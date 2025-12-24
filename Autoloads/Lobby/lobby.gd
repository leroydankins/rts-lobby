extends Node
##############
### This lobby does not act on its own, you will need to create an interface/ui that will call the join_game
### and create_game functions with the required arguments (Username, IP address for joining, lobby name for hosting)
### Lobby GUI will collect this information and contain buttons for joining or creating lobby.
### Works in tandem with another local autoload called LocalPlayerData, this data gets sent out to the server on connecting
### and will request the lobby update this information for all clients
##############



#UPNP Signal, emitted when port mapping is complete, success or failure
signal upnp_completed(error: Error);

#upnp thread
var upnp_thread: Thread = null;

#signals for when data is updated
signal data_updated;

#signals to connect to a UI lobby scene or game scene
signal player_connected(peer_id: int, player_info: Dictionary);
signal player_disconnected(peer_id: int);
signal connection_ended;
signal connection_started;

###PICK YOUR OWN PORT
const PORT: int = 7000;
const DEFAULT_SERVER_IP: String = "127.0.0.1";
const ETHANS_EXTERNAL_IP: String = "98.204.21.100"
const MAX_CONNECTIONS: int = 4; #CURRENT MAX CONNECTIONS

var is_connected: bool = false;
var connect_port: int = PORT;
var is_local: bool = false;

var lobby_name: String:
	get:
		return lobby_name;
	set(name):
		lobby_name = name;
		data_updated.emit();

var lobby_player_dictionary: Dictionary[String, Dictionary]:
	get:
		return lobby_player_dictionary;
	set(dict):
		lobby_player_dictionary = dict;
		data_updated.emit();

var players_loaded: int = 0:
	get:
		return players_loaded;
	set(value):
		players_loaded = value;
		data_updated.emit();

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




#join game function, requires address in current implementation
func join_game(address: String = "") -> Error:
	#player data is initialzed before this method is called

	#if we do not have an IP address input
	if address.is_empty():
		if (is_local):
			address = DEFAULT_SERVER_IP;
		push_error("we didnt get an address, will not continue");
		return Error.FAILED;
	#create a multiplayer peer implementation
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
	#try to create a client at the port
	var error: Error = peer.create_client(address, PORT);
	#on connect okay, the player will send their local player information to the server and get updated

	print(error);
	#if the error exists and is not ok, return the error
	if error != OK:
		push_error("Error on creating a client, error code: %s" % error);
		return error;

	#set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;
	var id: String = str(multiplayer.get_unique_id());
	print(id);

	#TELL THE SERVER YOU CREATED A CLIENT (does not confirm that connection was successful)
	return error;

#create game function
func create_game(lob_name: String) -> Error:
	#player data is initialzed before this method is called
	#create a multiplayer peer and set this instance to be this peer
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
	var error: Error = peer.create_server(PORT, MAX_CONNECTIONS);

	#if the error exists and is not ok, return the error
	if error != OK:
		push_error("Error on creating a client, error code: %s" % error);
		return error;
	is_connected = true;
	connection_started.emit();
	lobby_name = lob_name;
	#set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;

	var peer_id: String = str(multiplayer.get_unique_id());

	##TODO
	##add the player information to the server data holder here
	local_register_player.rpc_id(1,peer_id,LocalPlayerData.local_player);

	#STAY IN THE LOBBY
	return Error.OK;

#call this to end session
func remove_multiplayer_peer() -> Error:
	#re initialzize an offline peer to make things still function
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	print("disconnected");
	is_connected = false;
	lobby_name = "";
	lobby_player_dictionary.clear();
	connection_ended.emit();

	var err: Error;
	if (multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED):
		err = Error.OK;
	else:
		err = Error.FAILED;
	return err;
	#get rid of player references



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

#originally called on start and join, but now will only call this when the game is ready to start!! RTS Lobby system
func start_game() -> void:
	#hide the lobby UI, ask the server to change the level
	if multiplayer.is_server():
		change_level.call_deferred(load("res://game.tscn"));

#when the server starts a game from a UI scene, do Lobby.load_game.rpc(filepath)
@rpc("authority","call_local","reliable")
func load_game(game_scene_path: String) -> void:
	pass;

# Call this function deferred and only on the main authority (server).
func change_level(_scene: PackedScene) -> void:
	# Remove old level if any.
	##TODO SINCE SETUP ISNT SETUP YET
	##if game_node has a child, remove it
	## Add new level (original isnt an RPC and is instead add child with multiplayer spawner)
	pass;





#the connecting player will call this when they connect
@rpc("any_peer","call_local", "reliable")
func local_register_player(sender_id: String, new_player_info: Dictionary[String, Variant]) -> void:
	if (!multiplayer.is_server()):
		return;
	#only register the player on the server, you will then send this information out on update_player_list function
	if (lobby_player_dictionary.has(sender_id)):
		push_error("Recieved register player request on a player that already exists, overwriting previous entry");
	#add player information to dictionary of dictionaries
	lobby_player_dictionary[sender_id] = new_player_info;
	#send information to all others connected
	server_update_player_list.rpc(lobby_player_dictionary);
	server_update_lobby_name.rpc(lobby_name);


#send updated player dictionary when we make changes locally
@rpc("any_peer","call_local", "reliable")
func local_update_peer_information(sender_id: String, updated_dictionary: Dictionary[String, Variant]) -> void:
	if (!multiplayer.is_server()):
		return;
		#only update the player on the server, you will then send this information out on update_player_list function
	if (!lobby_player_dictionary.has(sender_id)):
		push_error("Recieved update player data request on a player that does not exist, creating new entry");
	#add player information to dictionary of dictionaries
	lobby_player_dictionary[sender_id] = updated_dictionary;
	#send information to all others connected
	server_update_player_list.rpc(lobby_player_dictionary);
	pass;

#The multiplayer server will call this on all players to update the information of the dictionary
@rpc("authority","call_local","reliable")
func server_update_player_list(lobby_dict: Dictionary)-> void:
	#Multiplayer server ID is 1
	if(multiplayer.get_remote_sender_id() != multiplayer_server_id):
		return;
	#update our lobby's reference to palyers to be the same as the
	lobby_player_dictionary = lobby_dict;

#the multiplayer server will call this on all players to update the information of the lobby name
@rpc("authority","call_local","reliable")
func server_update_lobby_name(lob_name: String)-> void:
	#Multiplayer server ID is 1
	if(multiplayer.get_remote_sender_id() != multiplayer_server_id):
		return;
	#update our lobby's reference to palyers to be the same as the
	lobby_name = lob_name;


#when you connect, send your information to the server and then wait for it to add you to lobby scene
func on_connected_ok() -> void: #Set player information if you are the authority
	print("connected to server");
	is_connected = true;
	connection_started.emit();
	#when we connect  to the server, add our own player information to the local StateData autoload
	print("calling rpc to add player data to the server data");
	var peer_id: String = str(multiplayer.get_unique_id());
	#call rpc_id to server only (1)
	local_register_player.rpc_id(1,peer_id, LocalPlayerData.local_player);


func on_connected_fail() -> void:
	is_connected = false;
	connection_ended.emit();
	var err: Error = remove_multiplayer_peer();


##TODO update
func on_peer_connected(id: int) -> void:
	print(str("player connected, id is ", id, " my id is ", multiplayer.get_unique_id()));
	#When a peer connects, add them to the lobby scene UI and send any sort of information you need to send to update them
	if(multiplayer.is_server()):
		print("the multiplayer server has recieved a peer that has connected")
		pass;

func on_peer_disconnected(peer_id: int)->void:
	if (!multiplayer.is_server()):
		return;
	var id: String = str(peer_id);
	if (lobby_player_dictionary.has(id)):
		lobby_player_dictionary.erase(id);
		server_update_player_list.rpc(lobby_player_dictionary)
	player_disconnected.emit();

func on_server_disconnected() -> void:
	print("disconnected");
	is_connected = false;
	lobby_name = "";
	lobby_player_dictionary.clear();
	connection_ended.emit();


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

func _exit_tree() -> void:
	if (upnp_thread):
		upnp_thread.wait_to_finish();
