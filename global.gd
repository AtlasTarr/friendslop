extends Node


var Username:= ""

var BALL = load("res://misc/bullet.tscn")

@rpc("any_peer", "call_local")
func shoot_ball(pos, dir, force):
	var new_ball: RigidBody3D = BALL.instantiate()
	new_ball.position = pos + Vector3(0.0, 1.5, 0.0) + (dir * 1.2)
	get_tree().current_scene.add_child(new_ball, true)
	new_ball.apply_central_impulse(dir * force)
