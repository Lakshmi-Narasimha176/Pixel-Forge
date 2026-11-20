@tool
extends SceneTree

func _init():
	var main_ps = load("res://horror/main.tscn")
	var root = main_ps.instantiate()
	root._ready()
	print("Player initial pos: ", root.player.position)
	print("Doors count: ", root.doors.size())
	for d in root.doors:
		print("Door: ", d.label, " at pos: ", d.pos, " locked: ", d.locked, " lock: ", d.lock)
	quit()
