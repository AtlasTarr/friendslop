extends StaticBody3D
@export var locked:= false
var open = false
var opened = false
@export var unlocker:= "key"
var initial_rot: Vector3 
var open_rot: Vector3 
var temp_rot: Vector3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_rot.y = rotation.y
	open_rot.y = rotation.y + 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
						locked = false
						open = true
				if open && !locked:
					open = false
					print("close")
					Network.rpc("network_rotate", self.get_path(), initial_rot)
				elif !open && !locked:
					open = true
					print("open")
					Network.rpc("network_rotate", self.get_path(), open_rot)
	
