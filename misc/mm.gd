extends Control

var peer = ENetMultiplayerPeer.new()
const port = 8890
@export var PS: PackedScene
const LOBBY = preload("res://Levels/lobby.tscn")

const FRIENDSLOP = preload("res://friendslop.tres")
var tube_client := TubeClient.new()
var tube_enabled: = false

@onready var session_id: LineEdit = %SessionID
@onready var username: LineEdit = %Username
@onready var join: Button = %Join
@onready var host: Button = %Host
@onready var red: HScrollBar= %red
@onready var green: HScrollBar= %green
@onready var blue: HScrollBar= %blue
var colour: Color


func _ready() -> void:
	if tube_enabled:
		tube_client.context = FRIENDSLOP
		tube_client.peer_signaling_max_attempts = 20
		get_tree().root.call_deferred("add_child", tube_client)
	
	session_id.text_changed.connect(session_updated)
	username.text_changed.connect(username_updated)
	join.disabled = true
	join.pressed.connect(join_tube)
	host.pressed.connect(on_create_tube)
	red.value_changed.connect(Update_rgb)
	green.value_changed.connect(Update_rgb)
	blue.value_changed.connect(Update_rgb)

func session_updated(new_text: String):
	if new_text != "":
		join.disabled = false
		

func username_updated(new_text: String):
	print("test1")
	Global.Username = new_text

func join_tube():
	Network.tube_join(session_id.text, colour)
	multiplayer.connected_to_server.connect(add_world)
	self.hide()

func on_create_tube():
	Network.tube_create( Color(red.value / 255,green.value / 255,blue.value / 255))
	add_world()
	self.hide()

func tube_create():
	multiplayer.peer_connected.connect(add_player)
	tube_client.create_session()
	add_player(1)
	print(tube_client.session_id)

func tube_join(sessionID: String, Colour: Color):
	multiplayer.peer_connected.connect(add_player.bind(colour))
	tube_client.join_session(sessionID)

func add_world():
	var new_world = LOBBY.instantiate()
	get_tree().current_scene.add_child(new_world, true)


func add_player(id:int):
	var player = PS.instantiate()
	player.name = str(id)
	var level = get_tree().root.get_node("/root/lobby")
	level.add_child(player,true)
	print("player add")
	print(tube_client.session_id)
	print(tube_client._peers)

func Update_rgb(_arg: float):
	print("test")
	colour = Color(red.value / 255,green.value / 255,blue.value / 255)
	$Panel/VBoxContainer/VBoxContainer/ColorRect.color =colour
	Global.colour = colour
