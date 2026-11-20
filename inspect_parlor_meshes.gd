@tool
extends SceneTree

func _init():
	var ps = load("res://modular_vintage_living_room_-_game_ready_pbr.glb")
	var n = ps.instantiate()
	for c in n.find_children("*", "MeshInstance3D", true, false):
		print("Parlor mesh: ", c.name)
	quit()
