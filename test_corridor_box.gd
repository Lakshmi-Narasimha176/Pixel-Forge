@tool
extends SceneTree

func _init():
	var ps = load("res://horror_corridor_5.glb")
	var n = ps.instantiate()
	var bb = AABB()
	var has = false
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi = c as MeshInstance3D
		if mi.mesh:
			var a = mi.mesh.get_aabb()
			if not has: bb = a; has = true
			else: bb = bb.merge(a)
	print("Corridor raw AABB: ", bb)
	quit()
