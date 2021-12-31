extends Object

const GIZMO_CIRCLE_SIZE = 1.1
const GIZMO_ARROW_OFFSET = GIZMO_CIRCLE_SIZE + 0.3
const GIZMO_ARROW_SIZE = 0.35
const GIZMO_SCALE_OFFSET = GIZMO_CIRCLE_SIZE + 0.3

var _plugin: EditorPlugin

func _init(p: EditorPlugin):
    _plugin = p

func startup():
    _init_meshes()
    _init_instance()

# 0: x, 1: y, 2: z
var move_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var move_gizmo_instances = [0, 0, 0]

func _init_meshes():
    for i in range(3):
        var col: Color
        match i:
            0:
                col = Color.red
            1:
                col = Color.green    
            2:
                col = Color.blue

        var mat = SpatialMaterial.new()
        mat.flags_unshaded = true
        mat.flags_transparent = true
        mat.flags_no_depth_test = true
        mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
        mat.render_priority = 127
        mat.albedo_color = col
        
        var ivec = Vector3.ZERO
        ivec[i] = 1
        var nivec = Vector3.ZERO
        nivec[(i+1)%3] = 1
        nivec[(i+1)%2] = 1
        var ivec2 = Vector3.ZERO
        ivec2[(i+1)%3] = 1
        var ivec3 = Vector3.ZERO
        ivec3[(i+2)%3] = 1
        
        if true: # translate
            var st = SurfaceTool.new()
            st.begin(Mesh.PRIMITIVE_TRIANGLES)
            var arrow_points = 5
            var arrow = [
                nivec * 0 + ivec * 0,
                nivec * 0.01 + ivec * 0.0,
                nivec * 0.01 + ivec * GIZMO_ARROW_OFFSET,
                nivec * 0.065 + ivec * GIZMO_ARROW_OFFSET,
                nivec * 0 + ivec * (GIZMO_ARROW_OFFSET + GIZMO_ARROW_SIZE)
            ]

            var arrow_sides = 16
            for k in range(arrow_sides):
                var ma = Basis(ivec, PI * 2 * float(k) / arrow_sides)
                var mb = Basis(ivec, PI * 2 * float(k+1) / arrow_sides)
                for j in range(arrow_points-1):
                    var points = [
                        ma.xform(arrow[j]),
                        mb.xform(arrow[j]),
                        ma.xform(arrow[j+1]),
                        mb.xform(arrow[j+1]),
                    ]
                    st.add_vertex(points[0])
                    st.add_vertex(points[1])
                    st.add_vertex(points[2])
                    st.add_vertex(points[0])
                    st.add_vertex(points[2])
                    st.add_vertex(points[3])
            st.set_material(mat)
            st.commit(move_gizmo[i])

func _init_instance():
    for i in range(3):
        move_gizmo_instances[i] = VisualServer.instance_create()
        VisualServer.instance_set_base(move_gizmo_instances[i], move_gizmo[i])
        VisualServer.instance_set_scenario(move_gizmo_instances[i], _plugin.get_tree().root.world.scenario)
        VisualServer.instance_set_visible(move_gizmo_instances[i], false)
        VisualServer.instance_geometry_set_cast_shadows_setting(move_gizmo_instances[i], VisualServer.SHADOW_CASTING_SETTING_OFF) 
        VisualServer.instance_set_layer_mask(move_gizmo_instances[i], 100)

var transform setget set_transform
var transform_ok: bool = false

func set_transform(v):
    transform = v
    _update_view()

func _update_view():
    if not transform:
        for i in range(3):
            VisualServer.instance_set_visible(move_gizmo_instances[i], false)
        return

    var camera = _plugin.last_camera
    var cam_xform = camera.global_transform
    var xform = transform
    var camz = -cam_xform.basis.z.normalized()
    var camy = -cam_xform.basis.y.normalized()
    var p = Plane(camz, camz.dot(cam_xform.origin))
    var gizmo_d = max(abs(p.distance_to(xform.origin)), 0.00001)
    var d0 = camera.unproject_position(cam_xform.origin + camz * gizmo_d).y
    var d1 = camera.unproject_position(cam_xform.origin + camz*gizmo_d+camy).y
    var dd = abs(d0-d1)
    if dd == 0:
        dd = 0.0001
    var gizmo_size = 80
    var gizmo_scale = gizmo_size/abs(dd)
    var scale = Vector3(1,1,1) * gizmo_scale
    xform.basis = xform.basis.scaled(scale)

    for i in range(3):
        VisualServer.instance_set_transform(move_gizmo_instances[i], xform)
        VisualServer.instance_set_visible(move_gizmo_instances[i], true)

func process():
    _update_view()