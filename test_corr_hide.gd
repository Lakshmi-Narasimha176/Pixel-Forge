
@tool
extends SceneTree
func _init():
    var ps = load("res://horror_corridor_5.glb")
    var n = ps.instantiate()
    n.rotation.x = -PI / 2.0
    for c in n.find_children("*", "MeshInstance3D", true, false):
        if "backside" in c.name.to_lower():
            c.visible = false
            print("Hid: ", c.name)
    quit()
