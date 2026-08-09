extends RigidBody3D
@export var Item_name: = "Default item"
@export var is_shared: = true

func _process(delta: float) -> void:
	
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
