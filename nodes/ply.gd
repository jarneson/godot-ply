tool
extends MeshInstance

signal transform_updated

var default_material = preload("../debug_material.tres")

var PlyMesh = preload("../resources/ply_mesh.gd")
export(Resource) var ply_mesh = PlyMesh.new()
export(Array, Material) var materials

var mesh_instance = null
func _enter_tree():
    set_notify_transform(true)
    if not ply_mesh.is_connected("mesh_updated", self, "_on_mesh_updated"):
        ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")
    _on_mesh_updated()

func _exit_tree():
    set_notify_transform(false)
    if ply_mesh.is_connected("mesh_updated", self, "_on_mesh_updated"):
        ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")

func _notification(what):
    if what == Spatial.NOTIFICATION_TRANSFORM_CHANGED:
        emit_signal("transform_updated")

func _on_mesh_updated():
    if ply_mesh is PlyMesh:
        self.mesh = ply_mesh.get_mesh()
        for i in range(self.mesh.get_surface_count()):
            if materials and materials.size() > i and materials[i]:
                set("material/%s" % [i], materials[i])
            else:
                set("material/%s" % [i], default_material)
    else:
        print("not a PlyMesh: %s" % [ply_mesh])

    var collision_shape = get_node_or_null("StaticBody/CollisionShape")
    if collision_shape:
        collision_shape.shape = self.mesh.create_trimesh_shape()