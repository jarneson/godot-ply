extends Object

const GIZMO_CIRCLE_SIZE = 1.1
const GIZMO_ARROW_OFFSET = GIZMO_CIRCLE_SIZE + 0.3
const GIZMO_ARROW_SIZE = 0.35
const GIZMO_SCALE_OFFSET = GIZMO_CIRCLE_SIZE + 0.3
const GIZMO_PLANE_SIZE = 0.2
const GIZMO_PLANE_DST = 0.3

var _plugin: EditorPlugin

func _init(p: EditorPlugin):
    _plugin = p

var started: bool = false
func startup():
    _init_materials()
    _init_meshes()
    _init_instance()
    started = true

func teardown():
    if not started:
        return
    for i in range(3):
        VisualServer.free_rid(move_gizmo_instances[i])
        VisualServer.free_rid(move_plane_gizmo_instances[i])
    started = false

# 0: x, 1: y, 2: z
var move_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var move_gizmo_instances = [0, 0, 0]
var move_plane_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var move_plane_gizmo_instances = [0, 0, 0]

var axis_colors          = [Color(1.0,0.2,0.2), Color(0.2, 1.0, 0.2), Color(0.2, 0.2, 1.0)]
var axis_colors_selected = [Color(1.0,0.8,0.8), Color(0.8, 1.0, 0.8), Color(0.8, 0.8, 1.0)]

var axis_materials          = [null, null, null]
var axis_materials_selected = [null, null, null]

func _init_materials():
    for i in range(3):
        var mat = SpatialMaterial.new()
        mat.flags_unshaded = true
        mat.flags_transparent = true
        mat.flags_no_depth_test = true
        mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
        mat.render_priority = 127
        mat.albedo_color = axis_colors[i]
        axis_materials[i] = mat

        mat = SpatialMaterial.new()
        mat.flags_unshaded = true
        mat.flags_transparent = true
        mat.flags_no_depth_test = true
        mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
        mat.render_priority = 127
        mat.albedo_color = axis_colors_selected[i]
        axis_materials_selected[i] = mat

func _init_meshes():
    for i in range(3):
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
            st.set_material(axis_materials[i])
            st.commit(move_gizmo[i])

        if true: # translate plane
            var st = SurfaceTool.new()
            st.begin(Mesh.PRIMITIVE_TRIANGLES)
            var vec = ivec2 - ivec3
            var plane = [
                vec * GIZMO_PLANE_DST,
                vec * GIZMO_PLANE_DST + ivec2 * GIZMO_PLANE_SIZE,
                vec * (GIZMO_PLANE_DST + GIZMO_PLANE_SIZE),
                vec * GIZMO_PLANE_DST - ivec3 * GIZMO_PLANE_SIZE
            ]
            var ma = Basis(ivec, PI/2)
            var points = [
                ma.xform(plane[0]),
                ma.xform(plane[1]),
                ma.xform(plane[2]),
                ma.xform(plane[3])
            ]
            st.add_vertex(points[0])
            st.add_vertex(points[1])
            st.add_vertex(points[2])
            st.add_vertex(points[0])
            st.add_vertex(points[2])
            st.add_vertex(points[3])
            st.set_material(axis_materials[i])
            st.commit(move_plane_gizmo[i])

func _init_instance():
    print("init instances")
    for i in range(3):
        move_gizmo_instances[i] = VisualServer.instance_create()
        VisualServer.instance_set_base(move_gizmo_instances[i], move_gizmo[i])
        VisualServer.instance_set_scenario(move_gizmo_instances[i], _plugin.get_tree().root.world.scenario)
        VisualServer.instance_set_visible(move_gizmo_instances[i], false)
        VisualServer.instance_geometry_set_cast_shadows_setting(move_gizmo_instances[i], VisualServer.SHADOW_CASTING_SETTING_OFF) 
        VisualServer.instance_set_layer_mask(move_gizmo_instances[i], 100)

        move_plane_gizmo_instances[i] = VisualServer.instance_create()
        VisualServer.instance_set_base(move_plane_gizmo_instances[i], move_plane_gizmo[i])
        VisualServer.instance_set_scenario(move_plane_gizmo_instances[i], _plugin.get_tree().root.world.scenario)
        VisualServer.instance_set_visible(move_plane_gizmo_instances[i], false)
        VisualServer.instance_geometry_set_cast_shadows_setting(move_plane_gizmo_instances[i], VisualServer.SHADOW_CASTING_SETTING_OFF) 
        VisualServer.instance_set_layer_mask(move_plane_gizmo_instances[i], 100)

var transform # Nullable Transform
var gizmo_scale: float

func _get_transform(camera: Camera) -> Transform:
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
    gizmo_scale = gizmo_size/abs(dd)
    var scale = Vector3(1,1,1) * gizmo_scale
    xform.basis = xform.basis.scaled(xform.basis.get_scale().inverse()).scaled(scale)
    return xform

func _set_highlight(highlight_axis):
    for i in range(3):
        move_gizmo[i].surface_set_material(0, axis_materials_selected[i] if i == highlight_axis else axis_materials[i])
        move_plane_gizmo[i].surface_set_material(0, axis_materials_selected[i] if i+6 == highlight_axis else axis_materials[i])

func _update_view():
    if not transform:
        for i in range(3):
            VisualServer.instance_set_visible(move_gizmo_instances[i], false)
            VisualServer.instance_set_visible(move_plane_gizmo_instances[i], false)
        return

    var xform  = _get_transform(_plugin.last_camera)

    for i in range(3):
        VisualServer.instance_set_transform(move_gizmo_instances[i], xform)
        VisualServer.instance_set_visible(move_gizmo_instances[i], true)
        VisualServer.instance_set_transform(move_plane_gizmo_instances[i], xform)
        VisualServer.instance_set_visible(move_plane_gizmo_instances[i], true)

func select(camera: Camera, screen_position: Vector2, only_highlight: bool = false) -> bool:
    if not transform:
        return false
    
    var ray_pos = camera.project_ray_origin(screen_position)
    var ray = camera.project_ray_normal(screen_position)
    var gt = _get_transform(camera)
    var gs = gizmo_scale

    if true: # translate
        var col_axis = -1
        var col_d = 100000
        var is_plane_translate = false
        for i in range(3):
            var grabber_pos = gt.origin + gt.basis[i] * (GIZMO_ARROW_OFFSET + (GIZMO_ARROW_SIZE * 0.5))
            var grabber_radius = gs * GIZMO_ARROW_SIZE
            var r: Vector3

            var res = Geometry.segment_intersects_sphere(ray_pos, ray_pos + ray * 1000, grabber_pos, grabber_radius)
            if res.size() > 0:
                var d = res[0].distance_to(ray_pos)
                if d < col_d:
                    col_d = d
                    col_axis = i
        
        if col_axis == -1: # plane select
            col_d = 100000
            for i in range(3):
                var ivec2 = gt.basis[(i+1)%3].normalized()
                var ivec3 = gt.basis[(i+2)%3].normalized()
                var grabber_pos = gt.origin + (ivec2 + ivec3) * gs * (GIZMO_PLANE_SIZE + GIZMO_PLANE_DST * 0.6667)

                var p_norm = gt.basis[i].normalized()
                var plane = Plane(p_norm, p_norm.dot(gt.origin))
                var intersection = plane.intersects_ray(ray_pos, ray)
                if intersection:
                    var dist = intersection.distance_to(grabber_pos)
                    if dist < gs * GIZMO_PLANE_SIZE * 1.5:
                        dist = ray_pos.distance_to(intersection)
                        if dist < col_d:
                            col_d = dist
                            col_axis = i
                            is_plane_translate = true
        if col_axis != -1:
            if only_highlight:
                _set_highlight(col_axis + (6 if is_plane_translate else 0))
            if not only_highlight:
                edit_mode = TransformMode.TRANSLATE
                edit_direction = gt.basis[col_axis].normalized()
                edit_axis = col_axis + (3 if is_plane_translate else 0)
                in_edit = true
                compute_edit(camera, screen_position)
                _plugin.selection.begin_edit()
            return true
    if only_highlight:
        _set_highlight(-1)
    return false

enum TransformAxis { X, Y, Z, YZ, XZ, XY, MAX }
enum TransformMode { NONE, TRANSLATE, ROTATE, SCALE, MAX }
var edit_mode: int = TransformMode.NONE
var edit_direction: Vector3 = Vector3.ZERO
var edit_plane: bool = false
var edit_axis: int = TransformAxis.X
var in_edit: bool = false

var original_origin # nullable vector3
var original_intersect # nullable vector3
func compute_edit(camera: Camera, screen_position: Vector2, snap = null):
    if not transform:
        return
    if not in_edit:
        return
    match edit_mode:
        TransformMode.TRANSLATE:
            var ray_pos = camera.project_ray_origin(screen_position)
            var ray = camera.project_ray_normal(screen_position)
            var p = Plane(ray, ray.dot(transform.origin))
            var motion_mask = Vector3.ZERO
            match edit_axis:
                TransformAxis.X:
                    motion_mask = transform.basis.orthonormalized().x
                    var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
                    p = Plane(normal, normal.dot(transform.origin))
                TransformAxis.Y:
                    motion_mask = transform.basis.orthonormalized().y
                    var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
                    p = Plane(normal, normal.dot(transform.origin))
                TransformAxis.Z:
                    motion_mask = transform.basis.orthonormalized().z
                    var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
                    p = Plane(normal, normal.dot(transform.origin))
                TransformAxis.YZ:
                    var normal = transform.basis.x
                    p = Plane(normal, normal.dot(transform.origin))
                TransformAxis.XZ:
                    var normal = transform.basis.y
                    p = Plane(normal, normal.dot(transform.origin))
                TransformAxis.XY:
                    var normal = transform.basis.z
                    p = Plane(normal, normal.dot(transform.origin))
            var intersection = p.intersects_ray(ray_pos, ray)
            if not intersection:
                return
            
            if not original_intersect:
                original_intersect = intersection
                original_origin = transform.origin

            var motion = intersection - original_intersect
            if motion_mask != Vector3.ZERO:
                motion = motion_mask.dot(motion) * motion_mask
            if snap:
                motion = motion.snapped(Vector3(snap, snap, snap))

            var delta = original_origin + motion - transform.origin
            _plugin.selection.translate_selection(delta)
        TransformMode.ROTATE:
            pass
        TransformMode.SCALE:
            pass

func end_edit():
    if not in_edit:
        return

    in_edit = false
    original_intersect = null
    var name = "Ply: Transform"
    match edit_mode:
        TransformMode.TRANSLATE:
            name = "Ply: Translate"
        TransformMode.ROTATE:
            name = "Ply: Rotate"
        TransformMode.SCALE:
            name = "Ply: Scale"
    _plugin.selection.commit_edit(name, _plugin.get_undo_redo())

func abort_edit():
    if not in_edit:
        return

    match edit_mode:
        TransformMode.TRANSLATE:
            var delta = original_origin - transform.origin
            _plugin.selection.translate_selection(delta)

    in_edit = false
    original_intersect = null

func process():
    if not started:
        return
    var basis_override = null
    if in_edit:
        basis_override = transform.basis 
    if _plugin.selection:
        transform = _plugin.selection.get_selection_transform(_plugin.toolbar.gizmo_mode, basis_override)
    else:
        transform = null
    _update_view()