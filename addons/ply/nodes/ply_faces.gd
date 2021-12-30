extends ImmediateGeometry

const PlyMesh = preload("../resources/ply_mesh.gd")

onready var editor = get_parent()
var ply_mesh: PlyMesh
var copy_transform: Spatial

func _ready():
    var m = SpatialMaterial.new()
    m.albedo_color = Color(1,1,1,0.5)
    m.flags_use_point_size = true
    m.flags_no_depth_test = true
    m.flags_unshaded = true
    m.params_point_size = 10
    m.vertex_color_use_as_albedo = true
    m.flags_transparent = true
    set_material_override(m)
    print("material: ", m)

func _process(_delta):
    global_transform = copy_transform.global_transform
    clear()
    begin(Mesh.PRIMITIVE_TRIANGLES)
    set_color(Color(0,1,0,0.5))
    for f in range(ply_mesh.face_count()):
        if not editor.selected_faces.has(f):
            continue
        var ft = ply_mesh.face_tris(f)
        var verts = ft[0]
        var tris = ft[1]
        if verts.size() == 0:
            continue
        for tri in tris:
            add_vertex(verts[tri[0]][0])
            add_vertex(verts[tri[1]][0])
            add_vertex(verts[tri[2]][0])
    end()