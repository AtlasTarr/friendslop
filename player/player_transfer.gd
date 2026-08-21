extends CharacterBody3D
class_name Player

signal toggle_inventory()

const objecct_scene = "res://quest_library/player/player_transfer.tscn"

@export var inventory: Array[String]

var mouse_sensitivity = 0.002

@onready var camera = $Pivot/Camera
@onready var camera_2 = $Pivot/Camera/SubViewportContainer/SubViewport/Camera

@onready var base_fov = camera.fov

@onready var interact_ray = $Pivot/Camera/interact_ray

@export var mass : float = 1

@export var interacting: = false

var speed
var air_speed
var base_speed: = 5
var run_speed = 7

var temp_scale = 1.0

var tab: = false

var start: bool = true

var jump = 5.5

@onready var pivot: Node3D = $Pivot
var anim_model
@onready var anim_tree: AnimationTree = $"Dwarf Walk/AnimationTree"
@onready var anim_player: AnimationPlayer = $"Dwarf Walk/AnimationPlayer"
@onready var label: Label = %Label

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8 * mass
var running: bool = false

@export var username: = ""

var tube_client := TubeClient.new()
const FRIENDSLOP = preload("res://friendslop.tres")
const BULLET = preload("res://misc/bullet.tscn")
var bullets: Array = []
@onready var dwarf_walk: Node3D = $"Dwarf Walk"
@export var skin_colour = null

var health = 100

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	tube_client.context = FRIENDSLOP
	if !is_multiplayer_authority():
		return
	label.text = Global.Username
	username = Global.Username
	camera.current = true
	speed = 10
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

@rpc("any_peer", "call_local")
func set_colour(colour: Color):
	if skin_colour == null:
		print("set_colour to ", colour)
		
		$"Dwarf Walk".update_colour(colour)
		Network.set_variables(get_path(), ["skin_colour"], [colour])
	else:
		$"Dwarf Walk".update_colour(skin_colour)
		print("skin colour", skin_colour)
	

func damage(damage: float):
	if !is_multiplayer_authority(): return
	health -= damage
	print(health)

func death_state_checker():
	if !is_multiplayer_authority(): return
	if health <= 0:
		queue_free()

func heal(heal_amount: int):
	if !is_multiplayer_authority(): return
	health += heal_amount

func _unhandled_input(event):
	if !is_multiplayer_authority(): return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -1.2, 1.2)
		
	
	if Input.is_action_just_pressed("interact"):
		interact()

func _physics_process(delta):
	
	self.scale.y = lerp(self.scale.y, temp_scale, delta * 3)
	camera_2.global_transform = camera.global_transform

	if Input.is_action_just_pressed("shoot"):
		if !is_multiplayer_authority(): return
		var dir = $Pivot/Camera.global_position.direction_to($Pivot/Camera/gun_container.global_position)
		Network.rpc("network_add", BULLET, "bullet")
		
		for child in get_tree().current_scene.get_children():
			if child is Bullet:
				bullets.append(child)
		Network.rpc("set_variables", bullets[bullets.size() -1 ].get_path(), ["position"], [$Pivot/Camera/gun_container.global_transform.origin])
		var bullet = bullets[bullets.size()-1]
		bullet.apply_central_impulse(dir * 100)
	if Input.is_action_just_pressed("crouch"):
		if !is_multiplayer_authority(): return
		temp_scale = 0.5
		speed = speed/2
		self.global_transform.origin.y -= 0.5
	if Input.is_action_just_pressed("dash"):
		if !is_multiplayer_authority(): return
		add_velocity(-camera.global_transform.basis.z*10)
	if Input.is_action_just_released("crouch"):
		if !is_multiplayer_authority(): return
		temp_scale = 1.0
		speed = base_speed
	if Input.is_action_just_pressed("inventory"):
		if !tab:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			tab = true
		else :
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			tab = false
	if Input.is_action_just_pressed("interact"):
		if !is_multiplayer_authority(): return
		print("interact")
		interacting = true
	else:
		interacting = false

	if Input.is_action_pressed("sprint"):
		if !is_multiplayer_authority(): return
		speed = run_speed
		running = true
	if Input.is_action_pressed("sprint"):
		var fov = lerp(camera.fov, base_fov + 20, delta+ 0.1)
		camera.fov = fov
	else:
		if !is_multiplayer_authority(): return
		speed = base_speed
		running = false
		var fov = lerp(camera.fov, base_fov, delta + 0.05)
		camera.fov = fov
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	Move(delta)

func Move(delta):
	if !is_multiplayer_authority(): return
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = (direction.x * speed)
			velocity.z = (direction.z * speed)
			velocity.normalized()
			if !running:
				if  input_dir == Vector2(0,-1):
					anim_state_clear()
					anim_tree.set("parameters/conditions/walking",true)
				if  input_dir == Vector2(0,1):
					anim_state_clear()
					anim_tree.set("parameters/conditions/WB",true)
				elif input_dir == Vector2(1,0):
					anim_state_clear()
					anim_tree.set("parameters/conditions/right",true)
				elif input_dir == Vector2(-1,0):
					anim_state_clear()
					anim_tree.set("parameters/conditions/left",true)
			else:
				if  input_dir == Vector2(0,-1):
					anim_state_clear()
					anim_tree.set("parameters/conditions/running",true)
				if  input_dir == Vector2(0,1):
					anim_state_clear()
					anim_tree.set("parameters/conditions/RB",true)
		else:
			anim_state_clear()
			anim_tree.set("parameters/conditions/idle",true)
			velocity.z = lerp(velocity.z, 0.0, delta + 0.05)
			velocity.x = lerp(velocity.x, 0.0, delta + 0.05)
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = jump
			anim_state_clear()
			anim_tree.set("parameters/conditions/jump", true)

	else:
		velocity.x -= velocity.x * delta * mass
		velocity.z -= velocity.z * delta * mass
		velocity.y -= gravity * delta
	move_and_slide()

func anim_state_clear():
	if !is_multiplayer_authority(): return
	anim_tree.set("parameters/conditions/walking", false)
	anim_tree.set("parameters/conditions/idle", false)
	anim_tree.set("parameters/conditions/jump", false)
	anim_tree.set("parameters/conditions/running", false)
	anim_tree.set("parameters/conditions/right", false)
	anim_tree.set("parameters/conditions/left", false)
	anim_tree.set("parameters/conditions/RB", false)
	anim_tree.set("parameters/conditions/WB", false)

func interact():
	if !is_multiplayer_authority(): return
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if  collider.is_in_group("DialougeHolder"):
			if collider.can_access_inventory == true:
				collider.inventory_interact()
		elif "inventory" in collider:
			collider.inventory_interact()

func add_velocity(a_velocity: Vector3):
	if !is_multiplayer_authority(): return
	velocity = velocity+a_velocity
