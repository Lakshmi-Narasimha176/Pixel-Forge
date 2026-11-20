@tool
extends SceneTree

func _init():
	for name in ["modular_vintage_living_room_-_game_ready_pbr.glb", "horror_room.glb", "horror_soviet_room.glb", "weathered_red_saltbox_farmhouse.glb"]:
		var ps = load("res://" + name)
		if ps:
			var n = ps.instantiate()
			print(name, " instanced, children: ", n.get_child_count())
			_dump(n, 0)
	quit()

func _dump(n: Node, depth: int):
	if depth > 4: return
	var indent = ""
	for i in depth: indent += "  "
	print(indent, n.name)
	for c in n.get_children():
		_dump(c, depth + 1)
