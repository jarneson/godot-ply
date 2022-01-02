tool
extends VBoxContainer

onready var translate_container = $"G/Translate"
var translate_x 
var translate_y 
var translate_z 
onready var rotate_container = $"G/Rotate"
var rotate_x
var rotate_y
var rotate_z
onready var scale_container = $"G/Scale"
var scale_x
var scale_y
var scale_z
onready var apply = $"G/Apply"

var plugin = null

func _ready():
	var sl = EditorSpinSlider.new()
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.label = "x"
	translate_container.add_child(sl)

func _process(delta):
	if not plugin or not plugin.selection:
		# should get freed
		return
	pass
