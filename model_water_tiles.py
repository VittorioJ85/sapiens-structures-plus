"""Reproducible four-tile water normalization. Author: Vittorio.

Only the explicitly enabled water family is changed. The legacy large model
names become tile aliases; four native resource placements preserve the complete
rendered surface. No general geometric equivalence or renderer extension is used.
"""
import copy
import json
import struct
from pathlib import Path
from model_assets import checked_file, read_model, unpack
from model_geometry_checks import values
from model_translations import pack

OFFSETS = ((-1, 0, -1), (-1, 0, 1), (1, 0, -1), (1, 0, 1))


def verify_large(small, large):
    """Fail closed unless the expanded mesh is exactly four translated tiles."""
    a, ac = unpack(small); b, bc = unpack(large)
    ab, bb = dict(ac)[0x004E4942], dict(bc)[0x004E4942]
    if len(a['meshes']) != 1 or len(b['meshes']) != 4:
        raise ValueError('Unexpected water mesh layout')
    for doc in (a, b):
        if any(k in doc for k in ('animations', 'skins', 'extensions', 'extensionsRequired')):
            raise ValueError('Unsupported water model features')
        if len(doc['nodes']) != len(doc['meshes']) or doc['scenes'][doc.get('scene',0)]['nodes'] != list(range(len(doc['nodes']))):
            raise ValueError('Unexpected water scene layout')
        if any(set(n)-{'name', 'mesh'} for n in doc['nodes']):
            raise ValueError('Unexpected water node transform')
        if any(n.get('mesh') != i for i,n in enumerate(doc['nodes'])):
            raise ValueError('Unexpected water mesh instances')
        if any(len(mesh['primitives']) != 1 or mesh['primitives'][0].get('mode',4) != 4 for mesh in doc['meshes']):
            raise ValueError('Unsupported water primitive')
    ap = a['meshes'][0]['primitives'][0]
    ai = [int.from_bytes(x, 'little') for x in values(a, ab, ap['indices'])]
    for mesh, delta in zip(b['meshes'], OFFSETS):
        if len(mesh['primitives']) != 1:
            raise ValueError('Unexpected water primitive layout')
        bp = mesh['primitives'][0]
        if a['materials'][ap['material']] != b['materials'][bp['material']] or set(ap['attributes']) != set(bp['attributes']):
            raise ValueError('Water material/attribute mismatch')
        bi = [int.from_bytes(x, 'little') for x in values(b, bb, bp['indices'])]
        if len(ai) != len(bi): raise ValueError('Water triangle count changed')
        for attr in ap['attributes']:
            av = values(a, ab, ap['attributes'][attr]); bv = values(b, bb, bp['attributes'][attr])
            for i, j in zip(ai, bi):
                expected = av[i]
                if attr == 'POSITION':
                    expected = struct.pack('<3f', *(v+d for v,d in zip(struct.unpack('<3f', expected), delta)))
                if expected != bv[j]: raise ValueError('Water triangle attributes changed: '+attr)


def prepare(mod):
    """Normalize regenerated legacy assets; ordinary consolidation removes copies.

    All input reads precede writes. The caller owns the source snapshot/backup.
    Geometry that fails validation is never silently replaced.
    """
    mod = Path(mod)
    config = mod/'waterTiles.json'
    if not config.exists(): return
    if json.loads(config.read_text()) != {'version': 1}:
        raise ValueError('Unsupported water tile configuration')
    writes = {}
    for frame in range(64):
        small = read_model(checked_file(mod, f'slpool_wave{frame:02d}'))
        large_path = checked_file(mod, f'slpool4_wave{frame:02d}')
        if large_path.exists():
            large = large_path.read_bytes()
            if large != small:
                verify_large(small, large)
                writes[large_path] = small
    content = checked_file(mod, 'slpool_water4x4Content')
    if content.exists():
        small = read_model(checked_file(mod, 'slpool_water2x2Content'))
        if content.read_bytes() != small:
            verify_large(small, content.read_bytes())
            writes[content] = small
    for suffix in ('', '_low'):
        path = checked_file(mod, 'slpool_water4x4'+suffix)
        raw = read_model(path); doc, chunks = unpack(raw)
        slots = {n['name']: n for n in doc['nodes'] if n.get('name', '').startswith('dirt_')}
        first = slots['dirt_1']
        if 'dirt_2' in slots:
            if any(slots.get('dirt_'+str(i+1), {}).get('translation') != [x, -1, z] for i,(x,y,z) in enumerate(OFFSETS)):
                raise ValueError('Unexpected existing water tile placements')
            continue
        if first.get('translation') != [0, -1, 0] or 'rotation' in first or 'matrix' in first:
            raise ValueError('Unexpected original water placement')
        # The original node index stays stable; only additional nodes are appended.
        template = copy.deepcopy(first)
        first['translation'] = [-1, -1, -1]
        for i, (x,y,z) in enumerate(OFFSETS[1:], 2):
            node = copy.deepcopy(template)
            node.update(name='dirt_'+str(i), translation=[x, -1, z])
            index = len(doc['nodes']); doc['nodes'].append(node)
            for scene in doc['scenes']: scene['nodes'].append(index)
        writes[path] = pack(doc, chunks)
    for path, raw in writes.items(): path.write_bytes(raw)
