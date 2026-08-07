extends Control

var peer = ENetMultiplayerPeer.new()
const port = 8890
@export var PS: PackedScene

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit
var tube_client:TubeClient 

func _ready() -> void:
	if tree_entered:
		tube_client = get_tree().root.get_node("/root/lobby/MP_manager")

func _on_button_pressed() -> void:
	tube_client.create_session()
	$VBoxContainer.visible = false
	add_player(tube_client.peer_id)

func add_player(peer_id):
	var player = PS.instantiate()
	player.name = str(peer_id)
	var level = get_tree().root.get_node("/root/lobby")
	level.add_child(player,true)
	print("player add")
	print(tube_client.session_id)
	print(peer_id)


func _on_button_2_pressed() -> void:
	self.hide()
	tube_client.join_session($VBoxContainer/LineEdit.text)
	await tube_client.session_joined
	tube_client.peer_id = tube_client._peers.size() +1
	add_player(tube_client.peer_id)
