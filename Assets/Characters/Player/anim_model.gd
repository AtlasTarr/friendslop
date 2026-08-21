extends Node3D


const ANIM_MODEL = preload("uid://0xbcimc5g4lh")
var added
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#update_colour()
	pass

func update_colour(colour: Color):
	var temp_mat := StandardMaterial3D.new()
	temp_mat.albedo_color = colour
	$Skeleton3D/Beta_Surface.set_surface_override_material(0, temp_mat)
