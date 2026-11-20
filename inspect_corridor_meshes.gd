@tool
extends SceneTree

func _init():
	var ps = load("res://horror_corridor_5.glb")
	var n = ps.instantiate()
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi = c as MeshInstance3D
		if mi.mesh:
			print(mi.name, " aabb: ", mi.mesh.get_aabb())
			for i in mi.mesh.get_surface_count():
				var mat = mi.mesh.surface_get_material(i)
				if mat is StandardMaterial3D:
					print("  mat: ", mat.resource_name, " albedo_color: ", mat.albedo_color, " tex: ", mat.albedo_texture)
	quit()
