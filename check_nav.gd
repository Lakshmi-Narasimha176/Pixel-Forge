@tool
extends SceneTree

func _init():
	var ps = load("res://horror/main.tscn")
	var root = ps.instantiate()
	root._ready()

	print("=== ROOMS & DOORS CONNECTIVITY ===")
	for r in root.ROOMS:
		print("Room: ", r.id, " x:[", r.i * 2, ", ", (r.i + r.w) * 2, "] z:[", r.j * 2, ", ", (r.j + r.h) * 2, "]")
	
	print("\n=== DOORS ===")
	for d in root.doors:
		print("Door: ", d.label, " at ", d.pos, " locked:", d.locked, " lock:", d.lock)
	
	print("\n=== NAV GRAPH ===")
	for k in root.nav:
		var nbs = []
		for nb in root.nav[k]:
			nbs.append(nb.to + ((" (DOOR:" + nb.door.label + ")") if nb.door else ""))
		print("Cell ", k, " -> ", nbs)

	quit()
