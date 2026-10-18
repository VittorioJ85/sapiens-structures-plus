"""Lossless-in-shape rigid placement helpers for GLB authoring. Author: Vittorio.

Only proper rotations and translations are allowed. Scale, mirroring and shear
are deliberately rejected; no undocumented renderer scaling behavior is used.
Matrices use glTF's column-vector convention, stored as row-major JSON arrays
in the tooling manifest (glTF node matrices themselves are column-major).
"""
import numpy as np
import copy,hashlib,json
from collections import defaultdict
from model_assets import unpack


def checked(value):
    matrix=np.asarray(value,dtype=float)
    if matrix.shape!=(4,4) or not np.isfinite(matrix).all():raise ValueError('Invalid rigid matrix')
    if not np.allclose(matrix[3],[0,0,0,1],atol=1e-9,rtol=0):raise ValueError('Invalid affine row')
    R=matrix[:3,:3]
    if not np.allclose(R.T@R,np.eye(3),atol=1e-6,rtol=0) or abs(np.linalg.det(R)-1)>1e-6:
        raise ValueError('Only proper rigid transforms are supported')
    if np.max(np.abs(matrix[:3,3]))>=100:raise ValueError('Out-of-range translation')
    return matrix


def node_matrix(node,resource=False):
    if 'matrix' in node:return checked(np.array(node['matrix']).reshape(4,4).T)
    # Native worldHelper resolves resource placement through offset + rotation.
    # Editor helper-box scale is not the resource model's size. Keep that field
    # intact in the GLB, but never apply it to the baked resource mesh.
    if not resource and node.get('scale',[1,1,1])!=[1,1,1]:raise ValueError('Scaled mesh node')
    x,y,z,w=node.get('rotation',[0,0,0,1])
    m=np.eye(4);m[:3,:3]=[
        [1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
        [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
        [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]
    m[:3,3]=node.get('translation',[0,0,0])
    return checked(m)


def quaternion(R):
    # Eigenvector formulation remains stable for 180-degree rotations.
    xx,xy,xz=R[0];yx,yy,yz=R[1];zx,zy,zz=R[2]
    K=np.array([[xx-yy-zz,xy+yx,xz+zx,zy-yz],
                [xy+yx,yy-xx-zz,yz+zy,xz-zx],
                [xz+zx,yz+zy,zz-xx-yy,yx-xy],
                [zy-yz,xz-zx,yx-xy,xx+yy+zz]])/3
    values,vectors=np.linalg.eigh(K);q=vectors[:,np.argmax(values)]
    if q[3]<0:q=-q
    return q.tolist()


def transform_mesh(raw,matrix):
    from model_translations import positions,pack
    matrix=checked(matrix);doc,chunks=unpack(raw)
    if not doc.get('meshes') or any(set(n)-{'name','mesh'} for n in doc.get('nodes',[])):
        raise ValueError('Expected untransformed content meshes')
    if any(k in doc for k in ('animations','skins','cameras','extensions')):
        raise ValueError('Unsupported animated/extended content')
    index=next(i for i,(kind,data) in enumerate(chunks) if kind==0x004E4942)
    blob=bytearray(chunks[index][1]);done=set()
    # Shadow-volume meshes receive the identical rigid transform. Preserve all
    # nodes and primitive boundaries, including their visibility semantics.
    for primitive in [p for mesh in doc['meshes'] for p in mesh['primitives']]:
        if 'TANGENT' in primitive['attributes']:raise ValueError('Tangents require explicit support')
        for semantic in ('POSITION','NORMAL'):
            ai=primitive['attributes'].get(semantic)
            if ai is None or ai in done:continue
            done.add(ai);points=positions(doc,blob,ai)
            transformed=points.astype(float)@matrix[:3,:3].T
            if semantic=='POSITION':transformed+=matrix[:3,3]
            points[:]=transformed.astype('<f4')
            accessor=doc['accessors'][ai]
            if semantic=='POSITION' or 'min' in accessor:accessor['min']=points.min(0).tolist()
            if semantic=='POSITION' or 'max' in accessor:accessor['max']=points.max(0).tolist()
    chunks[index]=(0x004E4942,blob)
    return pack(doc,chunks)


def transform_slots(raw,slots,inverse=False):
    from model_translations import pack
    doc,chunks=unpack(raw);found=set()
    for node in doc.get('nodes',[]):
        name=node.get('name')
        if name not in slots:continue
        change=checked(slots[name])
        if inverse:change=np.linalg.inv(change)
        result=checked(node_matrix(node,resource=True)@change)
        # Remove numerical noise from inverse rotations (e.g. 2e-17 instead
        # of the authored zero). This is far below float32 model precision.
        for exact in (0.,1.,-1.):result[np.abs(result-exact)<1e-12]=exact
        for key in ('matrix','translation','rotation'):node.pop(key,None)
        node['translation']=result[:3,3].tolist()
        node['rotation']=quaternion(result[:3,:3])
        found.add(name)
    if found!=set(slots):raise ValueError('Missing resource placement node')
    return pack(doc,chunks)


def canonicalize_roundoff(mod,names):
    """Remove float32 transform roundoff only after full structural comparison.

    Consider only explicitly transformed content. UVs, colors, index order,
    material properties, node semantics and all other binary data stay exact.
    Final equivalence is checked by equivalent_template; a hash is only a filter.
    """
    from model_assets import checked_file
    from model_translations import positions,equivalent_template
    groups=defaultdict(list);changed=0
    for name in sorted(names):
        path=checked_file(mod,name)
        if not path.exists():continue
        raw=path.read_bytes();doc,chunks=unpack(raw);clean=copy.deepcopy(doc)
        for m in clean.get('materials',[]):m.pop('name',None)
        for a in clean.get('accessors',[]):a.pop('min',None);a.pop('max',None)
        binary=bytearray(dict(chunks).get(0x004E4942,b''))
        for mesh in doc.get('meshes',[]):
            for primitive in mesh['primitives']:
                for key in ('POSITION','NORMAL'):
                    ai=primitive['attributes'].get(key)
                    if ai is not None:positions(doc,binary,ai)[:]=0
        key=hashlib.sha256(json.dumps(clean,sort_keys=True).encode()+binary).digest()
        for base in groups[key]:
            template=equivalent_template(base,raw)
            if template is not None:
                if template!=raw:path.write_bytes(template);changed+=1
                break
        else:groups[key].append(raw)
    return changed
