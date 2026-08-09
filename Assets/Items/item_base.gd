extends RigidBody3D
@export var Item_name: = "Default item"
@export var is_shared: = true
var added = false
const DOOR = preload("res://Assets/Items/Item_base.tscn")

func _ready() -> void:
	multiplayer.peer_connected.connect(virtualise)

func _process(delta: float) -> void:
	if !added:
		virtualise()
	var ovl = $Area3D.get_overlapping_bodies()
	for body in ovl:
		if body is Player:
			if body.interacting:
				body.inventory.append(Item_name)
				print(Item_name)
				if is_shared:
					Network.rpc("network_remove", self.get_path())
				else:
					queue_free()

func virtualise():
	self.added = true
	Network.network_spawn(DOOR, str(name, "net"))
	var new_door = get_tree().current_scene.get_node(str("/root/lobby/", name, "net")).get_path()
	Network.set_variables(new_door, ["Item_name","is_shared","added","position","rotation"],[Item_name,is_shared,true,position,rotation])
	Network.rpc("network_remove", get_path())
