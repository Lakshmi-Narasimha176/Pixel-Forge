@tool
extends SceneTree

func _init():
	var ps = load("res://horror_corridor_5.glb")
	var n = ps.instantiate()
	print("--- TESTING CORRIDOR ORIENTATION ---")
	# In the model, the floor is at Z=0, ceiling is at Z=312.
	# Let us rotate by -PI/2 on X so Z becomes Y (up)!
	n.rotation.x = -PI / 2.0
	
	# Compute transformed AABB
	var t = n.transform
	var bb = AABB()
	var has = false
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi = c as MeshInstance3D
		if mi.mesh:
			var a = t * mi.mesh.get_aabb()
			if not has: bb = a; has = true
			else: bb = bb.merge(a)
	print("Transformed AABB (after rot X=-90deg): ", bb)
	print("Height Y: ", bb.size.y)
	print("Width X: ", bb.size.x)
	print("Length Z: ", bb.size.z)
	
	var target_h = 2.8
	var scale_factor = target_h / bb.size.y
	print("Scale factor for 2.8m height: ", scale_factor)
	print("Scaled dimensions: ", bb.size * scale_factor)
	quit()
