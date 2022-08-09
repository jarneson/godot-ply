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

const Generate = preload("res://addons/ply/resources/generate.gd")
const ExportMesh = preload("res://addons/ply/resources/export.gd")
const Extrude = preload("res://addons/ply/resources/extrude.gd")
const Subdivide = preload("res://addons/ply/resources/subdivide.gd")


var current_selection = "None"
var plugin = EditorPlugin

func _generate_cube(params = null):
	if not plugin.selection:
		return
	var size = 1
	var subdivisions = 0
	if params != null:
		size = params[0]
		subdivisions = params[1]
	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	var vertexes = [
		size * Vector3(-0.5, 0, -0.5),
		size * Vector3(0.5, 0, -0.5),
		size * Vector3(0.5, 0, 0.5),
		size * Vector3(-0.5, 0, 0.5)
	]
	Generate.nGon(plugin.selection.ply_mesh, vertexes)
	Extrude.faces(plugin.selection.ply_mesh, [0], null, size)
	for i in range(subdivisions):
		Subdivide.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Generate Cube", plugin.get_undo_redo(), pre_edit)


func _generate_plane(params = null):
	if not plugin.selection:
		return

	var size = 1
	var subdivisions = 0
	if params != null:
		size = params[0]
		subdivisions = params[1]

	var vertexes = [
		size * Vector3(-0.5, 0, -0.5),
		size * Vector3(0.5, 0, -0.5),
		size * Vector3(0.5, 0, 0.5),
		size * Vector3(-0.5, 0, 0.5)
	]

	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Generate.nGon(plugin.selection.ply_mesh, vertexes)
	for i in range(subdivisions):
		Subdivide.object(plugin.selection.ply_mesh)
	plugin.selection.ply_mesh.commit_edit("Generate Plane", plugin.get_undo_redo(), pre_edit)


func _generate_cylinder(params = null):
	if not plugin.selection:
		return

	var radius = 1
	var depth = 1
	var num_points = 8
	var num_segments = 1
	if params:
		radius = params[0]
		depth = params[1]
		num_points = params[2]
		num_segments = params[3]

	var vertexes = []
	for i in range(num_points):
		vertexes.push_back(
			Vector3(
				radius * cos(float(i) / num_points * 2 * PI),
				-depth / 2,
				radius * sin(float(i) / num_points * 2 * PI)
			)
		)

	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Generate.nGon(plugin.selection.ply_mesh, vertexes)
	for i in range(num_segments):
		Extrude.faces(plugin.selection.ply_mesh, [0], null, depth / num_segments)
	plugin.selection.ply_mesh.commit_edit("Generate Cylinder", plugin.get_undo_redo(), pre_edit)


func _generate_icosphere(params = null):
	if not plugin.selection:
		return

	var radius = 1.0
	var subdivides = 0
	if params:
		radius = params[0]
		subdivides = params[1]

	var pre_edit = plugin.selection.ply_mesh.begin_edit()
	Generate.icosphere(plugin.selection.ply_mesh, radius, subdivides)
	plugin.selection.ply_mesh.commit_edit("Generate Icosphere", plugin.get_undo_redo(), pre_edit)

func generate():
	if $"%Plane".pressed:
		_generate_plane([float($"%PlaneSizeInput".text), int($"%PlaneSubdivisionsInput".text)])
	elif $"%Cube".pressed:
		_generate_cube([float($"%CubeSizeInput".text), int($"%CubeSubdivisionsInput".text)])
	elif $"%Icosphere".pressed:
		_generate_icosphere([float($"%IcosphereRadiusInput".text), int($"%IcosphereSubdivisionsInput".text)])
	elif $"%Cylinder".pressed:
		_generate_cylinder(
			[
				float($"%CylinderRadiusInput".text),
				float($"%CylinderDepthInput".text),
				int($"%CylinderVerticesInput".text),
				int($"%CylinderSegmentsInput".text)
			])
	pass


func _on_visibility_changed():
	pass # Replace with function body.
