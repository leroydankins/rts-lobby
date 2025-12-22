class_name lobby
extends Node

#UPNP Signal, emitted when port mapping is complete, success or failure
signal upnp_completed(error: Error);
#upnp thread
var upnp_thread: Thread = null;

#signals to connect to a UI lobby scene or game scene
signal player_connected(peer_id: int, player_info: Dictionary);
signal player_disconnected(peer_id: int);
signal server_disconnected;



const PORT: int = 7000;
const DEFAULT_SERVER_IP: String = "127.0.0.1";
const MAX_CONNECTIONS: int = 20;

#control nodes
@export var _connect_butt: Button;
@export var _host_butt: Button;
@export var _username: TextEdit;
@export var _connect_address: TextEdit;
@onready var class_drop_down: OptionButton = $"CanvasLayer/LobbyUI/Customize Character/HBoxContainer3/ClassDropDown"
@export var _lobby_ui: Control;
@export var _game_node: Node;

var connect_port: int = PORT;
@onready var port_input: TextEdit = $CanvasLayer/LobbyUI/Connect/PORT/PortInput



#local player information, modified locally before the connection is made. It will be passed to every peer
var player_info: Dictionary[String, Variant];
var players_loaded = 0;



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Replace with function body.
	multiplayer.peer_connected.connect(on_peer_connected);
	multiplayer.peer_disconnected.connect(on_peer_disconnected);
	multiplayer.connected_to_server.connect(on_connected_ok);
	multiplayer.connection_failed.connect(on_connected_fail);
	multiplayer.server_disconnected.connect(on_server_disconnected);
	
	_connect_butt.pressed.connect(on_connect_button);
	_host_butt.pressed.connect(on_host_button);
	return;

func upnp_setup(server_port) -> void:
	#upnp queries take time
	var upnp: UPNP = UPNP.new();
	var disc_err: Error = upnp.discover() as Error;
	if disc_err != OK:
		push_error(str(disc_err));
		printerr("issue at discovery");
		upnp_completed.emit(disc_err);
	var mapping_err: Error = upnp.add_port_mapping(server_port) as Error;
	if (mapping_err != OK):
		push_error(str(mapping_err));
		printerr("issue at mapping");


#join game function, requires address in current implementation
func join_game(address = ""):
	#player data is initialzed before this method is called
	
	#ADD STATE DATA TO LOCAL PLAYER INFO
	StateData.local_player = player_info;
	
	#if we do not have a port input
	if port_input.text.is_empty():
		connect_port = PORT;
	else:
		connect_port = port_input.text.to_int();
	#if we do not have an IP address input
	if address.is_empty():
		printerr("NO PORT TO HAVE WOOPSIES");
		return;
	#create a multiplayer peer implementation
	var peer = ENetMultiplayerPeer.new();
	#try to create a client at the port
	var error = peer.create_client(address, PORT);
	#if the error exists and is not ok, return the error
	if error != OK:
		push_error(str(error, "im dumb"));
		return error;
	
	#set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;

	var id = str(multiplayer.get_unique_id());
	print(id);

	start_game();

#create game function
func create_game():
	#player data is initialzed before this method is called
	
	#ADD STATE DATA TO LOCAL PLAYER INFO
	StateData.local_player = player_info;
	
	
	#create a multiplayer peer and set this instance to be this peer
	var peer = ENetMultiplayerPeer.new();
	var error = peer.create_server(PORT, MAX_CONNECTIONS);
	if error:
		return error;
	multiplayer.multiplayer_peer = peer;
	#Add player information to global information since we are hosting
	var id = str(multiplayer.get_unique_id());
	StateData.add_player(id, StateData.local_player);

	#emit the signal that says a player connected, for game reaction reasons
	#player_connected.emit(1, player_info);
	
	start_game();

#REWORK
func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new();
	StateData.players_dictionary.clear();

#when the server starts a game from a UI scene, do Lobby.load_game.rpc(filepath)
#this will be changed to handle the game I am making!!!
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	#change the scene
	pass;


func start_game():
	_lobby_ui.hide();
	if multiplayer.is_server():
		change_level.call_deferred(load("res://game.tscn"));

# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	for c in _game_node.get_children():
		_game_node.remove_child(c)
		c.queue_free()
	# Add new level.
	_game_node.add_child(scene.instantiate())

func on_connect_button() -> void:
	player_info["username"] = _username.text;
	player_info["color"] = Color.RED;
	player_info["class"] = class_drop_down.selected;
	join_game(_connect_address.text);

func on_host_button() -> void:
	player_info["username"] = _username.text;
	player_info["color"] = Color.GREEN;
	player_info["class"] = class_drop_down.selected;
	create_game();

#when player connects, send them my player info
#this allowstransfer of all desired data for eacfh player

func on_peer_connected(id):
	print(str("player connected, id is ", id, " my id is ", multiplayer.get_unique_id()));
	if(multiplayer.is_server()):
		StateData.initialize_dictionary.rpc_id(id,StateData.players_dictionary);
	#register_player.rpc_id(id, player_info);


#call this when a player connects
@rpc("any_peer", "reliable")
func register_player(new_player_info: Dictionary[String, Variant]) -> void:
	var new_player_id: String = str(multiplayer.get_remote_sender_id());

func on_peer_disconnected(_id: int)->void:
	player_disconnected.emit();

func on_connected_ok(): #Set player information if you are the authority
	print("connected to server");
	#when we connect, send our information to the host to add to their server data and then send it out
	
	#when we connect  to the server, add our own player information to the local StateData autoload
	print("calling rpc to add player data to the server data");
	StateData.add_player.rpc_id(1, str(multiplayer.get_unique_id()),StateData.local_player);
	#var peer_id = multiplayer.get_unique_id();
	#player_connected.emit(peer_id, player_info);

func on_connected_fail():
	remove_multiplayer_peer();

func on_server_disconnected():
	remove_multiplayer_peer();
	server_disconnected.emit();

func _exit_tree() -> void:
	if (upnp_thread):
		upnp_thread.wait_to_finish();
