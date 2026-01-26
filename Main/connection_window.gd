extends Control
@onready var latency_label: Label = $VBoxContainer/LatencyLabel
@onready var peer_1: Label = $VBoxContainer/Peer1
@onready var peer_2: Label = $VBoxContainer/Peer2
@onready var timer: Timer = $Timer

var connected: bool = false;
var latency_time: float = 0;
var my_packet: ENetPacketPeer;
var thread: Thread;
var latency_dict: Dictionary = {};
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide();
	Lobby.connection_started.connect(on_connection);
	Lobby.connection_ended.connect(on_connection_end);
	timer.timeout.connect(on_timeout);
	pass # Replace with function body.

func on_connection() ->void:
	var enet_peer: ENetMultiplayerPeer = multiplayer.multiplayer_peer;
	timer.start();
	connected = true;
	pass;

func on_connection_end() -> void:
	pass;

func on_timeout() -> void:

	var time: float = Time.get_ticks_usec();

	for key: String in Lobby.lobby_player_dictionary.keys():
		if (int(key) == multiplayer.get_unique_id()):
			continue;
		ping_connection.rpc_id(int(key),time);

@rpc("any_peer", "call_remote", "unreliable", 99)
func ping_connection(start_time: float) -> void:
	var peer_id: int = multiplayer.get_remote_sender_id();
	pong_connection.rpc_id(peer_id, start_time);
	pass;

@rpc("any_peer", "call_remote", "unreliable", 99)
func pong_connection(start_time: float) -> void:
	latency_time = (Time.get_ticks_usec() - start_time) / 1000;
	latency_dict[multiplayer.get_remote_sender_id()] = latency_time;
	print("ponged ", latency_time)
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	if(Input.is_action_just_pressed("toggle_data")):
		if !visible:
			show();
		else:
			hide();
	if(!visible):
		return;
	if(!connected):
		return;
	latency_label.text = "Latency : %s ms" % [int(latency_time)];
	pass
