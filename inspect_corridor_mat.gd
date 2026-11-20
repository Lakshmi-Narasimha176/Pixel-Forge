@tool
extends SceneTree

func _init():
	var ps = load("res://horror_corridor_5.glb")
	var n = ps.instantiate()
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi = c as MeshInstance3D
		print("Mesh: ", mi.name)
		for i in mi.get_surface_override_material_count():
			print("  surface mat ", i, ": ", mi.get_surface_override_material(i))
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				print("  mesh mat ", i, ": ", mi.mesh.surface_get_material(i))
	quit()
