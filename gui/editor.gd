tool
extends Spatial

const SelectionMode = preload("../utils/selection_mode.gd")

var edited_node = null setget set_node
func set_node(n):
	if n == edited_node:
		return
	if edited_node:
		edited_node.disconnect("transform_updated", self, "_on_transform_updated")
		edited_node.ply_mesh.disconnect("mesh_updated", self, "_on_mesh_updated")
	edited_node = n
	if edited_node:
		edited_node.connect("transform_updated", self, "_on_transform_updated")
		edited_node.ply_mesh.connect("mesh_updated", self, "_on_mesh_updated")
		transform = edited_node.global_transform
	render()

var is_visible = true setget set_is_visible
func set_is_visible(val):
	is_visible = val
	if is_visible:
		show()
	else:
		hide()

var plugin = null

var mode = SelectionMode.MESH setget set_mode
func set_mode(m):
	if mode == m:
		return
	mode = m
	render()

const FaceScene = preload("./face.tscn")
const EdgeScene = preload("./edge.tscn")
const VertexScene = preload("./vertex.tscn")

func clear_children():
	for n in get_children():
		n.queue_free()

func _on_mesh_updated():
	var expected_children = 0
	match mode:
		SelectionMode.FACE:
			expected_children = edited_node.ply_mesh.face_count()
		SelectionMode.EDGE:
			expected_children = edited_node.ply_mesh.edge_count()
		SelectionMode.VERTEX:
			expected_children = edited_node.ply_mesh.vertex_count()

	var current_children = get_child_count()
	if expected_children > current_children:
		for i in range(current_children, expected_children):
			match mode:
				SelectionMode.FACE:
					instance_face(i)
				SelectionMode.EDGE:
					instance_edge(i)
				SelectionMode.VERTEX:
					instance_vertex(i)
	elif expected_children < current_children:
		for i in range(expected_children, current_children):
			get_child(i).queue_free()

func _on_transform_updated():
	self.transform = edited_node.global_transform

func instance_face(idx):
	var sc = FaceScene.instance()
	sc.name = "face_%s" % [idx]
	sc.face_idx = idx
	sc.ply_mesh = edited_node.ply_mesh
	sc.plugin = plugin
	add_child(sc)

func render():
	match mode:
		SelectionMode.MESH:
			clear_children()
		SelectionMode.FACE:
			render_faces()
		SelectionMode.EDGE:
			render_edges()
		SelectionMode.VERTEX:
			render_vertices()

func render_faces():
	clear_children()
	if not edited_node:
		return 
	for idx in range(edited_node.ply_mesh.face_count()):
		instance_face(idx)

func instance_edge(idx):
	var sc = EdgeScene.instance()
	sc.name = "edge_%s" % [idx]
	sc.edge_idx = idx
	sc.ply_mesh = edited_node.ply_mesh
	sc.plugin = plugin
	add_child(sc)

func render_edges():
	clear_children()
	if not edited_node:
		return
	for idx in range(edited_node.ply_mesh.edge_count()):
		instance_edge(idx)

func instance_vertex(idx):
	var v = edited_node.ply_mesh.vertexes[idx]
	var sc = VertexScene.instance()
	sc.name = "vertex_%s" % [idx]
	sc.vertex_idx = idx
	sc.ply_mesh = edited_node.ply_mesh
	sc.transform.origin = v
	sc.plugin = plugin
	add_child(sc)

func render_vertices():
	clear_children()
	for idx in range(edited_node.ply_mesh.vertex_count()):
		instance_vertex(idx)
