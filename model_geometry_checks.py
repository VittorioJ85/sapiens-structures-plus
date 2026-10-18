"""Independent lossless GLB comparison for regression tests. Author: Vittorio.

This decoder does not use the optimizer. It expands ordered triangle attributes
and compares exact bytes, including UVs, normals and unused attribute values.
Helper nodes, materials, scene metadata and unconsumed buffer views must match.
Only accessor/index storage layout may differ. No approximate tolerance applies.
"""
import copy
import struct
from model_assets import unpack

def values(doc, binary, index):
    # Deliberately independent of model_vertices.array and its deduplication.
    a = doc['accessors'][index]; v = doc['bufferViews'][a['bufferView']]
    types = {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}
    widths = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
    size = struct.calcsize('<'+types[a['componentType']]) * widths[a['type']]
    offset = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = v.get('byteStride', size)
    rows = [binary[offset+i*stride:offset+i*stride+size] for i in range(a['count'])]
    return rows


def verify(before, after):
    a, ac = unpack(before); b, bc = unpack(after)
    ab, bb = dict(ac).get(0x004E4942, b''), dict(bc).get(0x004E4942, b'')
    ad, bd = copy.deepcopy(a), copy.deepcopy(b)
    for d in (ad, bd):
        for key in ('buffers', 'bufferViews', 'accessors'):
            d.pop(key, None)
    assert ad == bd, 'Scene, mesh, helper, camera or material metadata changed'
    assert len(a.get('accessors', [])) == len(b.get('accessors', []))
    indices = set(); attributes = set(); triangles = 0
    for am, bm in zip(a.get('meshes', []), b.get('meshes', [])):
        for ap, bp in zip(am['primitives'], bm['primitives']):
            ai, bi = None, None
            if 'indices' in ap:
                index = ap['indices']; indices.add(index)
                ai = [int.from_bytes(x, 'little') for x in values(a, ab, index)]
                bi = [int.from_bytes(x, 'little') for x in values(b, bb, index)]
                assert len(ai) == len(bi)
                triangles += len(ai)//3
            for index in ap['attributes'].values():
                attributes.add(index)
                av, bv = values(a, ab, index), values(b, bb, index)
                assert set(av) == set(bv), 'Vertex attribute values removed or introduced'
                assert ([av[i] for i in ai] if ai is not None else av) == ([bv[i] for i in bi] if bi is not None else bv), 'Triangle attribute bytes changed'
    for i, (aa, ba) in enumerate(zip(a.get('accessors', []), b.get('accessors', []))):
        aa, ba = dict(aa), dict(ba)
        fields = ['byteOffset']
        if i in indices: fields += ['componentType', 'min', 'max']
        if i in attributes: fields += ['count']
        for field in fields: aa.pop(field, None); ba.pop(field, None)
        assert aa == ba, ('Accessor semantics changed', i)
        if i not in indices | attributes:
            assert values(a, ab, i) == values(b, bb, i)
    assert len(a.get('bufferViews', [])) == len(b.get('bufferViews', []))
    used = {a['accessors'][i]['bufferView'] for i in indices | attributes}
    for i, (av, bv) in enumerate(zip(a.get('bufferViews', []), b.get('bufferViews', []))):
        va, vb = dict(av), dict(bv)
        for field in ('byteOffset', 'byteLength', 'byteStride'):
            va.pop(field, None); vb.pop(field, None)
        assert va == vb
        if i not in used:
            assert ab[av.get('byteOffset',0):av.get('byteOffset',0)+av['byteLength']] == bb[bv.get('byteOffset',0):bv.get('byteOffset',0)+bv['byteLength']]
    return triangles

