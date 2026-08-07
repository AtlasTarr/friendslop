extends Control

var peer = ENetMultiplayerPeer.new()
const port = 8890
@export var PS: PackedScene
const LOBBY = preload("uid://cu4gt8ywt2n3q")

const FRIENDSLOP = preload("uid://f81okmp0sxuu")
var tube_client := TubeClient.new()
var tube_enabled: = false

@onready var session_id: LineEdit = %SessionID
@onready var username: LineEdit = %Username
@onready var join: Button = %Join
@onready var host: Button = %Host


func _ready() -> void:
	if tube_enabled:
		tube_client.context = FRIENDSLOP
		tube_client.peer_signaling_max_attempts = 20
		tube_client.peer_signaling_timeout = 30
		get_tree().root.call_deferred("add_child", tube_client)
	
	session_id.text_changed.connect(session_updated)
	username.text_changed.connect(username_updated)
	join.disabled = true
	join.pressed.connect(join_tube)
	host.pressed.connect(on_create_tube)
	if OS.has_feature("server"):
		Network.start_server()
		await get_tree().create_timer(0.1).timeout
		add_world()

func session_updated(new_text: String):
	if new_text != "":
		join.disabled = false
		

func username_updated(new_text: String):
	Global.Username = new_text

func join_tube():
	Network.tube_join(session_id.text)
	multiplayer.connected_to_server.connect(add_world)
	self.hide()

func on_create_tube():
	Network.tube_create()
	add_world()
	self.hide()

func tube_create():
	multiplayer.peer_connected.connect(add_player)
	tube_client.create_session()
	add_player(1)
	print(tube_client.session_id)

func tube_join(sessionID: String):
	multiplayer.peer_connected.connect(add_player)
	tube_client.join_session(sessionID)

func add_world():
	var new_world = LOBBY.instantiate()
	get_tree().current_scene.add_child(new_world)


func add_player(id:int):
	var player = PS.instantiate()
	player.name = str(id)
	var level = get_tree().root.get_node("/root/lobby")
	level.add_child(player,true)
	print("player add")
	print(tube_client.session_id)
	print(tube_client._peers)
