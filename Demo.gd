extends Spatial


func _ready():
	var b1 = Basis.IDENTITY
	var b2 = Basis(Vector3.UP, PI)
	print(b1 * b2)
	print(b2 / b1)
