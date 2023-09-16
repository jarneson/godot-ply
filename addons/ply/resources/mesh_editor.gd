@tool
extends Resource
class_name PlyMeshEditor

const Math = preload("res://addons/ply/utils/math.gd")
const PlyMesh = preload("res://addons/ply/resources/ply_mesh.gd")

var _pm: PlyMesh

func _init(pm: PlyMesh):
	_pm = pm

#########################################
# Vertices
#########################################
class Vertex:
	var _p: PlyMeshEditor
	var _i: int

	func id() -> int:
		return _i

	func _init(p: PlyMeshEditor, idx: int):
		_i = idx
		_p = p
	
	func position() -> Vector3:
		return _p._pm.vertexes[_i]

func call_each_vertex(fn: Callable) -> void:
	var e = Vertex.new(self, 0)
	for i in range(_pm.vertex_count()):
		e._init(self, i)
		fn.call(e)

#########################################
# Edges
#########################################
class Edge:
	var _p: PlyMeshEditor
	var _i: int

	func _init(p: PlyMeshEditor, idx: int):
		_i = idx
		_p = p

	func id() -> int:
		return _i

	func origin() -> Vertex:
		return Vertex.new(_p, _p._pm.edge_vertexes[_i*2])

	func destination() -> Vertex:
		return Vertex.new(_p, _p._pm.edge_vertexes[_i*2+1])

	func next_clockwise_edge(f: Face) -> Edge:
		if _p._pm.edge_faces[_i*2] == f.id():
			return Edge.new(_p, _p._pm.edge_edges[_i*2])
		else:
			return Edge.new(_p, _p._pm.edge_edges[_i*2+1])

func call_each_edge(fn: Callable) -> void:
	var e = Edge.new(self, 0)
	for i in range(_pm.edge_count()):
		e._init(self, i)
		fn.call(e)

#########################################
# Faces
#########################################
class Face:
	var _p: PlyMeshEditor
	var _i: int

	func id() -> int:
		return _i

	func _init(p: PlyMeshEditor, idx: int):
		_i = idx
		_p = p

	func edges() -> Array:
		var start = _p._pm.face_edges[_i]
		var out = []
		out.push_back(Edge.new(_p, start))
		var e = out[0].next_clockwise_edge(self)
		while e.id() != out[0].id():
			out.push_back(e)
			e = e.next_clockwise_edge(self)
		return out

	func raw_vertices() -> Array:
		var out = []
		var edges = self.edges()
		for e in edges:
			if _p._pm.edge_faces[2*e.id()] == id():
				out.push_back(e.destination().position())
			else:
				out.push_back(e.origin().position())
		return out

	func vertices() -> Array:
		var out = []
		var edges = self.edges()
		for e in edges:
			if _p._pm.edge_faces[2*e.id()] == id():
				out.push_back(e.destination())
			else:
				out.push_back(e.origin())
		return out

	func normal() -> Vector3:
		return Math.face_normal(self.raw_vertices())

func call_each_face(fn: Callable) -> void:
	var e = Face.new(self, 0)
	for i in range(_pm.face_count()):
		e._init(self, i)
		fn.call(e)
