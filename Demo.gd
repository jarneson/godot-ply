extends Spatial

func _ready():
	var n = Node.new()
	add_child(n)
	n = Node.new()
	add_child(n)
	n = Node.new()
	add_child(n)
	n = Node.new()
	add_child(n)

func _physics_process(delta):
	print("physics process")

func _process(delta):
	print("process")
