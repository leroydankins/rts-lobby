class_name GameLobbyGUI
extends Control

## This signals to Main to hi
signal return_main_pressed();

## Updated verson of lobby_gui that will receive player information from Lobby [br][br]
## Attempting to make Lobby agnostic to if we are online or not?
@onready var create_lobby_button: Button = $LobbyGUI/HostData/HostBox/CreateLobbyButton
@onready var lobby_edit: TextEdit = $LobbyGUI/HostData/HostBox/HBoxContainer/LobbyEdit
@onready var pass_edit: TextEdit = $LobbyGUI/HostData/HostBox/MakePublicBox/PassEdit
@onready var start_button: Button = $LobbyGUI/StartButton
@onready var disconnect_button: Button = $DisconnectButton

## Used in handling display and control cases for objects and disconnecting
var is_host: bool = false;

## Will need to handle if you are host or not, currently I think this is already done

## Integer to give to AI Bot for naming and peer_id [br][br]
## We start at 2 since multiplayer authority is 1
var cpu_num: int = 2;

## Password string used for connecting to the lobby
## Array of PlayerSlotContainers 
## Containers display the following information[br][br]
## [code] Username [/code][br] 
## [code] Race [/code][br]
## [code] Color [/code][br]
## [code] Ready [/code][br]
var player_slot_arr: Array[PlayerSlotContainer] = [
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer/PlayerSlotContainer,
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer2/PlayerSlotContainer, 
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer3/PlayerSlotContainer, 
	$LobbyGUI/PlayerData/PanelContainer/MarginContainer/PlayerBox/ListVBox/MarginContainer4/PlayerSlotContainer,
]

var _null_var : int 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_null_var = Lobby.connection_ended.connect(on_connection_ended);
	_null_var = Lobby.data_updated.connect(on_lobby_update);
	_null_var = Lobby.connection_ended.connect(on_connection_ended);
	_null_var = Lobby.connection_started.connect(on_connection_started);


## Main function of GameLobby [br][br]
## Sets the displayed information of the lobby based on connections
## Changes in the buttons inside of the GUI will send RPC updates to the server, which then updates everyone
func on_lobby_update() -> void:
	## Size of the current Lobby Dictionary Array
	var lobby_dict_size: int = Lobby.lobby_player_dictionary.size();
	## Slots in use according to lobby_player_dictionary["slot"]
	var slot_arr : Array = [];
	## Array of Player Dictionaries held in Lobby containing each players information
	var player_dict_arr: Array[Dictionary] = Lobby.lobby_player_dictionary.values();
	var start_ready: bool = true;
	## Only used by server
	var enough_players:bool = true;
	# for player_slot: PlayerSlotContainer in player_slot_arr
	# Update given information from corresponding players_dict_arr
	# username : String
	# race : int
	# color : int
	# ready : bool 
	# is_cpu : bool
	# calls PlayerSlotContainer function [update_fields], sending dictionary information
	
	for i: int in lobby_dict_size:
		if(is_multiplayer_authority() && player_dict_arr[i][GlobalConstants.IS_CPU_KEY]):
			player_slot_arr[i].enable_edit();
		else:
			player_slot_arr[i].disable_edit();
		player_slot_arr[i].update_player_data(player_dict_arr[i]);
		
		if(!player_dict_arr[i][GlobalConstants.READY_KEY]):
			start_ready = false;

	if (!Lobby.multiplayer.is_server()):
		return;

	##SERVER ONLY ACTIONS
	if(lobby_dict_size <= 1 || lobby_dict_size > Lobby.MAX_CONNECTIONS):
		enough_players = false;
	if(start_ready && enough_players):
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
	## We must implement a password to lobby eventually
	var err: Error = Lobby.create_lobby(lobby_edit.text, password);
	if (err != OK):
		# check if we are a server
		if (Lobby.multiplayer.is_server()):
			print("We are still a server at the moment")
	return err;

## Creates an AI Player and adds dictionary into Lobby.lobby_player_dictionary
## Appends additional PlayerSlot box to the list of players
## Edits of that PlayerSlot box will update data for Lobby
func on_add_ai_pressed() -> void:
	cpu_num += 1;
	## See [member Lobby.lobby_player_dictionary] 
	var ai_bot: Dictionary = {
		"username" = "bot_%s" % cpu_num,

		# The Color and Team values will get overwritten by Lobby when registering to ensure unique 
		"team" = 0,
		"color" = 0,
		"race" = 0,
		# Will get overwritten by lobby to ensure unique
		"slot" = 0,
		"ready" = true,
		"is_ai" = false,
	}
	# Register the cpu to the lobby
	Lobby.local_register_player.rpc_id(get_multiplayer_authority(),str(cpu_num), ai_bot);


## This is not hooked up to anything yet, we need to get the specific ready and update that data
func on_ready_toggled(player_id: String, toggle: bool) -> void:
	# Directly set Lobby player data instead of doing it through LocalPlayerData
	Lobby.local_update_peer_key.rpc_id(1,player_id, GlobalConstants.READY_KEY, toggle)



func on_connection_ended() ->void:
	# If we were joining someone's game
	if (!is_host):
		# Return to join lobby scene or main menu
		pass;
	else:
		# Disconnect any players and keep it a private game
		disconnect_button.disabled = true;


func on_connection_started() ->void:
	# Update connect/disconnect fields
	lobby_edit.editable = false;
	pass_edit.editable = false;
	
	create_lobby_button.disabled = true;
	disconnect_button.disabled = false;

func on_return_to_main() ->void:
	# Setting button_pressed to false will call emit the toggle signal automatically
	# Disconnect from the server first
	Lobby.remove_multiplayer_peer();
	# Reset all buttons
	
	# call disconnect pressed
	return_main_pressed.emit();
