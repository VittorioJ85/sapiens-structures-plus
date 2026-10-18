"""Lossless GLB vertex storage finalization. Author: Vittorio.

Only complete, byte-identical attribute tuples within one indexed triangle
primitive are shared. Triangle order, UV seams, normals and all helper nodes
remain unchanged. No coordinate quantization or mesh simplification is used.
Unsupported layouts are retained rather than guessed. This is build-time only.
"""
from collections import Counter
from pathlib import Path
import copy
import hashlib
import json
import numpy as np
from model_assets import unpack, linked

FORMATS = {5120: 'i1', 5121: 'u1', 5122: '<i2', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
BIN = 0x004E4942


def array(doc, blob, index):
    """Read a bounded accessor without interpreting padding as attribute data."""
    a = doc['accessors'][index]
    v = doc['bufferViews'][a['bufferView']]
    dtype = np.dtype(FORMATS[a['componentType']])
    width = WIDTHS[a['type']]
    count, offset = a['count'], a.get('byteOffset', 0)
    stride = v.get('byteStride', dtype.itemsize * width)
    if (count <= 0 or offset < 0 or stride < dtype.itemsize * width
            or offset + (count - 1) * stride + dtype.itemsize * width > v['byteLength']
            or v.get('byteOffset', 0) + v['byteLength'] > len(blob)):
        raise ValueError('Accessor exceeds its buffer view')
    return np.ndarray((count, width), dtype=dtype, buffer=blob,
                      offset=v.get('byteOffset', 0) + offset,
                      strides=(stride, dtype.itemsize)).copy()


def has_extensions(value):
    if isinstance(value, dict):
        return 'extensions' in value or any(has_extensions(v) for v in value.values())
    return isinstance(value, list) and any(has_extensions(v) for v in value)


def compact_glb(raw):
    """Return a smaller equivalent GLB, or the original bytes; deterministic."""
    doc, chunks = unpack(raw)
    if (len(chunks) != 2 or chunks[1][0] != BIN or len(doc.get('buffers', [])) != 1
            or doc.get('skins') or doc.get('animations') or doc.get('extensionsUsed')
            or doc.get('extensionsRequired') or has_extensions(doc)):
        return raw
    accessors, views = doc.get('accessors', []), doc.get('bufferViews', [])
    primitives = [p for m in doc.get('meshes', []) for p in m['primitives']]
    if any('sparse' in a or 'bufferView' not in a for a in accessors):
        return raw
    if any(p.get('targets') for p in primitives):
        return raw
    blob = chunks[1][1]
    limit = doc['buffers'][0]['byteLength']
    if limit > len(blob):
        raise ValueError('Truncated binary buffer')
    ranges = []
    for v in views:
        start, length = v.get('byteOffset', 0), v['byteLength']
        if v.get('buffer', 0) != 0 or start < 0 or length < 0 or start + length > limit:
            raise ValueError('Invalid buffer view')
        ranges.append((start, start + length))
    ordered = sorted(ranges)
    if any(a[1] > b[0] for a, b in zip(ordered, ordered[1:])):
        return raw  # Overlapping views can have independent consumers.
    uses = Counter(i for p in primitives for i in [*p['attributes'].values(), *([p['indices']] if 'indices' in p else [])])
    view_uses = Counter(a['bufferView'] for a in accessors)
    replacements = {}
    for p in primitives:
        if 'indices' not in p or p.get('mode', 4) != 4:
            continue
        ids = [*p['attributes'].values(), p['indices']]
        if any(uses[i] != 1 or view_uses[accessors[i]['bufferView']] != 1 for i in ids):
            continue
        if any(accessors[i]['type'] not in WIDTHS or accessors[i]['componentType'] not in FORMATS for i in ids):
            continue
        ia = accessors[p['indices']]
        if ia['type'] != 'SCALAR' or ia['componentType'] not in (5121, 5123, 5125):
            continue
        attrs = [(i, array(doc, blob, i)) for _, i in sorted(p['attributes'].items())]
        if not attrs or len({len(a) for _, a in attrs}) != 1:
            raise ValueError('Mismatched attribute counts')
        indices = array(doc, blob, p['indices']).ravel()
        if indices.size % 3 or int(indices.max()) >= len(attrs[0][1]):
            raise ValueError('Invalid triangle indices')
        rows = np.concatenate([a.view(np.uint8).reshape(len(a), -1) for _, a in attrs], axis=1)
        _, first, inverse = np.unique(rows, axis=0, return_index=True, return_inverse=True)
        # Preserve first source-vertex order. Sorting by float bytes would change
        # the ordering after rotations and prevent reliable authoring round trips.
        order = np.argsort(first)
        first = first[order]
        rank = np.empty(len(order), dtype=np.int64)
        rank[order] = np.arange(len(order))
        count = len(first)
        index_type = 5123 if count <= 65536 else 5125
        if ia['componentType'] == 5121 and count <= 256:
            index_type = 5121
        new_indices = rank[inverse[indices]].astype(FORMATS[index_type]).reshape(-1, 1)
        changed = [(i, a[first]) for i, a in attrs] + [(p['indices'], new_indices)]
        old_size = sum(views[accessors[i]['bufferView']]['byteLength'] for i in ids)
        # Vertex elements require four-byte alignment, including byte/short
        # attributes. Index buffers only need their ordinary component layout.
        encoded = []
        for i, a in changed:
            width = a.dtype.itemsize * a.shape[1]
            stride = width if i == p['indices'] else (width + 3) // 4 * 4
            if stride == width:
                binary = a.tobytes()
            else:
                padded = np.zeros((len(a), stride), dtype=np.uint8)
                padded[:, :width] = a.view(np.uint8).reshape(len(a), width)
                binary = padded.tobytes()
            encoded.append((i, a, binary, stride if stride != width else None))
        new_size = sum((len(binary) + 3) // 4 * 4 for _, _, binary, _ in encoded)
        if new_size >= old_size:
            continue
        for i, a, binary, stride in encoded:
            accessor = accessors[i]
            replacements[accessor['bufferView']] = (binary, stride)
            accessor['count'] = len(a)
            accessor.pop('byteOffset', None)
            if i == p['indices']:
                accessor['componentType'] = index_type
                for key, fn in [('min', np.min), ('max', np.max)]:
                    if key in accessor:
                        accessor[key] = [int(fn(a))]
            # Attribute bounds remain exact: every unique vertex is retained,
            # including unused vertices, so no bounding-volume changes occur.
    if not replacements:
        return raw
    packed = bytearray()
    for i, view in enumerate(views):
        packed.extend(b'\0' * (-len(packed) % 4))
        data, stride = replacements.get(i, (blob[ranges[i][0]:ranges[i][1]], view.get('byteStride')))
        view['byteOffset'] = len(packed)
        view['byteLength'] = len(data)
        if i in replacements:
            view.pop('byteStride', None)
            if stride is not None:
                view['byteStride'] = stride
        packed.extend(data)
    doc['buffers'][0]['byteLength'] = len(packed)
    packed.extend(b'\0' * (-len(packed) % 4))
    from model_translations import pack
    result = pack(doc, [chunks[0], (BIN, bytes(packed))])
    return result if len(result) < len(raw) else raw


def compact_json_tree(mod):
    """Stable JSON serialization, preserving all parsed values."""
    for path in sorted(Path(mod).rglob('*.json')):
        if linked(path):
            raise ValueError('Linked JSON asset')
        raw = path.read_bytes()
        encoded = json.dumps(json.loads(raw), separators=(',', ':'), ensure_ascii=False, allow_nan=False).encode('utf-8') + b'\n'
        if raw != encoded:
            path.write_bytes(encoded)


def finalize_models(mod):
    """Pack normalized runtime models and update the no-double-transform guards.

    Call after prepare_generated_models. Never label an unnormalized authoring
    model as runtime geometry: a stale normalization hash must fail explicitly.
    """
    mod = Path(mod)
    from model_translations import metadata
    meta = copy.deepcopy(metadata(mod))
    changed, saved = 0, 0
    for path in sorted((mod / 'models').glob('*.glb')):
        if linked(path):
            raise ValueError('Linked model asset')
        raw = path.read_bytes()
        packed = compact_glb(raw)
        if packed == raw:
            continue
        if meta and path.stem in meta['normalized_hashes']:
            if meta['normalized_hashes'][path.stem] != hashlib.sha256(raw).hexdigest():
                raise ValueError('Normalize authoring coordinates before packing: ' + path.stem)
            meta['normalized_hashes'][path.stem] = hashlib.sha256(packed).hexdigest()
        path.write_bytes(packed)
        changed += 1
        saved += len(raw) - len(packed)
    if changed and meta:
        path = mod / 'modelTranslations.json'
        if linked(path):
            raise ValueError('Linked transform manifest')
        path.write_text(json.dumps(meta, separators=(',', ':')) + '\n', encoding='utf-8')
    return {'repacked_models': changed, 'repacked_bytes_saved': saved}
