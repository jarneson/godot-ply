@tool
extends GridContainer

var res_data = Res_Ply_Data.new()
var SAVEPATH = "res://addons/ply/gui/toolbar/Button_Vertex_Color_Container_data.tres"
func _init():
	tree_entered.connect(tree_enter)
	tree_exiting.connect(tree_exit)

func _ready():
	if ResourceLoader.exists(SAVEPATH):
		res_data = load(SAVEPATH) as Res_Ply_Data
		for o in get_children():
			var color = res_data.data.get(o.name)
			if color:
				o.color = color

func tree_enter():
	pass

func tree_exit():
	ResourceSaver.save(res_data, SAVEPATH)

func save_color(pname, color):
	res_data.data[pname] = color
