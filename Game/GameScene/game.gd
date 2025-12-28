extends Node2D
@onready var game_clock: Label = $CanvasLayer/GameClock
@onready var minerals_label: Label = $CanvasLayer/ResourceBox/MineralsLabel
@onready var gas_label: Label = $CanvasLayer/ResourceBox/GasLabel

@onready var camera: Camera2D = $GameCamera
@onready var spawn_1: Marker2D = $SpawnHolder/Spawn1
@onready var spawn_2: Marker2D = $SpawnHolder/Spawn2
@onready var spawn_3: Marker2D = $SpawnHolder/Spawn3
@onready var spawn_4: Marker2D = $SpawnHolder/Spawn4
@onready var entity_holder: Node2D = $EntityHolder

var command_center: PackedScene = preload(GlobalConstants.COMMAND_CENTER)
var spawns: Array[Marker2D];

#dictionary of all players and their in game data (like resources)
#currently only used by the host, but likely will keep data updated across all peers for synchronicity
var player_game_dict: Dictionary[String, Dictionary] = {};
#will be local player data that everything local uses to show information
var local_game_dict: Dictionary[String, Variant] = {};

var time: float = 0;
var start_time: float = 0;
var started: bool = false;
var hr: int = 0;
var min: int = 0;
var sec: int = 0;

const PLAYER_ID_KEY: String = "player_id";
const PLAYER_USERNAME: String = "player_username";
const PLAYER_RESOURCE_KEY: String = "player_resource";
const PLAYER_GAS_KEY: String = "player_gas";
const PLAYER_RACE_KEY: String = "player_race";

#used in initialize function
const PLAYER_DICTIONARY_KEY: String = "player_dictionary";




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawns = [spawn_1, spawn_2, spawn_3,  spawn_4]
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer;
	#Connect to signals from Lobby
	Lobby.start_game.connect(on_start);
	Lobby.game_scene_loaded.rpc_id(Lobby.multiplayer_server_id);
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!started):
		return;
	minerals_label.text = "Minerals: %s" % local_game_dict[PLAYER_RESOURCE_KEY]
	gas_label.text = "Gas: %s" % local_game_dict[PLAYER_GAS_KEY];
	time = Time.get_ticks_msec() - start_time;
	sec = int(time / 1000) % 60
	min = int(time/ (1000 * 60)) % 60
	hr = int(time/ (1000 * 60 * 60)) % 24
	game_clock.text = "%s: %s: %s" % [hr, min, sec]
	pass

func on_start() -> void:
	if(!multiplayer.is_server()):
		return
	var init_dict: Dictionary = {};
	var start_spot: int = 0;
	for player_id: String in Lobby.lobby_player_dictionary:
		#create the peer's local player data
		var player_dictionary: Dictionary[String, Variant] = {
		"player_id" = player_id,
		"player_username" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.USERNAME_KEY],
		"player_race" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.RACE_KEY],
		"player_resource" = 400,
		"player_gas" = 0
		}
		#
		player_game_dict[player_id] = player_dictionary;

		init_dict["spawn_id"] = start_spot;
		init_dict["player_dictionary"] = player_dictionary;
		var spawn_loc: Vector2 = spawns[start_spot].global_position;
		#spawn the starting player's command center via RPC to all players
		var spawn_dict: Dictionary ={
		#temp use of a direct constant, the filepath will depend on starting race
		"file_path" = GlobalConstants.COMMAND_CENTER,
		"team" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.TEAM_KEY],
		"position" = spawn_loc,
		"color" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.COLOR_KEY]
		}
		add_entity_from_dict.rpc(spawn_dict);
		start_spot += 1;
		print(Lobby.lobby_player_dictionary[player_id], Time.get_ticks_msec());
		initialize_local_start.rpc_id(player_id.to_int(), init_dict);
	#after all data has been collected for each player and our dicitonary game has been created

	#Initialize every player's dictionary of all player data
	push_game_data_batch.rpc(player_game_dict)


	start_game.rpc();

@rpc("authority", "call_local", "reliable")
func add_entity_from_dict(dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return;
	if (dict.is_empty()):
		return;
	var obj: Node2D = load(dict["file_path"]).instantiate();
	obj.team = dict["team"];
	obj.global_position = dict["position"];
	#color is an int, the object will access the actual color via GlobalConstants
	obj.color = dict["color"];
	entity_holder.add_child(obj);
	pass;

#set up game for player, called by rpc_id to each specific player
@rpc("authority", "call_local", "reliable")
func initialize_local_start(init_dict: Dictionary) -> void:
	if (init_dict.is_empty()):
		push_error(multiplayer.get_unique_id(), "cannot initialize game start data, init dict was empty")
		return;
	if (init_dict.has("spawn_id")):
		var spawn:Marker2D = spawns[init_dict["spawn_id"]];
		camera.global_position = spawn.global_position;
	#our local dictionary becomes the dictionary that the server created for us
	if (init_dict.has(PLAYER_DICTIONARY_KEY)):
		local_game_dict = init_dict[PLAYER_DICTIONARY_KEY];
	return;



@rpc("any_peer", "call_local", "reliable")
func request_player_data_update(player_id: String, key: String, data: Variant) -> void:
	if (!multiplayer.is_server()):
		return;
	if (!player_game_dict.has(player_id)):
		return;
	player_game_dict[player_id][key] = data;
	push_player_data_update.rpc



##TODO
@rpc("any_peer", "call_local", "reliable")
func request_player_data_update_batch(player_id: String, new_dict: Dictionary[String,Variant]) ->void:
	#send a full local player dictionary to that player
	pass;

##TODO
@rpc("authority", "call_local", "reliable")
func push_player_data_update(updated_player: String, key: String, data: Variant) ->void:
	#if this was not called by the authority return;
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		push_error("this wasnt sent by the authority? wtf");
		return;
	#if this is not a valid player return;
	if (!player_game_dict.has(updated_player)):
		push_error("not a valid player in dictionary");
		return;
	#update our player_game_dictionary
	player_game_dict[updated_player][key] = data;

	#if we are updating the local player's information
	if (updated_player == local_game_dict[PLAYER_ID_KEY]):
		#if we dont have this key in our dicitionary return;
		if (!local_game_dict.has(key)):
			return;
		local_game_dict[key] = data;
	pass;

##TODO
@rpc("authority", "call_local", "reliable")
func push_player_data_update_batch(updated_player:String, dict: Dictionary[String, Variant]) ->void:
	pass;

#Called during the game initialization startup
@rpc("authority","call_local","reliable")
func push_game_data_batch(dict: Dictionary[String, Dictionary]) ->void:
	#if this was not called by the authority return;
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		push_error("this wasnt sent by the authority? wtf");
		return;
	player_game_dict = dict;

	#also should update our local player data with this data in order to keep things synced as possible
	local_game_dict = player_game_dict[local_game_dict[PLAYER_ID_KEY]]
	print(local_game_dict, Time.get_ticks_msec());
	pass;

#function that server does to set everyone's information
#iterate over the Lobby dictionary and establish their information
#called by the server, each local person starts the game
@rpc("authority","call_local","reliable")
func start_game() -> void:
	started = true;
	game_clock.text = "00:00";
	start_time = Time.get_ticks_msec();
	pass;
