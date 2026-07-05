extends Control

var lobby_id: int = 819273891938
var peer = ENetMultiplayerPeer.new()
const port = 8890
@export var PS: PackedScene

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit

func _on_button_pressed() -> void:
	self.hide()
	await Noray.connect_to_host("html-pk.with.playit.plus", 1025)
	Noray.register_host()
	Noray.register_remote(1041)
	peer.create_server(8890)
	multiplayer.multiplayer_peer = peer
	add_player(multiplayer.get_unique_id())
	Noray.on_connect_nat.connect(add_player)

func add_player(peer_id):
	var player = PS.instantiate()
	player.name = str(peer_id)
	get_tree().root.get_node("/root/lobby").add_child(player)
	print("player add")


func _on_button_2_pressed() -> void:
	self.hide()
	Noray.connect_nat($VBoxContainer/LineEdit.text)
	Noray.register_remote()
	Noray.register_host()
	
	peer.create_client($VBoxContainer/LineEdit.text, Noray.local_port)
	multiplayer.multiplayer_peer = peer
