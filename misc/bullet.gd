extends RigidBody3D
class_name Bullet

var velocity: Vector3
var gravity: float = 9.8
var shot_by: CharacterBody3D
@export var collision_array: Array
@export var damage: float
@onready var ray: RayCast3D = $RayCast3D


func effector():
	collision_array = get_colliding_bodies()
	
	for index in collision_array:
		if index.is_in_group("actor"):
			index.damage(damage)
			if index.has_method("agression_controller"):
				index.agression_controller(shot_by)
				_on_timer_timeout()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	effector()


func _on_timer_timeout() -> void:
	visible = false
	print("bullet deleted")
	queue_free()
