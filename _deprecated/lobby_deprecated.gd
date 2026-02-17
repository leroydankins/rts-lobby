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
const ETHANS_EXTERNAL_IP: String = "98.204.21.100"
const MAX_CONNECTIONS: int = 4; #CURRENT MAX CONNECTIONS


var connect_port: int = PORT;
var is_local: bool = false;

var lobby_player_dictionary: Dictionary[String, Dictionary];
var players_loaded: int = 0;
var multiplayer_server_id: int = 1;



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Replace with function body.
	multiplayer.peer_connected.connect(on_peer_connected);
	multiplayer.peer_disconnected.connect(on_peer_disconnected);
	multiplayer.connected_to_server.connect(on_connected_ok);
	multiplayer.connection_failed.connect(on_connected_fail);
	multiplayer.server_disconnected.connect(on_server_disconnected);

	##TODO
	##ESTABLISH HOW YOU TELL LOBBY WE ARE GOOD TO GO
	#_connect_butt.pressed.connect(on_connect_button);
	#_host_butt.pressed.connect(on_host_button);
	return;

func upnp_setup(server_port: int) -> void:
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
func join_game(address: String = "", port_input : String = "") -> Variant:
	#player data is initialzed before this method is called

	#if we do not have a port input
	if port_input.is_empty():
		push_error("we didnt get an input port, using basic 7000");
		connect_port = PORT;
	else:
		connect_port = port_input.to_int();

	#if we do not have an IP address input
	if address.is_empty():
		if (is_local):
			address = DEFAULT_SERVER_IP;
		push_error("we didnt get an address, will not continue");
		return;
	#create a multiplayer peer implementation
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
	#try to create a client at the port
	var error: Error = peer.create_client(address, PORT);

	#if the error exists and is not ok, return the error
	if error != OK:
		push_error("Error on creating a client, error code: %s" % error);
		return error;

	#set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;

	var id: String = str(multiplayer.get_unique_id());
	print(id);

	#TELL THE SERVER YOU ARE IN
	return;

#create game function
func create_game() -> Variant:
	#player data is initialzed before this method is called
	#create a multiplayer peer and set this instance to be this peer
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
	var error: Error = peer.create_server(PORT, MAX_CONNECTIONS);

	#if the error exists and is not ok, return the error
	if error != OK:
		push_error("Error on creating a client, error code: %s" % error);
		return error;

	#set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;

	var id: String = str(multiplayer.get_unique_id());

	##TODO
	##add the player information to the server data holder here

	#STAY IN THE LOBBY
	return;


##TODO
func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new();
	#get rid of player references

#when the server starts a game from a UI scene, do Lobby.load_game.rpc(filepath)
#this will be changed to handle the game I am making!!!
@rpc("call_local", "reliable")
func load_game(_game_scene_path: String) -> void:
	#change the scene
	pass;

#originally called on start and join, but now will only call this when the game is ready to start!! RTS Lobby system
func start_game() -> void:
	#hide the lobby UI, ask the server to change the level
	if multiplayer.is_server():
		change_level.call_deferred(load("res://game.tscn"));

# Call this function deferred and only on the main authority (server).
func change_level(_scene: PackedScene) -> void:
	# Remove old level if any.
	##TODO SINCE SETUP ISNT SETUP YET
	##if game_node has a child, remove it
	## Add new level (original isnt an RPC and is instead add child with multiplayer spawner)
	pass;

##DEPRECATED
#This button will be outside of lobby autoload and in the lobby system, it will just request to connect to lobby
func on_connect_button() -> void:
	#player data will come from singleton autoload that has internal players information
	#get player data from LocalPlayerData
	#LocalPlayerData.local_dictionary["username"] = "Placeholder Username";
	#request to join game
	#join_game(_connect_address.text);
	pass;

##DEPRECATED
#This button will be outside of lobby autoload and in the lobby system, it will just request to connect to lobby
func on_host_button() -> void:
	#get player data from LocalPlayerData
	#request to create game
	#create_game();
	pass;

#when player connects, send them my player info
#this allowstransfer of all desired data for eacfh player

##TODO
func on_peer_connected(id: int) -> void:
	print(str("player connected, id is ", id, " my id is ", multiplayer.get_unique_id()));
	#When a peer connects, add them to the lobby scene UI and send any sort of information you need to send to update them
	if(multiplayer.is_server()):
		print("the multiplayer server has recieved a peer that has connected")
		pass;
	#register_player.rpc_id(id, player_info);


#the connecting player will call this when they connect
@rpc("any_peer", "reliable")
func register_player(new_player_info: Dictionary[String, Variant]) -> void:
	if (!multiplayer.is_server()):
		return;
	#only register the player on the server, you will then send this information out on update_player_list function
	var new_player_id: String = str(multiplayer.get_remote_sender_id());
	lobby_player_dictionary[new_player_id] = new_player_info;
	update_player_list.rpc(lobby_player_dictionary);
	#add player information to dictionary of dictionaries

@rpc("authority","call_local","reliable")
func update_player_list(lobby_dict: Dictionary)-> void:
	#Multiplayer server ID is 1
	if(multiplayer.get_remote_sender_id() != multiplayer_server_id):
		return;
	#update our lobby's reference to palyers to be the same as the
	lobby_player_dictionary = lobby_dict;


func on_peer_disconnected(_id: int)->void:
	player_disconnected.emit();

##TODO
#when you connect, send your information to the server and then wait for it to add you to lobby scene
func on_connected_ok() -> void: #Set player information if you are the authority
	print("connected to server");
	#when we connect, send our information to the host to add to their server data and then send it out
	#RPC LOBBY ADD DATA TO DICTIONARY
	#when we connect  to the server, add our own player information to the local StateData autoload
	print("calling rpc to add player data to the server data");
	register_player.rpc(LocalPlayerData.local_player);
	#var peer_id = multiplayer.get_unique_id();
	#player_connected.emit(peer_id, player_info);

func on_connected_fail()-> void:
	remove_multiplayer_peer();

func on_server_disconnected() -> void:
	remove_multiplayer_peer();
	server_disconnected.emit();

func _exit_tree() -> void:
	if (upnp_thread):
		upnp_thread.wait_to_finish();
