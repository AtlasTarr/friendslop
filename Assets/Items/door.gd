extends StaticBody3D
class_name Door
@export var locked:= false
@export var open = false
var opened = false
@export var unlocker:= "key"
var initial_rot: Vector3 
var open_rot: Vector3 
var temp_rot: Vector3
@export var added:= false

const DOOR = preload("res://Assets/Items/door.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_rot.y = rotation.y
	open_rot.y = rotation.y + 2
	multiplayer.peer_connected.connect(virtualise)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !added:
		virtualise()
	var bodys: = []
	var ovl = $Area3D.get_overlapping_bodies()
	var ovl2 = $Area3D2.get_overlapping_bodies()
	bodys.append_array(ovl)
	bodys.append_array(ovl2)
	for body in bodys:
		if body is Player:
			if body.interacting:
				if locked:
					if body.inventory.has(unlocker):
						Network.rpc("set_variables", get_path(), ["locked"],[false])
						open = true
				if open && !locked:
					Network.rpc("set_variables", get_path(), ["open"],[false])
				elif !open && !locked:
					Network.rpc("set_variables", get_path(), ["open"],[true])
	
	if rotation.y > initial_rot.y && !open:
		rotation.y = lerp(rotation.y, initial_rot.y,delta)
		print(str("closing"))
	if rotation.y < open_rot.y && open:
		rotation.y = lerp(rotation.y, open_rot.y,delta)
		print("opening")
	Network.rpc("network_rotate", get_path(), rotation)



func virtualise():
	print("virtualised")
	self.added = true
	Network.network_spawn(DOOR, str(name, "net"))
	var new_door = get_tree().current_scene.get_node(str("/root/lobby/", name, "net")).get_path()
	Network.set_variables(new_door, ["initial_rot","open_rot","locked","unlocker","added","position","rotation"],[initial_rot,open_rot,locked,unlocker,true,position,rotation])
	Network.rpc("network_remove", get_path())
	var new_door_n = get_node(new_door)
