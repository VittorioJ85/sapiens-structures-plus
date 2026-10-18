"""Conservative shared-GLB build tooling. Author: Vittorio.

Models are equivalent only when all JSON except material names and all binary
chunks match. Logical asset readers support the resulting flat alias manifest.
No arbitrary code is read from the JSON manifest. Deletions require --apply,
validated local paths, and a verified archive of every removed physical file.
"""
from pathlib import Path
from collections import defaultdict
import argparse
import hashlib
import json
import re
import struct
import stat
import zipfile
from datetime import datetime
from functools import lru_cache

IDENTIFIER = re.compile(r'^[A-Za-z0-9_-]+$')


def linked(path):
    """Reject Windows junctions too, including Python versions without is_junction."""
    try:
        info = path.lstat()
    except FileNotFoundError:
        return False
    return stat.S_ISLNK(info.st_mode) or bool(getattr(info, 'st_file_attributes', 0) & 0x400)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def unpack(raw):
    if len(raw) < 20 or struct.unpack_from('<III', raw) != (0x46546C67, 2, len(raw)):
        raise ValueError('Invalid GLB header')
    chunks, offset = [], 12
    while offset < len(raw):
        size, kind = struct.unpack_from('<II', raw, offset)
        if size % 4 or offset + 8 + size > len(raw):
            raise ValueError('Invalid GLB chunk')
        chunks.append((kind, raw[offset + 8:offset + 8 + size]))
        offset += 8 + size
    if offset != len(raw) or chunks[0][0] != 0x4E4F534A:
        raise ValueError('Invalid GLB JSON chunk')
    doc = json.loads(chunks[0][1])
    if any('uri' in buffer for buffer in doc.get('buffers', [])):
        raise ValueError('External GLB buffers are not supported')
    return doc, chunks


def signature(raw):
    doc, chunks = unpack(raw)
    materials = [m.get('name') for m in doc.get('materials', [])]
    for material in doc.get('materials', []):
        material.pop('name', None)
    normalized = json.dumps(doc, sort_keys=True, separators=(',', ':')).encode()
    normalized += b''.join(struct.pack('<II', kind, len(data)) + data for kind, data in chunks[1:])
    return digest(normalized), materials


def checked_file(mod, name):
    if not IDENTIFIER.fullmatch(name):
        raise ValueError(f'Invalid model identifier: {name}')
    root = (mod / 'models').resolve()
    path = root / (name + '.glb')
    if path.resolve().parent != root or linked(path):
        raise ValueError(f'Linked/escaping model path: {path}')
    return path


@lru_cache(maxsize=16)
def _manifest(path, modified, size):
    # File metadata invalidates the cache after a generator rewrites the manifest.
    # Callers treat the returned table as read-only.
    mod = path.parent
    data = json.loads(path.read_text('utf-8'))
    for name, entry in data.items():
        checked_file(mod, name)
        checked_file(mod, entry['base'])
        if entry['base'] in data or not isinstance(entry['materials'], dict):
            raise ValueError('Aliases must be flat and have a material map')
        if not all(isinstance(k, str) and isinstance(v, str) for k, v in entry['materials'].items()):
            raise ValueError('Invalid material map')
    return data


def manifest(mod):
    path = Path(mod) / 'modelAliases.json'
    if not path.exists():
        return {}
    stat = path.stat()
    return _manifest(path, stat.st_mtime_ns, stat.st_size)


def model_names(mod, pattern='*'):
    import fnmatch
    names = {p.stem for p in (mod / 'models').glob('*.glb')} | set(manifest(mod))
    return sorted(n for n in names if fnmatch.fnmatchcase(n, pattern))


def read_model(path):
    """Read a logical GLB for generators/tests, applying only declared names.

    Physical overrides win, exactly as in the runtime. This reader does not
    write expanded models and therefore cannot accidentally undo consolidation.
    """
    path = Path(path)
    if path.exists():
        return path.read_bytes()
    mod = path.parent.parent
    entry = manifest(mod).get(path.stem)
    if entry is None:
        raise FileNotFoundError(path)
    raw = checked_file(mod, entry['base']).read_bytes()
    if not entry['materials']:
        return raw
    doc, chunks = unpack(raw)
    for material in doc.get('materials', []):
        name = material.get('name')
        if name in entry['materials']:
            material['name'] = entry['materials'][name]
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    chunks[0] = (0x4E4F534A, encoded)
    payload = b''.join(struct.pack('<II', len(data), kind) + data for kind, data in chunks)
    return struct.pack('<III', 0x46546C67, 2, len(payload) + 12) + payload


def consolidate(mod, apply=False, module='spModelAliasData'):
    requested = Path(mod).absolute()
    for path in [requested, *requested.parents]:
        if linked(path):
            raise ValueError(f'Linked path is unsupported: {path}')
    mod = requested.resolve()
    if not IDENTIFIER.fullmatch(module):
        raise ValueError('Invalid Lua module name')
    if not (mod / 'modInfo.lua').is_file():
        raise ValueError('Expected mod root')
    # Reject junctions/symlinks in the mod tree before any mutation.
    for path in [mod, *mod.parents, *mod.rglob('*')]:
        if linked(path):
            raise ValueError(f'Linked path is unsupported: {path}')
    old = manifest(mod)
    if apply and (mod / 'waterTiles.json').exists():
        from model_water_tiles import prepare as prepare_water_tiles
        prepare_water_tiles(mod)
    if apply and (mod / 'modelTranslations.json').exists():
        # Maintained generators write in authoring coordinates. Restore static
        # slot placement sharing before ordinary material-only deduplication.
        from model_translations import prepare_generated_models
        prepare_generated_models(mod)
    storage_report = {}
    if apply:
        from model_vertices import finalize_models
        storage_report = finalize_models(mod)
    physical = {p.stem: p for p in (mod / 'models').glob('*.glb')}
    entries, groups = {}, defaultdict(list)
    for name, path in sorted(physical.items()):
        checked_file(mod, name)
        raw = path.read_bytes()
        key, materials = signature(raw)
        entries[name] = (key, materials)
        groups[key].append(name)
    for name, entry in old.items():
        if name not in physical:
            key, materials = entries[entry['base']]
            entries[name] = (key, [entry['materials'].get(m, m) for m in materials])
            groups[key].append(name)
    result = {}
    for group in groups.values():
        candidates = [n for n in group if n in physical]
        base = min(candidates, key=lambda n: (not n.endswith('_low'), len(n), n))
        source_materials = entries[base][1]
        for name in sorted(group):
            if name == base:
                continue
            target_materials = entries[name][1]
            mapping = {a: b for a, b in zip(source_materials, target_materials) if a != b}
            if (any(not a or not b for a, b in mapping.items()) or
                    any(mapping.get(a, a) != b for a, b in zip(source_materials, target_materials))):
                if name not in physical:
                    raise ValueError(f'Cannot preserve existing alias: {name}')
                continue
            result[name] = {'base': base, 'materials': mapping}
    result = dict(sorted(result.items()))
    removals = [physical[n] for n in result if n in physical]
    report = {'logical_models': len(entries), 'physical_before': len(physical),
              'aliases': len(result), 'physical_after': len(physical) - len(removals),
              'removed_bytes': sum(p.stat().st_size for p in removals)}
    report.update(storage_report)
    if apply:
        # Back up the exact bytes before removing only explicitly verified files.
        backup_dir = mod.parent / 'backups'
        backup_dir.mkdir(exist_ok=True)
        if linked(backup_dir):
            raise ValueError('Linked backup directory')
        if removals:
            backup = backup_dir / (mod.name + '-model-assets-' + datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '.zip')
            hashes = {p.name: digest(p.read_bytes()) for p in removals}
            with zipfile.ZipFile(backup, 'x', zipfile.ZIP_DEFLATED) as archive:
                for path in removals:
                    archive.write(path, path.name)
            with zipfile.ZipFile(backup) as archive:
                for name, expected in hashes.items():
                    if digest(archive.read(name)) != expected:
                        raise ValueError('Backup integrity failure')
            report['backup'] = str(backup)
        # JSON is the tooling manifest; static Lua is the runtime representation.
        # JSON string escaping is Lua-compatible for these ASCII material names.
        def quote(value):
            if not re.fullmatch(r'[A-Za-z0-9_. -]+', value):
                raise ValueError(f'Unsupported material identifier: {value}')
            return json.dumps(value)
        lines = ['-- Generated by model_assets.py; do not edit. Author: Vittorio.', 'return {']
        for name, entry in result.items():
            maps = ','.join('[' + quote(k) + ']=' + quote(v) for k, v in sorted(entry['materials'].items()))
            lines.append('[' + quote(name) + ']={base=' + quote(entry['base']) + ',materials={' + maps + '}},')
        lines.append('}\n')
        (mod / 'modelAliases.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
        (mod / 'scripts/common' / (module + '.lua')).write_text('\n'.join(lines), encoding='utf-8')
        for path in removals:
            if digest(path.read_bytes()) != hashes[path.name]:
                raise ValueError('Model changed during consolidation')
            checked_file(mod, path.stem).unlink()
        from model_vertices import compact_json_tree
        compact_json_tree(mod)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mod', type=Path)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--module', default='spModelAliasData', help='Unique Lua data module for this mod')
    args = parser.parse_args()
    print(json.dumps(consolidate(args.mod, args.apply, args.module), indent=2))
