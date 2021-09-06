tool
extends MeshInstance

var PlyMesh = preload("../resources/ply_mesh.gd")
export(Resource) var ply_mesh = PlyMesh.new()
export(Material) var material = preload("../debug_material.tres")


var mesh_instance = null
func _enter_tree():
    render_mesh()

    if not ply_mesh.is_connected("mesh_updated", self, "render_mesh"):
        ply_mesh.connect("mesh_updated", self, "render_mesh")

func render_mesh():
    if ply_mesh is PlyMesh:
        self.mesh = ply_mesh.get_mesh()
        set("material/0", material)
    else:
        print("not a PlyMesh: %s" % [ply_mesh])