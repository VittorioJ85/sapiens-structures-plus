"""Static resource placement sharing for authoring tools. Author: Vittorio.

Runtime placement stays in ordinary GLB assembly nodes. Content vertices and
normals are rebased by proper rigid transforms. All material variants of a slot
MUST use one transform, proven by the planner and independently verified against
the pre-change assemblies. Legacy 0.16.1 translation manifests remain readable.
"""
from pathlib import Path
from functools import lru_cache
import copy,json,struct,hashlib
import numpy as np
from model_assets import unpack,read_model,checked_file,linked


def sha(raw):return hashlib.sha256(raw).hexdigest()


def pack(doc,chunks):
    encoded=json.dumps(doc,separators=(',',':')).encode()
    encoded+=b' '*(-len(encoded)%4)
    chunks=[(0x4E4F534A,encoded),*chunks[1:]]
    body=b''.join(struct.pack('<II',len(data),kind)+data for kind,data in chunks)
    return struct.pack('<III',0x46546C67,2,len(body)+12)+body


def positions(doc,blob,index):
    accessor=doc['accessors'][index];view=doc['bufferViews'][accessor['bufferView']]
    assert accessor['componentType']==5126 and accessor['type']=='VEC3' and not accessor.get('sparse')
    return np.ndarray((accessor['count'],3),dtype='<f4',buffer=blob,
        offset=view.get('byteOffset',0)+accessor.get('byteOffset',0),
        strides=(view.get('byteStride',12),4))


def shift_mesh(raw,offset):
    doc,chunks=unpack(raw)
    assert len(doc.get('nodes',[]))==1 and len(doc.get('meshes',[]))==1
    assert not set(doc['nodes'][0])-{'name','mesh'}
    offset=np.asarray(offset,dtype=float)
    assert offset.shape==(3,) and np.isfinite(offset).all() and np.max(np.abs(offset))<100
    index=next(i for i,(kind,data) in enumerate(chunks) if kind==0x004E4942)
    blob=bytearray(chunks[index][1]);done=set()
    for primitive in doc['meshes'][0]['primitives']:
        ai=primitive['attributes']['POSITION']
        if ai in done:continue
        done.add(ai);points=positions(doc,blob,ai)
        points[:]=(points.astype(float)+offset).astype('<f4')
        doc['accessors'][ai]['min']=points.min(0).tolist()
        doc['accessors'][ai]['max']=points.max(0).tolist()
    chunks[index]=(0x004E4942,blob)
    return pack(doc,chunks)


def shift_slots(raw,slots,sign=1):
    doc,chunks=unpack(raw);found=set()
    for node in doc.get('nodes',[]):
        name=node.get('name')
        if name not in slots:continue
        assert 'matrix' not in node and node.get('rotation',[0,0,0,1])==[0,0,0,1]
        assert node.get('scale',[1,1,1])==[1,1,1]
        node['translation']=(np.asarray(node.get('translation',[0,0,0]))+sign*np.asarray(slots[name])).tolist()
        found.add(name)
    assert found==set(slots), 'Missing assembly resource nodes'
    return pack(doc,chunks)


@lru_cache(maxsize=8)
def _load(path,modified,size):
    data=json.loads(path.read_text())
    from model_rigid import checked
    if set(data['mesh_offsets']) & set(data.get('mesh_transforms',{})) or set(data['assembly_offsets']) & set(data.get('assembly_transforms',{})):
        raise ValueError('A model cannot use both legacy offsets and rigid transforms')
    for name,matrix in data.get('mesh_transforms',{}).items():
        checked_file(path.parent,name);checked(matrix)
    for name,slots in data.get('assembly_transforms',{}).items():
        checked_file(path.parent,name)
        for matrix in slots.values():checked(matrix)
    for name,offset in data['mesh_offsets'].items():
        checked_file(path.parent,name)
        assert len(offset)==3 and all(isinstance(v,(int,float)) for v in offset)
        assert np.isfinite(offset).all() and max(map(abs,offset))<100
    for name,slots in data['assembly_offsets'].items():
        checked_file(path.parent,name)
        for offset in slots.values():
            assert len(offset)==3 and np.isfinite(offset).all() and max(map(abs,offset))<100
    targets=[pair['target'] for pair in data['equivalent_pairs']]
    assert len(targets)==len(set(targets)), 'Duplicate translation target'
    assert not set(targets)&{p['base'] for p in data['equivalent_pairs']}, 'Translation chains are unsupported'
    for pair in data['equivalent_pairs']:
        checked_file(path.parent,pair['base']);checked_file(path.parent,pair['target'])
    return data


def metadata(mod):
    path=Path(mod)/'modelTranslations.json'
    if not path.exists():return None
    st=path.stat();return _load(path,st.st_mtime_ns,st.st_size)


def read_authoring_model(path):
    """Expand a logical model into the original baked authoring coordinates."""
    path=Path(path);raw=read_model(path);data=metadata(path.parent.parent)
    if not data:return raw
    if path.stem in data['mesh_offsets']:raw=shift_mesh(raw,data['mesh_offsets'][path.stem])
    if path.stem in data['assembly_offsets']:raw=shift_slots(raw,data['assembly_offsets'][path.stem],-1)
    from model_rigid import transform_mesh,transform_slots
    if path.stem in data.get('mesh_transforms',{}):raw=transform_mesh(raw,data['mesh_transforms'][path.stem])
    if path.stem in data.get('assembly_transforms',{}):raw=transform_slots(raw,data['assembly_transforms'][path.stem],inverse=True)
    return raw


def equivalent_template(base_raw,target_raw):
    """Return a material-preserving exact template only after numeric validation.

    Metadata, UVs, colors, topology and non-position binary attributes must match;
    only position and normal roundoff may differ within the recorded tolerances.
    Node names are retained here, unlike the broader candidate discovery scan.
    """
    # Compare one deterministic storage layout, whether the generator emitted
    # expanded vertices or read already packed runtime geometry.
    from model_vertices import compact_glb
    a,ac=unpack(compact_glb(base_raw));b,bc=unpack(compact_glb(target_raw))
    # Unknown extension chunks must remain byte-identical as well. They are
    # never part of the float32 roundoff normalization allowance.
    if [(k,v) for k,v in ac if k not in (0x4E4F534A,0x004E4942)] != [(k,v) for k,v in bc if k not in (0x4E4F534A,0x004E4942)]:return None
    ad=copy.deepcopy(a);bd=copy.deepcopy(b)
    for doc in (ad,bd):
        for mat in doc.get('materials',[]):mat.pop('name',None)
        for accessor in doc.get('accessors',[]):accessor.pop('min',None);accessor.pop('max',None)
    if ad!=bd:return None
    ab=bytearray(dict(ac).get(0x004E4942,b''));bb=bytearray(dict(bc).get(0x004E4942,b''))
    done=set()
    for primitive in [p for m in a.get('meshes',[]) for p in m['primitives']]:
        for semantic,tolerance in [('POSITION',2e-6),('NORMAL',2e-5)]:
            ai=primitive['attributes'].get(semantic)
            if ai is None or ai in done:continue
            done.add(ai)
            av=positions(a,ab,ai);bv=positions(b,bb,ai)
            if not np.isfinite(av).all() or not np.isfinite(bv).all():return None
            if np.max(np.abs(av.astype(float)-bv.astype(float)))>tolerance:return None
            av[:]=0;bv[:]=0
    if ab!=bb:return None
    for source,target in zip(a.get('materials',[]),b.get('materials',[])):
        if 'name' in target:source['name']=target['name']
        else:source.pop('name',None)
    return pack(a,ac)


def prepare_generated_models(mod):
    """Normalize regenerated authoring files before ordinary material deduplication.

    Unchanged optimized files are identified by hash, preventing double shifts.
    A generator must use read_authoring_model when reading existing mod meshes.
    New geometry that no longer matches a translation pair stays independent.
    """
    mod=Path(mod);data=metadata(mod)
    if not data:return
    data=copy.deepcopy(data);changed=False
    from model_rigid import transform_mesh,transform_slots
    for name in sorted(set(data['mesh_offsets'])|set(data['assembly_offsets'])|set(data.get('mesh_transforms',{}))|set(data.get('assembly_transforms',{}))):
        path=checked_file(mod,name)
        if not path.exists():continue
        raw=path.read_bytes()
        if sha(raw)==data['normalized_hashes'].get(name):continue
        if name in data['mesh_offsets']:raw=shift_mesh(raw,-np.asarray(data['mesh_offsets'][name]))
        if name in data['assembly_offsets']:raw=shift_slots(raw,data['assembly_offsets'][name])
        if name in data.get('mesh_transforms',{}):raw=transform_mesh(raw,np.linalg.inv(data['mesh_transforms'][name]))
        if name in data.get('assembly_transforms',{}):raw=transform_slots(raw,data['assembly_transforms'][name])
        path.write_bytes(raw);data['normalized_hashes'][name]=sha(raw);changed=True
    for pair in data['equivalent_pairs']:
        target=checked_file(mod,pair['target'])
        if not target.exists():continue
        base=read_model(checked_file(mod,pair['base']))
        template=equivalent_template(base,target.read_bytes())
        if template is not None and template!=target.read_bytes():
            target.write_bytes(template);data['normalized_hashes'][pair['target']]=sha(template);changed=True
    if changed:
        path=mod/'modelTranslations.json'
        assert not linked(path)
        path.write_text(json.dumps(data,indent=2)+'\n')
