extends Control

var lobby_id: int = 819273891938
var peer = ENetMultiplayerPeer.new()
const port = 8891
@export var PS: PackedScene

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit

func _on_button_pressed() -> void:
	self.hide()
	Noray.connect_to_host($VBoxContainer/LineEdit2.text, port)
	Noray.register_host()
	Noray.register_remote()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	add_player(multiplayer.get_unique_id())
	Noray.on_connect_nat.connect(add_player)
	print("ID:",Noray.oid)

func add_player(peer_id):
	var player = PS.instantiate()
	player.name = str(peer_id)
	get_tree().root.get_node("/root/lobby").add_child(player)


func _on_button_2_pressed() -> void:
	self.hide()
	Noray.connect_nat($VBoxContainer/LineEdit.text)
	peer.create_client($VBoxContainer/LineEdit.text,9999)
	multiplayer.multiplayer_peer = peer
