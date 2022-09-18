extends Object

# This code was adapted from the Godot editor source code under the following license:
#
# Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.
# Copyright (c) 2014-2021 Godot Engine contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# -- Godot Engine <https://godotengine.org>

const GIZMO_CIRCLE_SIZE = 1.1
const GIZMO_ARROW_OFFSET = GIZMO_CIRCLE_SIZE + 0.3
const GIZMO_ARROW_SIZE = 0.35
const GIZMO_SCALE_OFFSET = 2 * GIZMO_CIRCLE_SIZE
const GIZMO_SCALE_SIZE = 0.14
const GIZMO_PLANE_SIZE = 0.2
const GIZMO_PLANE_DST = 0.3
const GIZMO_PLANE_SCALE_DST = GIZMO_CIRCLE_SIZE
const GIZMO_RING_HALF_WIDTH = 0.1

const ROTATE_SHADER_CODE = """
shader_type spatial;
render_mode unshaded, depth_draw_never; 
uniform vec4 albedo; 

mat3 orthonormalize(mat3 m) { 
	vec3 x = normalize(m[0]); 
	vec3 y = normalize(m[1] - x * dot(x, m[1])); 
	vec3 z = m[2] - x * dot(x, m[2]); 
	z = normalize(z - y * (dot(y,m[2]))); 
	return mat3(x,y,z); 
} 

void vertex() { 
	mat3 mv = orthonormalize(mat3(MODELVIEW_MATRIX)); 
	vec3 n = mv * VERTEX; 
	float orientation = dot(vec3(0,0,-1),n); 
	if (orientation <= 0.005) { 
		VERTEX += NORMAL*0.02; 
	} 
} 

void fragment() { 
	ALBEDO = albedo.rgb; 
	ALPHA = albedo.a; 
}
"""

var _plugin: EditorPlugin


func _init(p: EditorPlugin):
	_plugin = p


func startup() -> void:
	_init_materials()
	_init_meshes()
	_init_instance()


func teardown() -> void:
	for i in range(3):
		RenderingServer.free_rid(move_gizmo_instances[i])
		RenderingServer.free_rid(move_plane_gizmo_instances[i])
		RenderingServer.free_rid(rotate_gizmo_instances[i])
		RenderingServer.free_rid(scale_gizmo_instances[i])
		RenderingServer.free_rid(scale_plane_gizmo_instances[i])


# 0: x, 1: y, 2: z
var move_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var move_gizmo_instances = [0, 0, 0]
var move_plane_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var move_plane_gizmo_instances = [0, 0, 0]
var rotate_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var rotate_gizmo_instances = [0, 0, 0]
var scale_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var scale_gizmo_instances = [0, 0, 0]
var scale_plane_gizmo = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
var scale_plane_gizmo_instances = [0, 0, 0]

var axis_colors = [Color(1.0, 0.2, 0.2), Color(0.2, 1.0, 0.2), Color(0.2, 0.2, 1.0)]
var axis_colors_selected = [Color(1.0, 0.8, 0.8), Color(0.8, 1.0, 0.8), Color(0.8, 0.8, 1.0)]

var axis_materials = [null, null, null]
var axis_materials_selected = [null, null, null]
var rotation_materials = [null, null, null]
var rotation_materials_selected = [null, null, null]


func _init_materials() -> void:
	var rotate_shader = Shader.new()
	rotate_shader.code = ROTATE_SHADER_CODE
	for i in range(3):
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.no_depth_test = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.render_priority = 127
		mat.albedo_color = axis_colors[i]
		axis_materials[i] = mat

		mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.no_depth_test = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.render_priority = 127
		mat.albedo_color = axis_colors_selected[i]
		axis_materials_selected[i] = mat

		var rotate_mat = ShaderMaterial.new()
		rotate_mat.render_priority = 127
		rotate_mat.shader = rotate_shader
		rotate_mat.set_shader_param("albedo", axis_colors[i])
		rotation_materials[i] = rotate_mat

		var rotate_mat_hl = rotate_mat.duplicate()
		rotate_mat_hl.set_shader_param("albedo", axis_colors_selected[i])
		rotation_materials_selected[i] = rotate_mat_hl


func _init_meshes() -> void:
	for i in range(3):
		var ivec = Vector3.ZERO
		ivec[i] = 1
		var nivec = Vector3.ZERO
		nivec[(i + 1) % 3] = 1
		nivec[(i + 1) % 3] = 1
		var ivec2 = Vector3.ZERO
		ivec2[(i + 1) % 3] = 1
		var ivec3 = Vector3.ZERO
		ivec3[(i + 2) % 3] = 1

		if true:  # translate
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
				var mb = Basis(ivec, PI * 2 * float(k + 1) / arrow_sides)
				for j in range(arrow_points - 1):
					var points = [
						ma * arrow[j],
						mb * arrow[j],
						ma * arrow[j + 1],
						mb * arrow[j + 1],
					]
					st.add_vertex(points[0])
					st.add_vertex(points[1])
					st.add_vertex(points[2])
					st.add_vertex(points[0])
					st.add_vertex(points[2])
					st.add_vertex(points[3])
			st.set_material(axis_materials[i])
			st.commit(move_gizmo[i])

		if true:  # translate plane
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var vec = ivec2 - ivec3
			var plane = [
				vec * GIZMO_PLANE_DST,
				vec * GIZMO_PLANE_DST + ivec2 * GIZMO_PLANE_SIZE,
				vec * (GIZMO_PLANE_DST + GIZMO_PLANE_SIZE),
				vec * GIZMO_PLANE_DST - ivec3 * GIZMO_PLANE_SIZE
			]
			var ma = Basis(ivec, PI / 2)
			var points = [
				ma * plane[0], ma * plane[1], ma * plane[2], ma * plane[3]
			]
			st.add_vertex(points[0])
			st.add_vertex(points[1])
			st.add_vertex(points[2])
			st.add_vertex(points[0])
			st.add_vertex(points[2])
			st.add_vertex(points[3])
			st.set_material(axis_materials[i])
			st.commit(move_plane_gizmo[i])

		if true:  # rotation
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var n = 128
			var m = 3
			for j in range(n):
				var basis = Basis(ivec, (PI * 2 * j) / n)
				var vertex = basis * ivec2 * GIZMO_CIRCLE_SIZE
				for k in range(m):
					var ofs = Vector2(cos((PI * 2 * k) / m), sin((PI * 2 * k) / m))
					var normal = ivec * ofs.x + ivec2 * ofs.y
					st.set_normal(basis * normal)
					st.add_vertex(vertex)
			for j in range(n):
				for k in range(m):
					var current_ring = j * m
					var next_ring = ((j + 1) % n) * m
					var current_segment = k
					var next_segment = (k + 1) % m
					st.add_index(current_ring + next_segment)
					st.add_index(current_ring + current_segment)
					st.add_index(next_ring + current_segment)
					st.add_index(next_ring + current_segment)
					st.add_index(next_ring + next_segment)
					st.add_index(current_ring + next_segment)
			var arrays = st.commit_to_arrays()
			rotate_gizmo[i].add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			rotate_gizmo[i].surface_set_material(0, rotation_materials[i])

		if true:  # scale
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var arrow = [
				nivec * 0.0 + ivec * GIZMO_SCALE_OFFSET,
				nivec * GIZMO_SCALE_SIZE / 2 + ivec * GIZMO_SCALE_OFFSET,
				nivec * GIZMO_SCALE_SIZE / 2 + ivec * (GIZMO_SCALE_SIZE + GIZMO_SCALE_OFFSET),
				nivec * 0.0 + ivec * (GIZMO_SCALE_SIZE + GIZMO_SCALE_OFFSET),
			]
			var arrow_sides = 4
			for k in range(arrow_sides):
				var ma = Basis(ivec, PI * 2 * float(k) / arrow_sides)
				var mb = Basis(ivec, PI * 2 * float(k + 1) / arrow_sides)
				for j in range(arrow.size() - 1):
					var points = [
						ma * arrow[j],
						mb * arrow[j],
						ma * arrow[j + 1],
						mb * arrow[j + 1],
					]
					st.add_vertex(points[0])
					st.add_vertex(points[1])
					st.add_vertex(points[2])
					st.add_vertex(points[0])
					st.add_vertex(points[2])
					st.add_vertex(points[3])
			st.set_material(axis_materials[i])
			st.commit(scale_gizmo[i])

		if true:  # scale plane
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var vec = ivec2 - ivec3
			var plane = [
				vec * (GIZMO_PLANE_SCALE_DST + GIZMO_PLANE_SIZE / 2),
				vec * GIZMO_PLANE_SCALE_DST + ivec2 * GIZMO_PLANE_SIZE / 0.9,
				vec * (GIZMO_PLANE_SCALE_DST + GIZMO_PLANE_SIZE),
				vec * GIZMO_PLANE_SCALE_DST - ivec3 * GIZMO_PLANE_SIZE / 0.9
			]
			var ma = Basis(ivec, PI / 2)
			var points = [
				ma * plane[0], ma * plane[1], ma * plane[2], ma * plane[3]
			]
			st.add_vertex(points[0])
			st.add_vertex(points[1])
			st.add_vertex(points[2])
			st.add_vertex(points[0])
			st.add_vertex(points[2])
			st.add_vertex(points[3])
			st.set_material(axis_materials[i])
			st.commit(scale_plane_gizmo[i])


func _init_instance() -> void:
	for i in range(3):
		move_gizmo_instances[i] = RenderingServer.instance_create()
		RenderingServer.instance_set_base(move_gizmo_instances[i], move_gizmo[i])
		RenderingServer.instance_set_scenario(
			move_gizmo_instances[i], _plugin.get_tree().root.world_3d.scenario
		)
		RenderingServer.instance_set_visible(move_gizmo_instances[i], false)
		RenderingServer.instance_geometry_set_cast_shadows_setting(
			move_gizmo_instances[i], RenderingServer.SHADOW_CASTING_SETTING_OFF
		)
		RenderingServer.instance_set_layer_mask(move_gizmo_instances[i], 100)

		move_plane_gizmo_instances[i] = RenderingServer.instance_create()
		RenderingServer.instance_set_base(move_plane_gizmo_instances[i], move_plane_gizmo[i])
		RenderingServer.instance_set_scenario(
			move_plane_gizmo_instances[i], _plugin.get_tree().root.world_3d.scenario
		)
		RenderingServer.instance_set_visible(move_plane_gizmo_instances[i], false)
		RenderingServer.instance_geometry_set_cast_shadows_setting(
			move_plane_gizmo_instances[i], RenderingServer.SHADOW_CASTING_SETTING_OFF
		)
		RenderingServer.instance_set_layer_mask(move_plane_gizmo_instances[i], 100)

		rotate_gizmo_instances[i] = RenderingServer.instance_create()
		RenderingServer.instance_set_base(rotate_gizmo_instances[i], rotate_gizmo[i])
		RenderingServer.instance_set_scenario(
			rotate_gizmo_instances[i], _plugin.get_tree().root.world_3d.scenario
		)
		RenderingServer.instance_set_visible(rotate_gizmo_instances[i], false)
		RenderingServer.instance_geometry_set_cast_shadows_setting(
			rotate_gizmo_instances[i], RenderingServer.SHADOW_CASTING_SETTING_OFF
		)
		RenderingServer.instance_set_layer_mask(rotate_gizmo_instances[i], 100)

		scale_gizmo_instances[i] = RenderingServer.instance_create()
		RenderingServer.instance_set_base(scale_gizmo_instances[i], scale_gizmo[i])
		RenderingServer.instance_set_scenario(
			scale_gizmo_instances[i], _plugin.get_tree().root.world_3d.scenario
		)
		RenderingServer.instance_set_visible(scale_gizmo_instances[i], false)
		RenderingServer.instance_geometry_set_cast_shadows_setting(
			scale_gizmo_instances[i], RenderingServer.SHADOW_CASTING_SETTING_OFF
		)
		RenderingServer.instance_set_layer_mask(scale_gizmo_instances[i], 100)

		scale_plane_gizmo_instances[i] = RenderingServer.instance_create()
		RenderingServer.instance_set_base(scale_plane_gizmo_instances[i], scale_plane_gizmo[i])
		RenderingServer.instance_set_scenario(
			scale_plane_gizmo_instances[i], _plugin.get_tree().root.world_3d.scenario
		)
		RenderingServer.instance_set_visible(scale_plane_gizmo_instances[i], false)
		RenderingServer.instance_geometry_set_cast_shadows_setting(
			scale_plane_gizmo_instances[i], RenderingServer.SHADOW_CASTING_SETTING_OFF
		)
		RenderingServer.instance_set_layer_mask(scale_plane_gizmo_instances[i], 100)


var transform  # Nullable Transform3D
var gizmo_scale: float


func _get_transform(camera: Camera3D) -> Transform3D:
	var cam_xform = camera.global_transform
	var xform = transform
	var camz = -cam_xform.basis.z.normalized()
	var camy = -cam_xform.basis.y.normalized()
	var p = Plane(camz, camz.dot(cam_xform.origin))
	var gizmo_d = max(abs(p.distance_to(xform.origin)), 0.00001)
	var d0 = camera.unproject_position(cam_xform.origin + camz * gizmo_d).y
	var d1 = camera.unproject_position(cam_xform.origin + camz * gizmo_d + camy).y
	var dd = abs(d0 - d1)
	if dd == 0:
		dd = 0.0001
	var gizmo_size = 80
	gizmo_scale = gizmo_size / abs(dd)
	var scale = Vector3(1, 1, 1) * gizmo_scale
	xform.basis = xform.basis.scaled(xform.basis.get_scale().inverse()).scaled(scale)
	return xform


func _set_highlight(highlight_axis) -> void:
	for i in range(3):
		move_gizmo[i].surface_set_material(
			0, axis_materials_selected[i] if i == highlight_axis else axis_materials[i]
		)
		move_plane_gizmo[i].surface_set_material(
			0, axis_materials_selected[i] if i + 6 == highlight_axis else axis_materials[i]
		)
		rotate_gizmo[i].surface_set_material(
			0, rotation_materials_selected[i] if i + 3 == highlight_axis else rotation_materials[i]
		)
		scale_gizmo[i].surface_set_material(
			0, axis_materials_selected[i] if i + 9 == highlight_axis else axis_materials[i]
		)
		scale_plane_gizmo[i].surface_set_material(
			0, axis_materials_selected[i] if i + 12 == highlight_axis else axis_materials[i]
		)


func _update_view() -> void:
	if transform == null:
		for i in range(3):
			RenderingServer.instance_set_visible(move_gizmo_instances[i], false)
			RenderingServer.instance_set_visible(move_plane_gizmo_instances[i], false)
			RenderingServer.instance_set_visible(rotate_gizmo_instances[i], false)
			RenderingServer.instance_set_visible(scale_gizmo_instances[i], false)
			RenderingServer.instance_set_visible(scale_plane_gizmo_instances[i], false)
		return

	var xform = _get_transform(_plugin.last_camera)

	for i in range(3):
		RenderingServer.instance_set_transform(move_gizmo_instances[i], xform)
		RenderingServer.instance_set_visible(move_gizmo_instances[i], true)
		RenderingServer.instance_set_transform(move_plane_gizmo_instances[i], xform)
		RenderingServer.instance_set_visible(move_plane_gizmo_instances[i], true)
		RenderingServer.instance_set_transform(rotate_gizmo_instances[i], xform)
		RenderingServer.instance_set_visible(rotate_gizmo_instances[i], true)
		RenderingServer.instance_set_transform(scale_gizmo_instances[i], xform)
		RenderingServer.instance_set_visible(scale_gizmo_instances[i], true)
		RenderingServer.instance_set_transform(scale_plane_gizmo_instances[i], xform)
		RenderingServer.instance_set_visible(scale_plane_gizmo_instances[i], true)


func select(camera: Camera3D, screen_position: Vector2, only_highlight: bool = false) -> bool:
	if transform == null:
		return false

	var ray_pos = camera.project_ray_origin(screen_position)
	var ray = camera.project_ray_normal(screen_position)
	var gt = _get_transform(camera)
	var gs = gizmo_scale

	if true:  # translate
		var col_axis = -1
		var col_d = 100000
		var is_plane_translate = false
		for i in range(3):
			var grabber_pos = (
				gt.origin
				+ gt.basis[i] * (GIZMO_ARROW_OFFSET + (GIZMO_ARROW_SIZE * 0.5))
			)
			var grabber_radius = gs * GIZMO_ARROW_SIZE
			var res = Geometry3D.segment_intersects_sphere(
				ray_pos, ray_pos + ray * 1000, grabber_pos, grabber_radius
			)
			if res.size() > 0:
				var d = res[0].distance_to(ray_pos)
				if d < col_d:
					col_d = d
					col_axis = i

		if col_axis == -1:  # plane select
			col_d = 100000
			for i in range(3):
				var ivec2 = gt.basis[(i + 1) % 3].normalized()
				var ivec3 = gt.basis[(i + 2) % 3].normalized()
				var grabber_pos = (
					gt.origin
					+ (ivec2 + ivec3) * gs * (GIZMO_PLANE_SIZE + GIZMO_PLANE_DST * 0.6667)
				)

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
			else:
				edit_mode = TransformMode.TRANSLATE
				edit_axis = col_axis + (3 if is_plane_translate else 0)
				in_edit = true
				compute_edit(camera, screen_position)
				_plugin.selection.begin_edit()
			return true

	if true:  # rotation
		var col_axis = -1
		var col_d = 100000
		for i in range(3):
			var normal = gt.basis[i].normalized()
			var plane = Plane(normal, normal.dot(gt.origin))
			var r = plane.intersects_ray(ray_pos, ray)
			if r == null:
				continue
			var dist = r.distance_to(gt.origin)
			var r_dir = (r - gt.origin).normalized()

			var camera_normal = -camera.global_transform.basis.z
			if camera_normal.dot(r_dir) <= 0.005:
				if (
					dist > gs * (GIZMO_CIRCLE_SIZE - GIZMO_RING_HALF_WIDTH)
					&& dist < gs * (GIZMO_CIRCLE_SIZE + GIZMO_RING_HALF_WIDTH)
				):
					var d = ray_pos.distance_to(r)
					if d < col_d:
						col_d = d
						col_axis = i
		if col_axis != -1:
			if only_highlight:
				_set_highlight(col_axis + 3)
			else:
				edit_mode = TransformMode.ROTATE
				edit_axis = col_axis
				in_edit = true
				compute_edit(camera, screen_position)
				_plugin.selection.begin_edit()
			return true

	if true:  # scale
		var col_axis = -1
		var col_d = 100000
		var is_plane_translate = false
		for i in range(3):
			var grabber_pos = (
				gt.origin
				+ gt.basis[i] * (GIZMO_SCALE_OFFSET + (GIZMO_SCALE_SIZE * 0.5))
			)
			var grabber_radius = gs * GIZMO_SCALE_SIZE
			var r: Vector3

			var res = Geometry3D.segment_intersects_sphere(
				ray_pos, ray_pos + ray * 1000, grabber_pos, grabber_radius
			)
			if res.size() > 0:
				var d = res[0].distance_to(ray_pos)
				if d < col_d:
					col_d = d
					col_axis = i

		if col_axis == -1:  # plane select
			col_d = 100000
			for i in range(3):
				var ivec2 = gt.basis[(i + 1) % 3].normalized()
				var ivec3 = gt.basis[(i + 2) % 3].normalized()
				var grabber_pos = (
					gt.origin
					+ (ivec2 + ivec3) * gs * (GIZMO_PLANE_SIZE + GIZMO_PLANE_SCALE_DST)
				)

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
				_set_highlight(col_axis + (12 if is_plane_translate else 9))
			else:
				edit_mode = TransformMode.SCALE
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
var edit_plane: bool = false
var edit_axis: int = TransformAxis.X
var in_edit: bool = false

var original_intersect  # nullable vector3


func compute_edit(camera: Camera3D, screen_position: Vector2, snap: float = 0.0) -> void:
	if transform == null:
		return
	if not in_edit:
		return
	var ray_pos = camera.project_ray_origin(screen_position)
	var ray = camera.project_ray_normal(screen_position)
	var xb = transform.basis.orthonormalized()
	match edit_mode:
		TransformMode.TRANSLATE:
			var p = Plane(ray, ray.dot(transform.origin))
			var motion_mask = Vector3.ZERO
			match edit_axis:
				TransformAxis.X:
					motion_mask = xb.x
					var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
					p = Plane(normal, normal.dot(transform.origin))
				TransformAxis.Y:
					motion_mask = xb.y
					var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
					p = Plane(normal, normal.dot(transform.origin))
				TransformAxis.Z:
					motion_mask = xb.z
					var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
					p = Plane(normal, normal.dot(transform.origin))
				TransformAxis.YZ:
					var normal = xb.x
					p = Plane(normal, normal.dot(transform.origin))
				TransformAxis.XZ:
					var normal = xb.y
					p = Plane(normal, normal.dot(transform.origin))
				TransformAxis.XY:
					var normal = xb.z
					p = Plane(normal, normal.dot(transform.origin))
			var intersection = p.intersects_ray(ray_pos, ray)
			if intersection == null:
				return

			if original_intersect == null:
				original_intersect = intersection

			var motion = intersection - original_intersect
			if motion_mask != Vector3.ZERO:
				motion = motion_mask.dot(motion) * motion_mask
			if snap != 0:
				motion = xb * (xb.inverse() * motion).snapped(Vector3(snap, snap, snap))

			_plugin.selection.translate_selection(motion)
		TransformMode.ROTATE:
			var plane = Plane()
			var axis = Vector3()
			match edit_axis:
				TransformAxis.X:
					var normal = xb.x
					plane = Plane(normal, normal.dot(transform.origin))
					axis = xb.x
				TransformAxis.Y:
					var normal = xb.y
					plane = Plane(normal, normal.dot(transform.origin))
					axis = xb.y
				TransformAxis.Z:
					var normal = xb.z
					plane = Plane(normal, normal.dot(transform.origin))
					axis = xb.z

			var intersection = plane.intersects_ray(ray_pos, ray)
			if intersection == null:
				return
			if original_intersect == null:
				original_intersect = intersection

			var y_axis = (original_intersect - transform.origin).normalized()
			var x_axis = plane.normal.cross(y_axis).normalized()

			var angle = atan2(
				x_axis.dot(intersection - transform.origin),
				y_axis.dot(intersection - transform.origin)
			)

			if snap:
				angle = rad_to_deg(angle) + snap * 0.5
				angle -= fmod(angle, snap)
				angle = deg_to_rad(angle)

			_plugin.selection.rotate_selection(axis, angle)
		TransformMode.SCALE:
			if (
				edit_axis == TransformAxis.X
				|| edit_axis == TransformAxis.Y
				|| edit_axis == TransformAxis.Z
			):
				var motion_mask = Vector3.ZERO
				var p = Plane()
				var scale_factor_index = -1
				match edit_axis:
					TransformAxis.X:
						motion_mask = xb.x
						scale_factor_index = 0
						var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
						p = Plane(normal, normal.dot(transform.origin))
					TransformAxis.Y:
						motion_mask = xb.y
						scale_factor_index = 1
						var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
						p = Plane(normal, normal.dot(transform.origin))
					TransformAxis.Z:
						motion_mask = xb.z
						scale_factor_index = 2
						var normal = motion_mask.cross(motion_mask.cross(ray)).normalized()
						p = Plane(normal, normal.dot(transform.origin))
				var intersection = p.intersects_ray(ray_pos, ray)
				if intersection == null:
					return

				if original_intersect == null:
					original_intersect = intersection

				var motion = intersection - original_intersect
				if motion_mask != Vector3.ZERO:
					motion = motion_mask.dot(motion) * motion_mask
				motion /= original_intersect.distance_to(transform.origin)
				if snap:
					motion = motion.snapped(Vector3(snap, snap, snap))

				var scale = Vector3(1, 1, 1) + xb.inverse() * motion
				_plugin.selection.scale_selection_along_plane_normal(
					motion_mask, scale[scale_factor_index]
				)
			else:
				var p = Plane()
				var normal: Vector3
				var scale_idx: int
				var axis_1: Vector3
				var axis_2: Vector3
				match edit_axis:
					TransformAxis.YZ:
						axis_1 = xb.y
						axis_2 = xb.z
						scale_idx = 1
						normal = xb.x
						p = Plane(normal, normal.dot(transform.origin))
					TransformAxis.XZ:
						axis_1 = xb.x
						axis_2 = xb.z
						scale_idx = 0
						normal = xb.y
						p = Plane(normal, normal.dot(transform.origin))
					TransformAxis.XY:
						axis_1 = xb.x
						axis_2 = xb.y
						scale_idx = 0
						normal = xb.z
						p = Plane(normal, normal.dot(transform.origin))
				var motion_mask = axis_1 + axis_2
				var intersection = p.intersects_ray(ray_pos, ray)
				if intersection == null:
					return

				if original_intersect == null:
					original_intersect = intersection

				var motion = intersection - original_intersect
				if motion_mask != Vector3.ZERO:
					motion = motion_mask.dot(motion) * motion_mask
				motion /= original_intersect.distance_to(transform.origin)
				if snap:
					motion = motion.snapped(Vector3(snap, snap, snap))

				var scale = Vector3(1, 1, 1) + xb.inverse() * motion
				_plugin.selection.scale_selection_along_plane(
					normal, [axis_1, axis_2], scale[scale_idx]
				)


func end_edit() -> void:
	if not in_edit:
		return

	in_edit = false
	original_intersect = null
	var name = "Ply: Transform3D"
	match edit_mode:
		TransformMode.TRANSLATE:
			name = "Ply: Translate"
		TransformMode.ROTATE:
			name = "Ply: Rotate"
		TransformMode.SCALE:
			name = "Ply: Scale"
	_plugin.selection.commit_edit(name, _plugin.get_undo_redo())


func abort_edit() -> void:
	if not in_edit:
		return
	_plugin.selection.abort_edit()
	in_edit = false
	original_intersect = null


func process() -> void:
	var basis_override = null
	if in_edit:
		basis_override = transform.basis
	if _plugin.selection:
		transform = _plugin.selection.get_selection_transform(
			_plugin.toolbar.gizmo_mode, basis_override
		)
	else:
		transform = null
	_update_view()
