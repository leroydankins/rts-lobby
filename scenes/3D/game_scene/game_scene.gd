class_name GameScene
extends Node3D
@onready var game_clock: Label = $UI_Layer/GameClock
@onready var minerals_label: Label = $UI_Layer/ResourceBox/MineralsLabel
@onready var gas_label: Label = $UI_Layer/ResourceBox/GasLabel
#TEMPORARY
@onready var team_label: Label = $UI_Layer/ResourceBox/TeamLabel

@onready var command_controller: Node = $CommandController

@onready var camera: Node3D = $CameraBase
@onready var spawn_1: Marker3D = $SpawnHolder/Spawn1
@onready var spawn_2: Marker3D = $SpawnHolder/Spawn2
@onready var entity_holder: EntityHolder = $EntityHolder

var spawns: Array[Marker3D];

#dictionary of all players and their in game data (like resources)
#currently only used by the host, but likely will keep data updated across all peers for synchronicity
var player_game_dict: Dictionary[String, Dictionary] = {};
#will be local player data that everything local uses to show information
var local_game_dict: Dictionary[String, Variant] = {};

var time: float = 0;
var start_time: float = 0;
var started: bool = false;
var hr: int = 0;
var minutes: int = 0;
var sec: int = 0;

const PLAYER_ID_KEY: String = "player_id";
const PLAYER_USERNAME_KEY: String = "player_username";
const PLAYER_RESOURCE_KEY: String = "player_resource";
const PLAYER_GAS_KEY: String = "player_gas";
const PLAYER_RACE_KEY: String = "player_race";
const PLAYER_COLOR_KEY: String = "player_color";

#used in initialize function
const PLAYER_DICTIONARY_KEY: String = "player_dictionary";




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawns = [spawn_1, spawn_2]
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer;
	#Connect to signals from Lobby
	var _null_var: int = Lobby.start_game.connect(on_start);
	Lobby.game_scene_loaded.rpc_id(Lobby.multiplayer_server_id);
	team_label.text = "Team %s" % GlobalConstants.TEAMS[LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]];
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (!started):
		return;
	if (local_game_dict.is_empty()):
		return;
	minerals_label.text = "Minerals: %s" % local_game_dict[PLAYER_RESOURCE_KEY]
	gas_label.text = "Gas: %s" % local_game_dict[PLAYER_GAS_KEY];
	time = Time.get_ticks_msec() - start_time;
	sec = int(time / 1000) % 60
	minutes = int(time/ (1000 * 60)) % 60
	hr = int(time/ (1000 * 60 * 60)) % 24
	game_clock.text = "%s: %s: %s" % [hr, minutes, sec]
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
		"player_team" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.TEAM_KEY],
		"player_color" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.COLOR_KEY],
		"player_resource" = 400,
		"player_gas" = 0
		}
		#
		player_game_dict[player_id] = player_dictionary;

		init_dict["spawn_id"] = start_spot;
		init_dict["player_dictionary"] = player_dictionary;
		var spawn_loc: Vector3 = spawns[start_spot].global_position;
		#spawn the starting player's command center via RPC to all players
		var spawn_info: Dictionary ={
			"team" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.TEAM_KEY],
			"player_id" = player_id,
			"position" = spawn_loc,
			"color" =  player_dictionary[PLAYER_COLOR_KEY],
			"race" = player_dictionary[PLAYER_RACE_KEY]
		}
		var spawn_dict: Dictionary ={
		#temp use of a direct constant, the filepath will depend on starting race
		"team" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.TEAM_KEY],
		"player_id" = player_id,
		"position" = spawn_loc,
		"color" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.COLOR_KEY]
		}
		match(player_dictionary[PLAYER_RACE_KEY]):
			0:
				#dwarf
				spawn_dict["file_path"] = GlobalConstants.DWARF_SETTLEMENT_FILEPATH
			_:
				#Default is dwarf rn
				spawn_dict["file_path"] = GlobalConstants.DWARF_SETTLEMENT_FILEPATH
		create_initial_player_entities(spawn_info)
		start_spot += 1;

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
	var obj: Node3D = load(dict["file_path"]).instantiate();
	obj.team = dict["team"];
	obj.player_id = dict["player_id"];
	obj.global_position = dict["position"];
	#color is an int, the object will access the actual color via GlobalConstants
	obj.color = dict["color"];
	entity_holder.add_child(obj);
	pass;

@rpc("authority", "call_local", "reliable")
func create_initial_player_entities(dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return;
	if (dict.is_empty()):
		push_error("BUG AT GAME_SCENE TRYING TO SPAWN INITIAL UNITS");
		return;
	var spawn_path: String = "";
	match(dict[PLAYER_RACE_KEY]):
		0:#dwarf
			spawn_path = GlobalConstants.DWARF_SETTLEMENT_FILEPATH;
		_:
			#Default is dwarf rn
			spawn_path = GlobalConstants.DWARF_SETTLEMENT_FILEPATH;
	var start_building: Node3D = load(spawn_path).instantiate();
	start_building.team = dict["team"];
	start_building.player_id = dict["player_id"];
	start_building.global_position = dict["position"];
	#color is an int, the object will access the actual color via GlobalConstants
	start_building.color = dict["color"];
	start_building.is_constructed = true;
	entity_holder.register_entity(start_building);
	pass;

#set up game for player, called by rpc_id to each specific player
@rpc("authority", "call_local", "reliable")
func initialize_local_start(init_dict: Dictionary) -> void:
	if (init_dict.is_empty()):
		push_error(multiplayer.get_unique_id(), "cannot initialize game start data, init dict was empty")
		return;
	if (init_dict.has("spawn_id")):
		var spawn : Marker3D = spawns[init_dict["spawn_id"]];
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
	if(key == PLAYER_RESOURCE_KEY || key == PLAYER_GAS_KEY):

		var val: int = player_game_dict[player_id][key];

		var new_val: int = val + data;
		if (val <= 0):
			val = 0;
		data = new_val;

	player_game_dict[player_id][key] = data;

	push_player_data_update.rpc(player_id,key,data);



##TODO
@rpc("any_peer", "call_local", "reliable")
func request_player_data_update_batch(_player_id: String, _new_dict: Dictionary[String,Variant]) ->void:
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

		local_game_dict[key] = data;
		print(local_game_dict[key]);
	pass;

@rpc("authority", "call_local", "reliable")
func push_player_data_update_batch(updated_player:String, dict: Dictionary[String, Variant]) ->void:
	#if this was not called by the authority return;
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		push_error("this wasnt sent by the authority? wtf");
		return;
	#if this is not a valid player return;
	if (!player_game_dict.has(updated_player)):
		push_error("not a valid player in dictionary");
		return;
		#if we are updating the local player's information
	#update our player_game_dictionary
	player_game_dict[updated_player] = dict;

	if (updated_player == local_game_dict[PLAYER_ID_KEY]):
		local_game_dict = dict;


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

#array has a slot for each resource type because it has to pass both as checks for spending
#Array cannot be typed due to functionality of originating Dictionary (See GlobalConstants CMD Dictionaries)
func spend_resources(player_id: String, cost_arr: Array) -> bool:
	var mineral_cost: int = cost_arr[0];
	var gas_cost: int = cost_arr[1];
	#final check on resources
	if (mineral_cost > player_game_dict[player_id][PLAYER_RESOURCE_KEY]):
		return false;
	if (gas_cost> player_game_dict[player_id][PLAYER_GAS_KEY]):
		return false;
	#cost array is converted to absolute values
	request_player_data_update.rpc(player_id, PLAYER_RESOURCE_KEY, -1 * abs(mineral_cost));
	request_player_data_update.rpc(player_id, PLAYER_GAS_KEY, -1 * abs(gas_cost));
	return true;

#cost array is converted to absolute values
func refund_resources(player_id: String, cost_arr: Array) ->bool:
	var mineral_cost: int = cost_arr[0];
	var gas_cost: int = cost_arr[1];
	#final check on resources
	print(player_game_dict[player_id])
	#max allowable minerals?
	if (mineral_cost > 99999):
		return false;
	#max allowable gas?
	if (gas_cost> 99999):
		return false;

	request_player_data_update.rpc(player_id, PLAYER_RESOURCE_KEY, abs(mineral_cost));
	request_player_data_update.rpc(player_id, PLAYER_GAS_KEY, abs(gas_cost));
	return true;

#check which resource to supply in this scenario, different than spend s
func gain_resources(player_id: String, resource_arr: Array) -> bool:
	#slot 1 is amount, slot 2 is resource type
	match(resource_arr[1]):
		GlobalConstants.ResourceType.MINERAL:
			var mineral_cost: int = resource_arr[0];
			request_player_data_update.rpc(player_id, PLAYER_RESOURCE_KEY, mineral_cost);
			return true;
		GlobalConstants.ResourceType.GAS:
			var gas_cost: int = resource_arr[0];
			request_player_data_update.rpc(player_id, PLAYER_GAS_KEY, gas_cost);
			return true;
		_:
			print("not valid resource type, returning  false")
			return false;

#function that server does to set everyone's information
#iterate over the Lobby dictionary and establish their information
#called by the server, each local person starts the game
@rpc("authority","call_local","reliable")
func start_game() -> void:
	started = true;
	game_clock.text = "00:00";
	start_time = Time.get_ticks_msec();

	pass;
