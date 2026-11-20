@tool
extends SceneTree

func _init():
	var ps = load("res://horror_corridor_5.glb")
	var n = ps.instantiate()
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi = c as MeshInstance3D
		if mi.mesh:
			print(mi.name, " mesh aabb: ", mi.mesh.get_aabb())
	quit()
