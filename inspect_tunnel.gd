@tool
extends SceneTree

func _init():
	var ps = load("res://tunnel.glb")
	if ps:
		var n = ps.instantiate()
		print("Tunnel loaded, node count: ", n.get_child_count())
		_dump_node(n, 0)
	quit()

func _dump_node(n: Node, depth: int):
	var indent = ""
	for i in depth: indent += "  "
	print(indent, n.name, " (", n.get_class(), ")")
	if n is MeshInstance3D and n.mesh:
		print(indent, "  mesh aabb: ", n.mesh.get_aabb())
	for c in n.get_children():
		_dump_node(c, depth + 1)
