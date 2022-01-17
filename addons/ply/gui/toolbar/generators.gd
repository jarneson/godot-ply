tool
extends AcceptDialog

onready var selection_plane = $"C/C/Generators/C/Plane"
onready var selection_cube = $"C/C/Generators/C/Cube"
onready var selection_icosphere = $"C/C/Generators/C/Icosphere"
onready var selection_cylinder = $"C/C/Generators/C/Cylinder"

onready var settings_plane = $"C/C/Settings/PlaneSettings"
onready var plane_size = $"C/C/Settings/PlaneSettings/SizeInput"
onready var plane_subdivisions = $"C/C/Settings/PlaneSettings/SubdivisionsInput"

onready var settings_cube = $"C/C/Settings/CubeSettings"
onready var cube_size = $"C/C/Settings/CubeSettings/SizeInput"
onready var cube_subdivisions = $"C/C/Settings/CubeSettings/SubdivisionsInput"

onready var settings_icosphere = $"C/C/Settings/IcosphereSettings"
onready var icosphere_radius = $"C/C/Settings/IcosphereSettings/RadiusInput"
onready var icosphere_subdivisions = $"C/C/Settings/IcosphereSettings/SubdivisionsInput"

onready var settings_cylinder = $"C/C/Settings/CylinderSettings"
onready var cylinder_radius = $"C/C/Settings/CylinderSettings/RadiusInput"
onready var cylinder_depth = $"C/C/Settings/CylinderSettings/DepthInput"
onready var cylinder_vertices = $"C/C/Settings/CylinderSettings/VerticesInput"
onready var cylinder_segments = $"C/C/Settings/CylinderSettings/SegmentsInput"

var current_selection = "None"


func _ready() -> void:
	selection_plane.connect("pressed", self, "_set_selection", ["Plane"])
	selection_cube.connect("pressed", self, "_set_selection", ["Cube"])
	selection_icosphere.connect("pressed", self, "_set_selection", ["Icosphere"])
	selection_cylinder.connect("pressed", self, "_set_selection", ["Cylinder"])


func _set_selection(sel) -> void:
	current_selection = sel
	_update_display()


func _hide_settings() -> void:
	settings_plane.visible = false
	settings_cube.visible = false
	settings_icosphere.visible = false
	settings_cylinder.visible = false


func _update_display() -> void:
	_hide_settings()
	match current_selection:
		"Plane":
			settings_plane.visible = true
		"Cube":
			settings_cube.visible = true
		"Icosphere":
			settings_icosphere.visible = true
		"Cylinder":
			settings_cylinder.visible = true


func get_selection() -> Array:
	match current_selection:
		"Plane":
			return ["Plane", [float(plane_size.text), int(plane_subdivisions.text)]]
		"Cube":
			return ["Cube", [float(cube_size.text), int(cube_subdivisions.text)]]
		"Icosphere":
			return ["Icosphere", [float(icosphere_radius.text), int(icosphere_subdivisions.text)]]
		"Cylinder":
			return [
				"Cylinder",
				[
					float(cylinder_radius.text),
					float(cylinder_depth.text),
					int(cylinder_vertices.text),
					int(cylinder_segments.text)
				]
			]
	return []
