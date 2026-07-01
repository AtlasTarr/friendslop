extends Control

var lobby_id: int = 819273891938
var peer = SteamMultiplayerPeer
@export var PS: PackedScene
var host:bool = false
var is_joining: bool = false

var port:int = 9999

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit


func _ready() -> void:
	print("server init:", Steam.steamInit(480,true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_join)

func _on_button_pressed() -> void:
	self.hide()
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 20)
	host = true

func on_lobby_created(result: int, lobby:int ):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		add_player()
		print("lobby: ", lobby_id)

func add_player(id: int = 1):
	var player = PS.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)

func remove_player(id: int):
	if not get_tree().has_node(str(id)):
		return
	get_tree().get_node(str(id)).queue_free()



func on_lobby_join(join_id: int, perm: int, locked: bool, response: int):
	if !is_joining:
		return
	
	self.lobby_id = join_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(join_id))
	multiplayer.multiplayer_peer = peer
	is_joining = false

func join_lobby(lobby: int):
	is_joining = true
	Steam.joinLobby(lobby)


func _on_button_2_pressed() -> void:
	join_lobby(line_edit.text.to_int())
