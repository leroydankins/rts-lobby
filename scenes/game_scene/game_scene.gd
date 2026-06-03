class_name GameScene
extends Node3D

signal quit_event();
signal score_screen_event();
signal game_finished();

@onready var game_clock: Label = $UI_Layer/GameClock
@onready var minerals_label: Label = $UI_Layer/ResourceBox/MineralsLabel
@onready var gas_label: Label = $UI_Layer/ResourceBox/GasLabel
#TEMPORARY
@onready var team_label: Label = $UI_Layer/ResourceBox/TeamLabel
@export var player_data_manager: PlayerDataManager;
@onready var command_controller: Node = $CommandController

@onready var camera: Node3D = $CameraBase
@onready var entity_holder: EntityHolder = $EntityHolder
@onready var spawn_holder: Node3D = $SpawnHolder
@onready var in_game_menu: InGameMenu = $UI_Layer/InGameMenu

## Array Marker3Ds of used in establishing each player's initial TownHall and Workers
var spawns: Array[Node3D];

## Each player has a dictionary of the following fields used in creation, assigned to [PlayerDataManager] [br][br]
##[code] player_id[/code] :  [int] Assigned to all units owned by of player_id player, same as player_color  [br][br]
##[code] player_username[/code] :  [String] Username associated with the player established in the Menus, [br][br]
##[code] player_race[/code] :  [int] Player Race chosen in [Lobby], Race string is accessed from [constant GlobalConstants.RACES] [br][br]
##[code] player_team[/code] :  [int] value representing Team, used in win condition testing and for determining what is visible [br][br]
##[code] player_color[/code] :  [int] value same as player_id but used to determine color of units [br][br]
##[code] player_mineral[/code] :  [int] Amount of mineral resource, managed by [PlayerDataManager] [br][br]
##[code] player_gas[/code] :  [int] Amount of gas resource, managed by [PlayerDataManager] [br][br]
##[code] player_supply[/code] :  [Array] of Initialized Supply, [ [code]used[/code] ,  [code]capacity[/code] ] [br][br]
##[code] player_peer_id[/code] :  [String] Online Multiplayer Peer ID for the individual, used in RPC ID calls but game logic should rely on player_id [br][br]
##[code] player_playing[/code] :  [bool] for checking players still in game in win/loss conditionals, [br][br]
var initializing_player_dict: Dictionary[String, Variant];

var player_resource: int = 50; ## Initial [code] Mineral [/code] count at the start of the game
var player_gas: int = 0; ## Initial [code] Gas [/code] count at the start of the game
var elapsed_time: float = 0; ## Time since [method start_game] has been called
var start_time: float = 0;
var game_is_active: bool = false;
var hr: int = 0;
var minutes: int = 0;
var sec: int = 0;

#used in initialize function
const PLAYER_DICTIONARY_KEY: String = "player_dictionary";


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for spawn: Node3D in spawn_holder.get_children():
		spawns.append(spawn);
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer;

	# Connect to signals from Lobby
	var _null_var: int = Lobby.start_game.connect(on_start);
	entity_holder.player_lost.connect(on_player_lost);
	player_data_manager.team_won.connect(on_team_won);
	_null_var = in_game_menu.quit_pressed.connect(on_quit);
	_null_var = in_game_menu.options_pressed.connect(on_options);
	_null_var = in_game_menu.resume_pressed.connect(on_resume);
	_null_var = in_game_menu.return_to_game_pressed.connect(on_return);
	_null_var = in_game_menu.score_screen_pressed.connect(on_score_screen);
	Lobby.game_scene_loaded.rpc_id(get_multiplayer_authority());

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (!game_is_active):
		return;
	minerals_label.text = "Minerals: %s" % player_data_manager.player_dict[player_data_manager.local_id][PlayerDataManager.MINERAL_KEY]
	gas_label.text = "Gas: %s" % player_data_manager.player_dict[player_data_manager.local_id][PlayerDataManager.GAS_KEY];

	elapsed_time = Time.get_ticks_msec() - start_time;
	sec = int(elapsed_time / 1000) % 60
	minutes = int(elapsed_time/ (1000 * 60)) % 60
	hr = int(elapsed_time/ (1000 * 60 * 60)) % 24
	game_clock.text = "%s: %s: %s" % [hr, minutes, sec]
	pass

func on_start() -> void:
	if(!multiplayer.is_server()):
		return
	var init_dict: Dictionary = {};
	var start_spot: int = 0;
	# before all data has been collected for each player and our dictionary game has been created, create the player arr in entity_hjolder
	var player_arr: Array[int] = [];
	for player: String in Lobby.lobby_player_dictionary:
		player_arr.append(Lobby.lobby_player_dictionary[player][GlobalConstants.COLOR_KEY])

	entity_holder.initialize_player_arr.rpc(player_arr);
	for player_id: String in Lobby.lobby_player_dictionary:
		var player: int = Lobby.lobby_player_dictionary[player_id][GlobalConstants.COLOR_KEY];
		#new version, we do not want to base unit values off peer id so we care about color/player_id instead of peer id
		## Data is collected from the lobby node and then we do not communicate with lobby after
		initializing_player_dict = {
		"player_id" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.COLOR_KEY], #num int and also is the same as color
		"player_username" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.USERNAME_KEY],
		"player_race" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.RACE_KEY],
		"player_team" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.TEAM_KEY],
		"player_color" = Lobby.lobby_player_dictionary[player_id][GlobalConstants.COLOR_KEY],
		"player_mineral" = player_resource,
		"player_gas" = player_gas,
		"player_supply" = [0,0],
		"player_peer_id" = player_id,
		"player_playing" = true,
		}

		player_data_manager.player_dict[player] = initializing_player_dict; #player is an int key for the

		init_dict["spawn_id"] = start_spot; #Package starting location to send in RPC
		var spawn_loc: Vector3 = spawns[start_spot].global_position;
		#spawn the starting player's command center via RPC to all players
		var spawn_dictionary: Dictionary ={
			"team" = initializing_player_dict[PlayerDataManager.TEAM_KEY],
			"player_id" = player_id,
			"position" = spawn_loc,
			"color" =  initializing_player_dict[PlayerDataManager.COLOR_KEY],
			"race" = initializing_player_dict[PlayerDataManager.RACE_KEY]
		}
		create_initial_player_entities.rpc(spawn_dictionary)
		start_spot += 1;

		initialize_local_start.rpc_id(player_id.to_int(), init_dict, initializing_player_dict["player_color"]); #RPC To create local player data, data is repeated in local dict for ease of access
	# Initialize every player's dictionary of all player data
	player_data_manager.push_game_data_batch.rpc(player_data_manager.player_dict)

	start_game.rpc();

@rpc("authority", "call_local", "reliable")
func add_entity_from_dict(spawn_dictionary: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return;
	if (spawn_dictionary.is_empty()):
		return;
	var obj: Node3D = load(spawn_dictionary["file_path"]).instantiate();
	obj.team = spawn_dictionary["team"];
	obj.player_id = spawn_dictionary["player_id"];
	obj.global_position = spawn_dictionary["position"];
	obj.color = spawn_dictionary["color"]; #color is an int, the object will access the actual color via GlobalConstants
	entity_holder.add_child(obj);
	pass;

@rpc("authority", "call_local", "reliable")
func create_initial_player_entities(dict: Dictionary) -> void:
	var start_building : Node3D;
	var spawn_path : String;
	var packed_scene: PackedScene;
	if (multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		return;
	if (dict.is_empty()):
		push_error("BUG AT GAME_SCENE TRYING TO SPAWN INITIAL UNITS");
		return;

	match(dict["race"]):
		0:#dwarf
			spawn_path = GlobalConstants.DWARF_SETTLEMENT_FILEPATH;
		_:
			#Default is dwarf rn
			spawn_path = GlobalConstants.DWARF_SETTLEMENT_FILEPATH;
	packed_scene = load(spawn_path);
	start_building = packed_scene.instantiate();
	start_building.team = dict["team"];
	# color is an int, the object will access the actual color via GlobalConstants
	start_building.color = dict["color"];
	start_building.is_constructed = true;
	entity_holder.register_entity(start_building);
	start_building.global_position = dict["position"];
	pass;

#set up game for player, called by rpc_id to each specific player
@rpc("authority", "call_local", "reliable")
func initialize_local_start(init_dict: Dictionary, player_id: int) -> void:
	player_data_manager.local_id = player_id
	if (init_dict.is_empty()):
		push_error(multiplayer.get_unique_id(), "cannot initialize game start data, init dict was empty")
		return;
	if (init_dict.has("spawn_id")):
		var spawn : Marker3D = spawns[init_dict["spawn_id"]];
		camera.global_position = Vector3(spawn.global_position.x, 0, spawn.global_position.z);


## function that server does to set everyone's information [br][br]
## iterates over the Lobby dictionary and establish their information [br][br]
## called by the server, each local person starts the game [br][br]
@rpc("authority","call_local","reliable")
func start_game() -> void:
	print("started game game start at %s" % Time.get_ticks_msec())
	process_mode = Node.PROCESS_MODE_INHERIT
	game_is_active = true;
	game_clock.text = "00:00";
	start_time = Time.get_ticks_msec();
	team_label.text = "Team: %s" % player_data_manager.player_dict[player_data_manager.local_id][PlayerDataManager.TEAM_KEY];


# these get called only on multiplayer authority
@rpc("any_peer","call_local","reliable")
func on_player_lost(losing_player: int) ->void:
	if(!is_multiplayer_authority()):
		return;
	var peer_id: int = int(player_data_manager.player_dict[losing_player][PlayerDataManager.PEER_ID_KEY])
	player_data_manager.defeat_player(losing_player); #will emit team won if team wins
	player_lost_rpc.rpc(peer_id); #tell the clients that this person quit so they stop syncing

#players lose individually, but its a team that wins in the game logic
func on_team_won(winner_team: int) ->void:
	if(!is_multiplayer_authority()):
		return;
	var dict: Dictionary = player_data_manager.player_dict;
	for player: int in dict:
		var peer_id: String = dict[player][PlayerDataManager.PEER_ID_KEY];
		if dict[player][PlayerDataManager.TEAM_KEY] == winner_team:
			end_game_rpc.rpc_id(int(peer_id), true); # Winner
		else:
			end_game_rpc.rpc_id(int(peer_id), false);



@rpc("authority","call_local","reliable")
func player_lost_rpc(peer_id: int) ->void:
	var local: bool = false;
	if(peer_id == int(player_data_manager.player_dict[player_data_manager.local_id][PlayerDataManager.PEER_ID_KEY])): #If this is us
		local = true;
		process_mode = Node.PROCESS_MODE_DISABLED;
		game_is_active = false;
		in_game_menu.show_defeat();
	for sync: SyncComponent in get_tree().get_nodes_in_group("SyncComponent"):
		sync.set_visibility_for(peer_id, false)
		if(local):
			sync.stop_sync();




@rpc("authority", "call_local", "reliable")
func end_game_rpc(is_winner: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED;
	for sync: SyncComponent in get_tree().get_nodes_in_group("SyncComponent"):
		sync.stop_sync()
	game_is_active = false;
	if (is_winner):
		in_game_menu.show_victory();
	else:
		in_game_menu.show_defeat();

func on_quit() -> void:
	#tell the server that we quit
	on_player_lost.rpc_id(get_multiplayer_authority(),player_data_manager.local_id);
	#player_data_manager.player_lost.rpc(player_data_manager.local_id);

func on_resume() ->void:
	in_game_menu.toggle_menu();
	pass;

func on_return() -> void:
	in_game_menu.toggle_menu(); #same as resume for now until we implement paused single player gaming :3 3/25/26
	pass;

func on_score_screen() ->void:
	#emit signal to main menu to swap to that and get the hell out of here
	score_screen_event.emit();
	pass;

func on_options() ->void:
	pass;

#placeholder scripts for main menu
func get_player_data() ->Dictionary:
	return player_data_manager.player_dict;
func get_player_history() ->Dictionary:
	return {};
func get_cmd_array() -> Dictionary:
	return {};

func get_elapsed_time() -> float:
	var time: float = Time.get_ticks_msec() - start_time;
	return time;
