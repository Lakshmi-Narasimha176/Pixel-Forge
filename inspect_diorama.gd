@tool
extends SceneTree

func _init():
	var ps = load("res://textured_game_environment.glb")
	if ps:
		var n = ps.instantiate()
		print("textured_game_environment child count: ", n.get_child_count())
		_dump(n, 0)
	quit()

func _dump(n: Node, depth: int):
	if depth > 4: return
	var indent = ""
	for i in depth: indent += "  "
	print(indent, n.name, " (", n.get_class(), ")")
	if n is MeshInstance3D and n.mesh:
		print(indent, "  mesh aabb: ", n.mesh.get_aabb())
	for c in n.get_children():
		_dump(c, depth + 1)
