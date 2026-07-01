extends Node3D
class_name Level


const pickup = preload("res://inv/test_item_pickup.tscn")
var peer = ENetMultiplayerPeer.new()
@export var PS: PackedScene

@export var scene_name: String

@export var test_array: Array

@onready var children = self.get_children(true)
@onready var name_array: PackedStringArray

@onready var player = find_child("player")

func on_inventory_interface_drop_slot_data(slot_data, all: bool):
	var _pick_up = pickup.instantiate()
	_pick_up.slot_data = slot_data.duplicate()
	if all == false:
		_pick_up.slot_data.quantity = 1
	else:
		pass
	_pick_up.position = player.get_drop_direction()
	self.add_child(_pick_up)
