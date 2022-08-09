"""
MIT License

Copyright (c) 2022  Jeffrey Arneson, Sólyom Zoltán, András Kis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
tool
extends Control


signal selection_mode_changed(mode)
signal gizmo_mode_changed(mode)

const SelectionMode = preload("res://addons/ply/utils/selection_mode.gd")
const GizmoMode = preload("res://addons/ply/utils/gizmo_mode.gd")

const Invert = preload("res://addons/ply/resources/invert.gd")
const Extrude = preload("res://addons/ply/resources/extrude.gd")
const Subdivide = preload("res://addons/ply/resources/subdivide.gd")
const Triangulate = preload("res://addons/ply/resources/triangulate.gd")
const Loop = preload("res://addons/ply/resources/loop.gd")
const Collapse = preload("res://addons/ply/resources/collapse.gd")
const Connect = preload("res://addons/ply/resources/connect.gd")

var selection_mode: int = SelectionMode.MESH

var plugin: EditorPlugin

func _ready():

	pass

func _face_select_loop(offset):
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() != 1
	):
		return
	var loop = Loop.get_face_loop(
		plugin.selection.ply_mesh, plugin.selection.selected_faces[0], offset
	)[0]
	plugin.selection.selected_faces = loop


func _face_extrude():
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() == 0
	):
		return
	Extrude.faces(
		plugin.selection.ply_mesh, plugin.selection.selected_faces, plugin.get_undo_redo(), 1
	)
	


func _face_connect():
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() != 2
	):
		return
	Connect.faces(
		plugin.selection.ply_mesh,
		plugin.selection.selected_faces[0],
		plugin.selection.selected_faces[1],
		plugin.get_undo_redo()
	)


func _face_subdivide():
	if not plugin.selection or selection_mode != SelectionMode.FACE:
		return
	Subdivide.faces(
		plugin.selection.ply_mesh, plugin.selection.selected_faces, plugin.get_undo_redo()
	)


func _face_triangulate():
	if not plugin.selection or selection_mode != SelectionMode.FACE:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Triangulate.faces(plugin.selection.ply_mesh, plugin.selection.selected_faces)
	plugin.selection.ply_mesh.commit_edit("Triangulate Faces", plugin.get_undo_redo(), pre_edit)


func _set_face_surface(s):
	if (
		not plugin.selection
		or selection_mode != SelectionMode.FACE
		or plugin.selection.selected_faces.size() == 0
	):
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	for f_idx in plugin.selection.selected_faces:
		plugin.selection.ply_mesh.set_face_surface(f_idx, s)
	plugin.selection.ply_mesh.commit_edit("Paint Face", plugin.get_undo_redo(), pre_edit)


func _edge_select_loop():
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() != 1
	):
		return
	var loop = Loop.get_edge_loop(plugin.selection.ply_mesh, plugin.selection.selected_edges[0])
	plugin.selection.selected_edges = loop


func _edge_cut_loop():
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() != 1
	):
		return
	Loop.edge_cut(
		plugin.selection.ply_mesh, plugin.selection.selected_edges[0], plugin.get_undo_redo()
	)


func _edge_subdivide():
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() != 1
	):
		return
	Subdivide.edge(
		plugin.selection.ply_mesh, plugin.selection.selected_edges[0], plugin.get_undo_redo()
	)


func _edge_collapse():
	if (
		not plugin.selection
		or selection_mode != SelectionMode.EDGE
		or plugin.selection.selected_edges.size() == 0
	):
		return
	if Collapse.edges(
		plugin.selection.ply_mesh, plugin.selection.selected_edges, plugin.get_undo_redo()
	):
		plugin.selection.selected_edges = []

#
#func _export_to_obj():
#	if not plugin.selection or selection_mode != SelectionMode.MESH:
#		return
#	var fd = FileDialog.new()
#	fd.set_filters(PoolStringArray(["*.obj ; OBJ Files"]))
#	var base_control = plugin.get_editor_interface().get_base_control()
#	base_control.add_child(fd)
#	fd.popup_centered(Vector2(480, 600))
#	var file_name = yield(fd, "file_selected")
#	var obj_file = File.new()
#	obj_file.open(file_name, File.WRITE)
#	ExportMesh.export_to_obj(plugin.selection.ply_mesh, obj_file)


func _mesh_subdivide():
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Subdivide.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Subdivide Mesh", plugin.get_undo_redo(), pre_edit)


func _mesh_triangulate():
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Triangulate.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Subdivide Mesh", plugin.get_undo_redo(), pre_edit)

func _mesh_invert_normals():
	if not plugin.selection or selection_mode != SelectionMode.MESH:
		return
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Invert.normals(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Invert Normals", plugin.get_undo_redo(), pre_edit)


func _update_selection_mode(selected, mode):
	if selected:
		selection_mode = mode
		emit_signal("selection_mode_changed", mode)


var gizmo_mode: int = GizmoMode.LOCAL

func _update_gizmo_mode(selected, mode):
	if selected:
		gizmo_mode = mode
		emit_signal("gizmo_mode_changed", mode)
