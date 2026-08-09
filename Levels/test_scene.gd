extends Node3D
class_name Level


var peer = ENetMultiplayerPeer.new()
@export var PS: PackedScene

@export var scene_name: String

@export var test_array: Array

@onready var children = self.get_children(true)
@onready var name_array: PackedStringArray
