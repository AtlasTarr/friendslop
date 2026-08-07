extends CharacterBody3D
class_name Player

signal toggle_inventory()

const objecct_scene = "res://quest_library/player/player_transfer.tscn"

var mouse_sensitivity = 0.002

@export var _playerdata: PlayerData

@onready var camera = $Pivot/Camera
@onready var camera_2 = $Pivot/Camera/SubViewportContainer/SubViewport/Camera

@onready var base_fov = camera.fov

@onready var interact_ray = $Pivot/Camera/interact_ray

@export var UI_active: bool = false


@export var mass : float = 1

var speed
var air_speed

var temp_scale = 1.0


var start: bool = true

@export var old_helmet_inventory: Equip_Helmet_Data
@export var old_body_inventory: Equip_Body_Data
@export var old_weapon_inventory: Equip_Weapon_Data

@export var inventory: Inventory_Data
@export var equip_helmet_data: Equip_Helmet_Data
@export var equip_body_data: Equip_Body_Data
@export var equip_weapon_data: Equip_Weapon_Data
@export var current_weapon_data: Gun_Data 

@onready var gun_container: Node3D = $Pivot/gun_container
@onready var pivot: Node3D = $Pivot

@onready var anim_tree: AnimationTree = $"Dwarf Walk/AnimationTree"
@onready var anim_player: AnimationPlayer = $"Dwarf Walk/AnimationPlayer"
var defence: float

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8 * mass
var running: bool = false

@onready var inventory_interface = $UI/inventory_interface

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready():
	if !is_multiplayer_authority(): 
		print(get_multiplayer_authority()," is not auth of", self.name) 
		return
	camera.current = true
	speed = _playerdata.base_speed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		## sets the mentioned inventory data
	inventory_interface.set_player_inventory_data(inventory)
	inventory_interface.set_helmet_inventory_data(equip_helmet_data)
	inventory_interface.set_weapon_inventory_data(equip_weapon_data)
	inventory_interface.set_body_inventory_data(equip_body_data)
	
	
	## connects the force close to the toggle details function
	inventory_interface.force_close.connect(toggle_player_details)
	
	
	## connects the toggle inventory and hotbar data/visibilty
	
	##connects the quest_ui_toggle
	
	
	
	
	## connexts external inventory elements to the interface
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.connect("toggle_inventory", toggle_player_details)


func toggle_player_details(external_inventory_owner = null):
	if !is_multiplayer_authority(): return
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		UI_active = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else :
		UI_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory_owner(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory_owner()

func damage(damage: float, source: Object):
	if !is_multiplayer_authority(): return
	var real_damage = damage - defence
	if real_damage >0:
		@warning_ignore("narrowing_conversion")
		_playerdata.health -= real_damage
	else:
		_playerdata.health -= 1
	death_state_checker(source)

func death_state_checker(damage_source: Object):
	if !is_multiplayer_authority(): return
	if _playerdata.health <= 0:
		if "shot_by" in damage_source:
			var shot_by = damage_source.shot_by
			if "camera" in shot_by:
				shot_by.camera.current = true
		queue_free()

func heal(heal_amount: int):
	if !is_multiplayer_authority(): return
	_playerdata.health += heal_amount


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
	air_speed = _playerdata.air_speed
	inventory.slot_datas = _playerdata.inventory_data.slot_datas
	camera_2.global_transform = camera.global_transform


	if Input.is_action_just_pressed("crouch"):
		if !is_multiplayer_authority(): return
		temp_scale = 0.5
		speed = _playerdata.crouch_speed
		self.global_transform.origin.y -= 0.5
	if Input.is_action_just_pressed("dash"):
		if !is_multiplayer_authority(): return
		add_velocity(-camera.global_transform.basis.z*10)
	if Input.is_action_just_released("crouch"):
		if !is_multiplayer_authority(): return
		temp_scale = 1.0
		speed = _playerdata.base_speed
	if Input.is_action_just_pressed("inventory"):
		if !is_multiplayer_authority(): return
		toggle_player_details()
	
	for child in gun_container.get_children():
		if !UI_active:
			if Input.is_action_pressed("shoot"):
				if !is_multiplayer_authority(): return
				if "gun_data" in child:
					child.shoot(delta)
	
	if Input.is_action_just_pressed("refresh_weapon"):
		if !is_multiplayer_authority(): return
		refresh_weapon()
	


	update_helmet_stats()
	update_body_stats()
	update_weapon_equip()

	if Input.is_action_pressed("sprint"):
		if !is_multiplayer_authority(): return
		speed = _playerdata.run_speed
		var fov = lerp(camera.fov, base_fov + 20, delta+ 0.1)
		camera.fov = fov
		running = true
		
	elif Input.is_action_just_released("sprint"):
		if !is_multiplayer_authority(): return
		speed = _playerdata.base_speed
		running = false
	elif camera.fov != base_fov:
		var fov = lerp(camera.fov, base_fov, delta + 0.05)
		camera.fov = fov
		
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	Move(delta)
	_playerdata.rotation = rotation
	_playerdata.camera_rotation = pivot.rotation
	_playerdata.inventory_data.slot_datas = inventory.slot_datas

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
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = _playerdata.jump
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

func get_drop_direction() -> Vector3:
	var direction = -camera.global_transform.basis.z
	return camera.global_position + direction* 2


func add_velocity(a_velocity: Vector3):
	if !is_multiplayer_authority(): return
	velocity = velocity+a_velocity

func _on_timer_timeout():
	if !is_multiplayer_authority(): return
	inventory.force_update()
	equip_helmet_data.force_update()
	old_helmet_inventory.force_update()
	equip_body_data.force_update()
	old_body_inventory.force_update()
	equip_weapon_data.force_update()
	old_weapon_inventory.force_update()

func update_helmet_stats():
	equip_helmet_data.slot_datas = _playerdata.equip_helmet_data.slot_datas
	for index in range(_playerdata.equip_helmet_data.slot_datas.size()):
		if not _playerdata.equip_helmet_data.slot_datas[index] == null:
			var added = _playerdata.equip_helmet_data.slot_datas[index].item_data.get("added")
			if not added:
				_playerdata.equip_helmet_data.slot_datas[index].item_data.added = true
				var item_defence = _playerdata.equip_helmet_data.slot_datas[index].item_data.defence
				defence += item_defence
				for i in old_helmet_inventory.slot_datas.size():
					old_helmet_inventory.slot_datas[i] = _playerdata.equip_helmet_data.slot_datas[i]

	for index in range(old_helmet_inventory.slot_datas.size()):
		if not old_helmet_inventory.slot_datas[index] == null:
			if equip_helmet_data.slot_datas[index] == null:
				var item_defence = old_helmet_inventory.slot_datas[index].item_data.defence
				old_helmet_inventory.slot_datas[index].item_data.added = false
				defence -= item_defence
				for i in _playerdata.equip_helmet_data.slot_datas.size():
					old_helmet_inventory.slot_datas[i] = _playerdata.equip_helmet_data.slot_datas[i]
	_playerdata.equip_helmet_data.slot_datas = equip_helmet_data.slot_datas

func update_weapon_equip():
	equip_weapon_data.slot_datas = _playerdata.equip_weapon_data.slot_datas
	for index in range(_playerdata.equip_weapon_data.slot_datas.size()):
		if not _playerdata.equip_weapon_data.slot_datas[index] == null:
			var added = _playerdata.equip_weapon_data.slot_datas[index].item_data.get("added")
			if not added:
				_playerdata.equip_weapon_data.slot_datas[index].item_data.added = true
				for i in old_weapon_inventory.slot_datas.size():
					weapon_equip(_playerdata.equip_weapon_data.slot_datas[index].item_data)
					old_weapon_inventory.slot_datas[i] = _playerdata.equip_weapon_data.slot_datas[i]
			else:
				for i in old_weapon_inventory.slot_datas.size():
					current_weapon_data = old_weapon_inventory.slot_datas[i].item_data
					old_weapon_inventory.slot_datas[i] = _playerdata.equip_weapon_data.slot_datas[i]

	for index in range(old_weapon_inventory.slot_datas.size()):
		if not old_weapon_inventory.slot_datas[index] == null:
			if equip_weapon_data.slot_datas[index] == null:
				old_weapon_inventory.slot_datas[index].item_data.added = false
				for i in _playerdata.equip_weapon_data.slot_datas.size():
					weapon_unequip(old_weapon_inventory.slot_datas[index].item_data)
					old_weapon_inventory.slot_datas[i] = _playerdata.equip_weapon_data.slot_datas[i]
	update_weapon_stats()
	_playerdata.equip_weapon_data.slot_datas = equip_weapon_data.slot_datas

func update_weapon_stats():
	for child in gun_container.get_children():
		if not _playerdata.current_weapon_data == null:
			if child.ammo_set == false:
				child.gun_data = _playerdata.current_weapon_data
		if not child == null:
			_playerdata.current_weapon_data = child.gun_data
			child.set_ammo()

func weapon_equip(weapon_data: Gun_Data):
	const GUN_SCENE = preload("res://inv/gun_object.tscn")
	var gun_object = GUN_SCENE.instantiate()
	gun_object.gun_data = weapon_data
	gun_object.held_by = self
	gun_container.add_child(gun_object)
	update_weapon_stats()

func refresh_weapon():
	var missing_ammo: int = 0
	var reload_amount: int = 0
	var gun: Object
	for child in gun_container.get_children():
		if "gun_data" in child:
			gun = child
			missing_ammo = gun.gun_data.mag_size - gun.current_ammo
	for slot in inventory.slot_datas.size():
		var slot_data = inventory.slot_datas[slot]
		if slot_data != null:
			if slot_data.item_data != null:
				var slot_item = slot_data.item_data
				if slot_item is Ammo_Item_Data:
					if gun != null:
						if slot_item.calliber == gun.gun_data.calliber:
							for amount in slot_data.quantity:
								if slot_data.quantity != 0 && reload_amount < missing_ammo:
									reload_amount +=1
									inventory.use_slot_data(slot)
							gun.reload(reload_amount)

func check_slot_datas():
	for slot in inventory.slot_datas.size():
		var slot_data = inventory.slot_datas[slot]
		if slot_data.quantity == 0:
			inventory.use_slot_data(slot)

func weapon_unequip(weapon_data: Gun_Data):
	for child in gun_container.get_children():
		if "gun_data" in child:
			if child.gun_data.name == weapon_data.name:
				child.queue_free()

func update_body_stats():
	equip_body_data.slot_datas = _playerdata.equip_body_data.slot_datas
	for index in range(_playerdata.equip_body_data.slot_datas.size()):
		if not _playerdata.equip_body_data.slot_datas[index] == null:
			var added = _playerdata.equip_body_data.slot_datas[index].item_data.get("added")
			if not added:
				_playerdata.equip_body_data.slot_datas[index].item_data.added = true
				var item_defence = _playerdata.equip_body_data.slot_datas[index].item_data.defence
				defence += item_defence
				for i in old_body_inventory.slot_datas.size():
					old_body_inventory.slot_datas[i] = _playerdata.equip_body_data.slot_datas[i]

	for index in range(old_body_inventory.slot_datas.size()):
		if not old_body_inventory.slot_datas[index] == null:
			if equip_body_data.slot_datas[index] == null:
				var item_defence = old_body_inventory.slot_datas[index].item_data.defence
				old_body_inventory.slot_datas[index].item_data.added = false
				defence -= item_defence
				for i in _playerdata.equip_body_data.slot_datas.size():
					old_body_inventory.slot_datas[i] = _playerdata.equip_body_data.slot_datas[i]
	_playerdata.equip_body_data.slot_datas = equip_body_data.slot_datas
