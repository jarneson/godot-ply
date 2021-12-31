extends ImmediateGeometry

const PlyMesh = preload("../resources/ply_mesh.gd")

var ply_mesh: PlyMesh
var copy_transform: Spatial

onready var editor = get_parent()

func _ready():
    var m = SpatialMaterial.new()
    m.albedo_color = Color.white
    m.flags_use_point_size = true
    # m.flags_no_depth_test = true # enable for xray
    m.flags_unshaded = true
    m.params_point_size = 10
    m.vertex_color_use_as_albedo = true
    set_material_override(m)
    print("material: ", m)

func _process(_delta):
    global_transform = copy_transform.global_transform
    clear()
    begin(Mesh.PRIMITIVE_LINES)
    for e in range(ply_mesh.edge_count()):
        if editor.selected_edges.has(e):
            set_color(Color.green)
        else:
            set_color(Color.blue)
        add_vertex(ply_mesh.edge_origin(e))
        add_vertex(ply_mesh.edge_destination(e))
    end()