extends Node

## This lobby does not act on its own, you will need to create an interface/ui that will call the join_game
## and create_game functions with the required arguments (Username, IP address for joining, lobby name for hosting)
## Lobby GUI will collect this information and contain buttons for joining or creating lobby.
## Works in tandem with another local autoload called LocalPlayerData, this data gets sent out to the server on connecting
## and will request the lobby update this information for all clients
##RPC Calls to start the game will be handled here, but for modularity I will attempt to keep actual code for loading level in outside script
##Main will subscribe to set of signals from this lobby, which will handle the actual gameplay

## Local games will still interface with the lobby dictionary but just create individial peer IDs for AI


#UPNP Signal, emitted when port mapping is complete, success or failure
signal upnp_completed(error: Error);

#upnp thread
var upnp_thread: Thread = null;

#signals for Main scene to subscribe to
signal initialize_game(file_path: String);
signal start_game();
#signals for when data is updated
signal data_updated;

#signals to connect to a UI lobby scene or game scene
signal player_connected(peer_id: int, player_info: Dictionary);
signal player_disconnected(peer_id: int);
signal connection_ended;
signal connection_started;

## @experimental: PICK YOUR OWN PORT IN REAL SET UP
const PORT: int = 7000;
const DEFAULT_SERVER_IP: String = "127.0.0.1";
const ETHANS_EXTERNAL_IP: String = "98.204.21.100"
const MAX_CONNECTIONS: int = 4; #CURRENT MAX CONNECTIONS

var lobby_connected: bool = false;
var connect_port: int = PORT;
var is_local: bool = false;
var password: String = ""

var lobby_name: String:
	get:
		return lobby_name;
	set(name):
		lobby_name = name;

## Each player has a dictionary [br][br]
## Access each field via [GlobalConstants]
## The key is the multiplayer caller's peer_id as [String] [br][br]
##[code] username[/code] : String               [br][br]
##[code] team[/code]  : int                   [br][br]
##[code] color[/code] : int                   [br][br]
##[code] race[/code] : int               [br][br]
##[code] slot[/code] : int                 [br][br]
##[code] ready[/code] : bool                 [br][br]
##[code] is_cpu [/code] : bool             [br][br]
var lobby_player_dictionary: Dictionary[String, Dictionary]:
	get:
		return lobby_player_dictionary;
	set(dict):
		lobby_player_dictionary = dict;
		data_updated.emit();

var players_loaded: int = 0

var _null_var: int;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_null_var = multiplayer.peer_connected.connect(on_peer_connected);
	_null_var = multiplayer.peer_disconnected.connect(on_peer_disconnected);
	# This Multiplayer signal is connected to by Lobby and by Main
	_null_var = multiplayer.connected_to_server.connect(on_connected_ok);
	# This Multiplayer signal is Connected to by Lobby and by JoinGameLobby
	_null_var = multiplayer.connection_failed.connect(on_connected_fail);
	# This Multiplayer signal is Connected to Lobby and Main
	_null_var = multiplayer.server_disconnected.connect(on_server_disconnected);
# /ready

## Called whenever Create Game is pressed from Menu, handles local lobby until it is made public or online
func create_local_lobby() -> Error:
	## Offline multiplayer peer associated with the Lobby instance until we overwrite it with a live lobby
	var peer: OfflineMultiplayerPeer
	## String version of peer int represnting RPC address, not sure when I chose String but its kind of embedded now
	var peer_id: String
	## Dictionary reference to our LocalPlayerData singleton's player information
	var local_player : Dictionary[String,Variant]

	# player data is initialzed before this method is called
	# create a multiplayer peer and set this instance to be this peer
	peer = OfflineMultiplayerPeer.new();
	# set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;
	# Start fresh each time
	lobby_player_dictionary.clear();

	peer_id = str(multiplayer.get_unique_id());

	# add the player information to the server data holder here
	local_player  = LocalPlayerData.get_local_player();
	# Create a placeholder "player" name for the local player
	local_register_player.rpc_id(get_multiplayer_authority(),peer_id, local_player);

	# Currently update the name because we dont have a username attached
	LocalPlayerData.update_dictionary_data(GlobalConstants.USERNAME_KEY, "player");
	# STAY IN THE LOBBY
	return Error.OK;
# /create_local_lobby

## join game function, requires address in current implementation [br][br]
## Will need to implement a password string in the future that checks if the password is valid [br]
## Password setup will be done when we are using a list of available lobbies system when we connect to SteamWorks
func join_lobby(address: String = "") -> Error:
	##  ENET multiplayer peer associated with the Lobby instance until we overwrite it with a live lobby
	var peer: ENetMultiplayerPeer
	## Var holding error value when creating a client at the given port address
	var error: Error
	## String version of peer int represnting RPC address, not sure when I chose String but its kind of embedded now
	var peer_id: String

	#player data is initialzed before this method is called
	#if we do not have an IP address input
	if address.is_empty():
		if (is_local):
			address = DEFAULT_SERVER_IP;
		push_error("we didnt get an address, will not continue");
		return Error.FAILED;
	#create a multiplayer peer implementation
	peer = ENetMultiplayerPeer.new();
	#try to create a client at the port
	error = peer.create_client(address, PORT);
	#on connect okay, the player will send their local player information to the server and get updated

	#if the error exists and is not ok, return the error
	if error != OK:
		push_error("Error on creating a client, error code: %s" % error);
		return error;

	#set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;
	peer_id = str(multiplayer.get_unique_id());

	#TELL THE SERVER YOU CREATED A CLIENT (does not confirm that connection was successful)
	return error;

## Creates an online lobby for connecting to with peers [br][br]
## Uses the lobby name to establish what the lobby name is?
func create_lobby(lob_name: String, p_word: String) -> Error:
	# player data is initialzed before this method is called in LocalPlayerData
	# create a multiplayer peer and set this instance to be this peer

	## Empty API Call to our hosted server to create a unique ID and register password
	var unique_id: String = PlaceholderServer.get_unique_id()
	##  ENET multiplayer peer associated with the Lobby instance until we overwrite it with a live lobby
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();
	## Var holding error value when creating a client at the given port address
	var error: Error = peer.create_server(PORT, MAX_CONNECTIONS);
	## String version of peer int represnting RPC address, not sure when I chose String but its kind of embedded now
	var peer_id: String
	# if the error exists and is not ok, return the error
	if error != OK:
		push_error("Error on creating a client, error code: %s" % error);
		return error;

	# set this instance's multiplayer peer to this peer
	multiplayer.multiplayer_peer = peer;

	lobby_connected = true;
	connection_started.emit();

	lobby_name = lob_name;

	peer_id = str(multiplayer.get_unique_id());

	if(!lobby_player_dictionary):
		# add the player information to the server data holder here
		local_register_player.rpc_id(1,peer_id,LocalPlayerData.get_local_player());

	password = p_word;


	# STAY IN THE LOBBY
	return Error.OK;

##  This is called to end the lobby session in [Lobby] or [GameLobbyGUI]
func remove_multiplayer_peer() -> Error:
	for peer_id: String in lobby_player_dictionary.keys():
		if peer_id == str(multiplayer.get_unique_id()):
			# Skip this iteration if its you
			continue;
		if (lobby_player_dictionary[peer_id][GlobalConstants.IS_CPU_KEY]):
			# Skip this iteration if its a cpu
			continue;
		var _null: bool = lobby_player_dictionary.erase(peer_id);
	# re initialzize an offline peer to make things still function
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	lobby_connected = false;
	lobby_name = "";
	# No longer clear the lobby, just the non local (because CPUs)
	#lobby_player_dictionary.clear();
	connection_ended.emit();
	data_updated.emit();
	var err: Error;
	if (multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED):
		err = Error.OK;
	else:
		err = Error.FAILED;
	return err;

##  This is called to end the lobby session by [Main]
func end_lobby() -> Error:
	# re initialzize an offline peer to make things still function
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	lobby_connected = false;
	lobby_name = "";
	# No longer clear the lobby, just the non local (because CPUs)
	lobby_player_dictionary.clear();
	connection_ended.emit();
	data_updated.emit();
	var err: Error;
	if (multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED):
		err = Error.OK;
	else:
		err = Error.FAILED;
	return err;


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

## Each game scene calls game_scene_loaded via RPC when everything has initialized [br][br]
## Emits the [signal start_game] signal
@rpc("any_peer","call_local","reliable")
func game_scene_loaded() -> void:
	if (!is_multiplayer_authority()):
		return;
	var non_cpu_count: int = 0;
	for player: String in lobby_player_dictionary :
		# If this is  NOT a CPU we do not have to wait for it to load
		if(!lobby_player_dictionary[player][GlobalConstants.IS_CPU_KEY]):
			non_cpu_count += 1;
	print(non_cpu_count, "is the cpu count when the game loaded")

	players_loaded += 1;
	if players_loaded == non_cpu_count:
		print("emitted game start at %s" % Time.get_ticks_msec())
		start_game.emit();
		players_loaded = 0;

# when the server starts a game from a UI scene, do Lobby.load_game.rpc(filepath)
@rpc("authority","call_local","reliable")
func load_game(game_scene_path: String) -> void:
	#The local main scene will then add the scene and hide the UI
	initialize_game.emit(game_scene_path);
	pass;


## the connecting player will call this when they connect
## Assign them a team color as well and send that information back to them
@rpc("any_peer","call_local", "reliable")
func local_register_player(sender_id: String, new_player_info: Dictionary[String, Variant]) -> void:
	## Defines the color of the player when they join
	var color_int: int = 0;
	## Array of already used colors by int in the lobby
	var color_arr: Array[int] = [];
	## Defines the team_int of the player when they join
	var team_int: int = 0;
	## Array of already used teams by int in the lobby
	var team_arr: Array[int] = [];
	var slot_arr: Array[int] = [];
	var slot_int: int = 0;
	if (!is_multiplayer_authority()):
		return;
	# only register the player on the server, you will then send this information out on update_player_list function
	if (lobby_player_dictionary.has(sender_id)):
		push_error("Recieved register player request on a player that already exists, returning and not updated");
		return;

	# IMPLEMENTATION SPECIFIC DATA GOES HERE
	# choose the color of the player for them when they join

	for player: String in lobby_player_dictionary:
		# go over the list of players, get array of the colors
		color_arr.append(lobby_player_dictionary[player][GlobalConstants.COLOR_KEY])
		team_arr.append(lobby_player_dictionary[player][GlobalConstants.TEAM_KEY])
		slot_arr.append(lobby_player_dictionary[player][GlobalConstants.SLOT_KEY])

	#If this slot is already taken (somehow)
	if slot_arr.has(new_player_info[GlobalConstants.SLOT_KEY]):
		while(slot_arr.has(slot_int)):
			slot_int += 1;
			if(slot_int > MAX_CONNECTIONS):
				push_error("Slot size outside of max connections allowed")
				break
		# Assign new slot to player
		new_player_info[GlobalConstants.SLOT_KEY] = slot_int

	# If this color was already take (somehow)
	if color_arr.has(new_player_info[GlobalConstants.COLOR_KEY]):
		while (color_arr.has(color_int)):
			color_int += 1;
			if (color_int >= GlobalConstants.COLORS.size()):
				push_error("color outside of bounds!");
				break;
		# Assign new color to player
		new_player_info[GlobalConstants.COLOR_KEY] = color_int;

	#if this team is already taken (somehow), find new team to assign to player
	if (team_arr.has(new_player_info[GlobalConstants.TEAM_KEY])):
		while (team_arr.has(team_int)):
			team_int += 1;
			if (team_int >= GlobalConstants.TEAMS.size()):
				push_error("team number outside of bounds!");
				break;
		# Assign new team to player
		new_player_info[GlobalConstants.TEAM_KEY] = team_int;

	# add player information to dictionary of dictionaries
	lobby_player_dictionary[sender_id] = new_player_info;
	# send information to all others connected
	server_update_player_list.rpc(lobby_player_dictionary);
	# So the new connector has data
	server_update_lobby_name.rpc(lobby_name);


#send updated player dictionary when we make changes locally
@rpc("any_peer","call_local", "reliable")
func local_update_peer_information(sender_id: String, updated_dictionary: Dictionary[String, Variant]) -> void:
	if (!is_multiplayer_authority()):
		return;
		#only update the player on the server, you will then send this information out on update_player_list function
	if (!lobby_player_dictionary.has(sender_id)):
		push_error("Recieved update player data request on a player that does not exist");
	#add player information to dictionary of dictionaries
	lobby_player_dictionary[sender_id] = updated_dictionary;
	#send information to all others connected
	server_update_player_list.rpc(lobby_player_dictionary);

@rpc("any_peer", "call_local", "reliable")
func local_update_peer_key(u_peer: String, u_key: String, u_value: Variant) ->void:
	if (!is_multiplayer_authority()):
		return;
	#only update the player on the server, you will then send this information out on update_player_list function
	if (!lobby_player_dictionary.has(u_peer)):
		push_error("Recieved update player data request on a player that does not exist");
	# add player information to dictionary of dictionaries
	# There is some risk that if we are updating a key with an invalid variant type, we can break our dictionary
	lobby_player_dictionary[u_peer][u_key] = u_value;
	print("updated %s key on %s peer to be %s value" %[u_key, u_peer, u_value])
	#send information to all others connected
	server_update_player_list.rpc(lobby_player_dictionary);

## The multiplayer server will call this on all players to update the information of the dictionary
@rpc("authority","call_local","reliable")
func server_update_player_list(lobby_dict: Dictionary)-> void:
	## Multiplayer server ID is 1
	if(multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		return;

	# in case the server has updated our character, update that information first so we can call local data in GUI updates
	var local_player: Dictionary[String, Variant] = lobby_dict[str(multiplayer.get_unique_id())];
	LocalPlayerData.lobby_update_dictionary(local_player);

	# update our lobby's reference to players to be the same as the lobby
	lobby_player_dictionary = lobby_dict;



## the multiplayer server will call this on all players to update the information of the lobby name
@rpc("authority","call_local","reliable")
func server_update_lobby_name(lob_name: String)-> void:
	#Multiplayer server ID is 1
	if(multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		return;
	#update our lobby's reference to palyers to be the same as the
	lobby_name = lob_name;



## when you connect, send your information to the server and then wait for it to add you to lobby scene
func on_connected_ok() -> void: #Set player information if you are the authority
	# connected to server
	lobby_connected = true;
	connection_started.emit();
	# when we connect  to the server, add our own player information to the local StateData autoload
	var peer_id: String = str(multiplayer.get_unique_id());
	# call rpc_id to server only (1)
	local_register_player.rpc_id(1,peer_id, LocalPlayerData.get_local_player());


func on_connected_fail() -> void:
	print("we failed to connect")
	lobby_connected = false;
	connection_ended.emit();
	var _err: Error = remove_multiplayer_peer();


## This function currently doesn't do anything because the player connects sends their information to the server[br]
## Sending peer data to the server causes the server to replicate new information to each peer on lobby update
func on_peer_connected(id: int) -> void:
	#When a peer connects, add them to the lobby scene UI and send any sort of information you need to send to update them
	if(multiplayer.is_server()):
		print("the multiplayer server has recieved a peer that has connected")
		pass;

func on_peer_disconnected(peer_id: int)->void:
	if (!multiplayer.is_server()):
		return;
	var id: String = str(peer_id);
	if (lobby_player_dictionary.has(id)):
		var _success: int = lobby_player_dictionary.erase(id);
		server_update_player_list.rpc(lobby_player_dictionary)
	player_disconnected.emit();

func on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	lobby_connected = false;
	lobby_name = "";
	lobby_player_dictionary.clear();
	connection_ended.emit();
	data_updated.emit();

func _exit_tree() -> void:
	if (upnp_thread && upnp_thread.is_alive()):
		upnp_thread.wait_to_finish();
