@tool
extends SceneTree

func _init():
	var ps = load("res://horror_corridor_5.glb")
	if ps:
		var n = ps.instantiate()
		print("horror_corridor_5 child count: ", n.get_child_count())
		_dump(n, 0)
	quit()

func _dump(n: Node, depth: int):
	var indent = ""
	for i in depth: indent += "  "
	print(indent, n.name, " (", n.get_class(), ")")
	if n is CollisionShape3D:
		print(indent, "  COLLISION: ", n.shape)
	for c in n.get_children():
		_dump(c, depth + 1)
