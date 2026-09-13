class_name LobbyScreen
extends Control

## This signals to Main to hi
signal return_main_pressed();

@onready var start_button: Button = $LobbyGUI/StartButton
@onready var return_to_main: Button = $LobbyGUI/ReturnToMain

## Updated verson of lobby_gui that will receive player information from Lobby [br][br]

## Master control of the host buttons to hide and show with ease
@onready var host_control: Control = $LobbyGUI/HostControl
@onready var create_lobby_button: Button = $LobbyGUI/HostControl/PreHostBox/CreateLobbyButton
@onready var lobby_edit: TextEdit = $LobbyGUI/HostControl/PreHostBox/HBoxContainer/LobbyEdit
@onready var pass_edit: TextEdit = $LobbyGUI/HostControl/PreHostBox/MakePublicBox/PassEdit
@onready var username_edit: TextEdit = $LobbyGUI/HostControl/PreHostBox/HBoxContainer2/UsernameEdit

# Live server buttons
@onready var disconnect_lobby_button: Button = $LobbyGUI/HostControl/InHostBox/DCLobbyButton
@onready var uid_label: Label = $LobbyGUI/HostControl/InHostBox/UIDLabel



## Used in handling display and control cases for objects and disconnecting
var is_host: bool = false;


## Password string used for connecting to the lobby
## Array of PlayerSlotContainers
## Containers display the following information[br][br]
## [code] Username [/code][br]
## [code] Race [/code][br]
## [code] Color [/code][br]
## [code] Ready [/code][br]
@onready var player_slot_arr: Array[PlayerSlotContainer] = [
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer/PlayerSlotContainer,
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer2/PlayerSlotContainer,
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer3/PlayerSlotContainer,
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer4/PlayerSlotContainer,
]
## Local inverse version of the [member Lobby.lobby_player_dictionary] [br][br]
## Key [code] slot[/code] : int [br][br]
## value [code] peer[/code] : String
var slot_dict: Dictionary[int,String] = {};

var _null_var : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _success: int
	#
	_null_var = Lobby.data_updated.connect(on_lobby_update);
	_null_var = Lobby.connection_ended.connect(on_connection_ended);
	_null_var = Lobby.connection_started.connect(on_connection_started);
	_null_var = create_lobby_button.pressed.connect(on_create_lobby_pressed)
	_null_var = start_button.pressed.connect(on_start_pressed);
	_null_var = disconnect_lobby_button.pressed.connect(on_disconnect_lobby_pressed);
	_null_var = return_to_main.pressed.connect(on_return_to_main);
	for slot: PlayerSlotContainer in player_slot_arr:
		slot.reset_player_data();
		_success = slot.add_cpu_pressed.connect(on_add_cpu);
		_success = slot.race_updated.connect(on_race_updated);
		_success = slot.color_updated.connect(on_color_updated);
		_success = slot.team_updated.connect(on_team_updated);
		_success = slot.ready_toggled.connect(on_ready_toggled);


## Helper Function called when transitioning to this Menu Screen, sets is_host to true and shows host controls
func set_host() ->void:
	is_host = true;
	host_control.show();
	# If we are starting as an already online game we can add code here

## Helper Function called when transitioning to this Menu Screen, sets is_host to false and hides host controls
func set_client() ->void:
	is_host = false;
	host_control.hide();


## Main function of GameLobby [br][br]
## Sets the displayed information of the lobby based on connections
## Changes in the buttons inside of the GUI will send RPC updates to the server, which then updates everyone
func on_lobby_update() -> void:
	if (!visible):
		return;
	var player_dict: Dictionary = Lobby.lobby_player_dictionary
	## Size of the current Lobby Dictionary Array
	var lobby_dict_size: int = Lobby.lobby_player_dictionary.size();
	## Array of Player Dictionaries held in Lobby containing each players information
	var lobby_dict_keys: Array[String] = Lobby.lobby_player_dictionary.keys();
	## Local var used in iteration
	var player: Dictionary = {};
	## Local var used in iteration
	var slot_int: int;
	## Only used by server
	var team_arr: Array;
	var enough_players:bool = true;
	var start_ready: bool = true;
	## Checked at the end of on_lobby_update by iterating through all the team ids
	var team_ready: bool = false;

	var team_0: int

	# We re-set up the dictionary whenever we get new data
	slot_dict.clear()
	# Establish what slot
	for peer_string: String in lobby_dict_keys:
		slot_int = player_dict[peer_string][GlobalConstants.SLOT_KEY]
		slot_dict[slot_int] = peer_string;
	# Iterate through all the numbers and determine if we have a player in that slot
	for i: int in Lobby.MAX_CONNECTIONS:
		# If this slot has a player associated
		if slot_dict.has(i):
			# Access player dictionary by their slot number
			player = player_dict[slot_dict[i]]
			if (Lobby.is_multiplayer_authority() && player[GlobalConstants.IS_CPU_KEY]):
				player_slot_arr[i].enable_edit();
			else:
				# If this is our player
				if (Lobby.multiplayer.get_unique_id() == int(slot_dict[i])):
					player_slot_arr[i].enable_edit();
				# This is not our player
				else:
					player_slot_arr[i].disable_edit();
			player_slot_arr[i].update_player_data(player);
			if(!player[GlobalConstants.READY_KEY]):
				start_ready = false;
		# No player associated, sending empty dictionary will make it available slot
		else:
			player_slot_arr[i].update_player_data({});



	if (!Lobby.is_multiplayer_authority()):
		start_button.disabled = true;
		return;
	##SERVER ONLY ACTIONS
	team_arr = GlobalFunctions.get_player_property_array(Lobby.lobby_player_dictionary,GlobalConstants.TEAM_KEY);
	# Need more than 1 team
	if (!team_arr):
		return;
	team_0 = team_arr[0]
	for team_id : int in team_arr:
		if (team_id != team_0):
			team_ready = true;

	if(lobby_dict_size <= 1 || lobby_dict_size > Lobby.MAX_CONNECTIONS):
		enough_players = false;
	if(
		start_ready and enough_players
		and team_ready
	):
		start_button.disabled = false;
	else:
		start_button.disabled = true;
# /on_lobby_update On Lobby Update END


func on_create_lobby_pressed()-> Error:
	var password: String;
	if(lobby_edit.text.is_empty()):
		return Error.FAILED
	if(!pass_edit.text.is_empty()):
		password = pass_edit.text;
	# Temporary
	if(username_edit.text.is_empty()):
		return Error.FAILED;
	# This will eventually be done with the Steam ID or something shit man idk
	LocalPlayerData.update_dictionary_data(GlobalConstants.USERNAME_KEY, username_edit.text);
	## We must implement a password to lobby eventually
	var err: Error = Lobby.create_lobby(lobby_edit.text, password);
	return err;



## This is not hooked up to anything yet, we need to get the specific ready and update that data
func on_ready_toggled(slot: int, toggle: bool) -> void:
	# Directly set Lobby player data instead of doing it through LocalPlayerData
	var peer: String = slot_dict[slot]
	# Update the ready signal
	Lobby.local_update_peer_key.rpc_id(1,peer, GlobalConstants.READY_KEY, toggle)

## Creates CPU Player and adds dictionary into Lobby.lobby_player_dictionary
## Edits of that PlayerSlot box will update data for Lobby
func on_add_cpu(slot: int) ->void:
	# Check what numbers are free for CPU Name
	var lobby_keys: Array[String] = Lobby.lobby_player_dictionary.keys();

	## Integer to give to AI Bot for naming and peer_id [br][br]
	var cpu_num : int = 1;
	## One more than CPU_NUM to not interfere with Host peer_id
	var cpu_peer_id: String = str(cpu_num+1);
	# Goes from 0 to Max Connections (4), 1 will be taken by host so we start with i+2 for checking available key
	for i: int in Lobby.MAX_CONNECTIONS:
		if (!lobby_keys.has(str(i+2))):
			cpu_num = i + 1;
			cpu_peer_id = str(i+2);
			break
	## See [member Lobby.lobby_player_dictionary]
	var cpu_dict: Dictionary[String, Variant] = {
		#Reduce the cpu number by 1 for naming since it starts at 2
		"username" = "cpu_%s" % [cpu_num],
		# The Color and Team values will get overwritten by Lobby when registering to ensure unique
		"team" = 0,
		"color" = 0,
		"race" = 0,
		# Will get overwritten by lobby to ensure unique
		"slot" = slot,
		"ready" = true,
		"is_cpu" = true,
	}
	# Register the cpu to the lobby
	Lobby.local_register_player.rpc_id(Lobby.get_multiplayer_authority(),cpu_peer_id,cpu_dict);

func on_race_updated(slot:int, race_int : int) ->void:
	var peer: String = slot_dict[slot]
	if (!GlobalConstants.RACES.has(race_int)):
		push_error("team wasn't in index");
		return;
	#Update colors
	Lobby.local_update_peer_key.rpc_id(1,peer,GlobalConstants.RACE_KEY,race_int)

func on_color_updated(slot:int, color_int: int) ->void:
	var peer: String = slot_dict[slot]
	if (!GlobalConstants.COLORS.has(color_int)):
		push_error("team wasn't in index");
		return;
	#Update colors
	Lobby.local_update_peer_key.rpc_id(1,peer,GlobalConstants.COLOR_KEY,color_int)


func on_team_updated(slot:int, team_int : int) ->void:
	var peer: String = slot_dict[slot]
	if (!GlobalConstants.TEAMS.has(team_int)):
		push_error("team wasn't in index");
		return;
	#Update colors
	Lobby.local_update_peer_key.rpc_id(1,peer,GlobalConstants.TEAM_KEY,team_int)
	pass;

##TODO
func on_connection_ended() ->void:
	# If we were joining someone's game
	if (!is_host):
		# Return to join lobby scene or main menu
		pass;
	# If we are host
	else:
		# Disconnect any players and keep it a private game
		lobby_edit.editable = true;
		pass_edit.editable = true;
		username_edit.editable = true;
		create_lobby_button.disabled = false;

		disconnect_lobby_button.disabled = true;

func on_connection_started() ->void:
	# Update connect/disconnect fields
	lobby_edit.editable = false;
	pass_edit.editable = false;
	username_edit.editable = false;
	create_lobby_button.disabled = true;

	disconnect_lobby_button.disabled = false;

func on_return_to_main() ->void:
	# Setting button_pressed to false will call emit the toggle signal automatically
	# Disconnect from the server happens in main but eventually may be handled prior to that
	# Reset all buttons
	# call disconnect pressed
	return_main_pressed.emit();

func on_start_pressed() ->void:
	if !Lobby.is_multiplayer_authority():
		return;
	var lob_dict: Dictionary[String, Dictionary] = Lobby.lobby_player_dictionary;
	if (Lobby.lobby_player_dictionary.size() <= 1 || Lobby.lobby_player_dictionary.size() > Lobby.MAX_CONNECTIONS):
		push_error("Tried to start game without enough people, or too many people");
		return;
	for peer: String in lob_dict:
		if (lob_dict[peer]["ready"] == false):
			push_error("team isnt ready yet");
			return
		# CALL START GAME RPC AS THE SERVER
	Lobby.load_game.rpc(GlobalConstants.GAME_PATH);

func on_disconnect_lobby_pressed() ->void:
	if !Lobby.is_multiplayer_authority():
		# We are not the host? Why does this matter
		pass;
	# Disconnecting by remove_multiplayer_peer is automatically reacted to by Lobby.gd autoload
	var _null: Error = Lobby.remove_multiplayer_peer();
