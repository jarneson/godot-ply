extends ImmediateGeometry

const PlyMesh = preload("../resources/ply_mesh.gd")

var ply_mesh: PlyMesh
var copy_transform: Spatial

func _ready():
    var m = SpatialMaterial.new()
    m.albedo_color = Color.white
    m.flags_use_point_size = true
    # m.flags_no_depth_test = true
    m.flags_unshaded = true
    m.params_point_size = 10
    m.vertex_color_use_as_albedo = true
    set_material_override(m)
    print("material: ", m)

func _process(_delta):
    global_transform = copy_transform.global_transform
    clear()
    begin(Mesh.PRIMITIVE_POINTS)
    set_color(Color.blue)
    for v in range(ply_mesh.vertex_count()):
        add_vertex(ply_mesh.vertexes[v])
    end()