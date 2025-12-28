extends Control
@onready var lobby_data: Control = $LobbyData

@onready var create_lobby_button: Button = $HostData/HostBox/CreateLobbyButton
@onready var username_edit: TextEdit = $LoginData/LoginBox/HBoxContainer/UsernameEdit
@onready var lobby_edit: TextEdit = $HostData/HostBox/HBoxContainer/LobbyEdit

@onready var join_lobby_button: Button = $JoinData/JoinBox/JoinLobbyButton
@onready var ip_text_box: TextEdit = $JoinData/JoinBox/HBoxContainer2/IPTextBox


#Lobby Option Vars
@onready var disconnect_button: Button = $LobbyControls/VBoxContainer/DisconnectBox/DisconnectButton
@onready var ready_button: Button = $LobbyControls/VBoxContainer/ReadyBox/ReadyButton
@onready var start_button: Button = $LobbyControls/VBoxContainer/StartBox/StartButton
@onready var team_dropdown: OptionButton = $LobbyControls/VBoxContainer/TeamPickerHbox/TeamDropdown
@onready var race_dropdown: OptionButton = $LobbyControls/VBoxContainer/RacePickerHbox/RaceDropdown


#Lobby Status Vars
@onready var lobby_label: Label = $LobbyData/LobbyBox/LobbyLabel
@onready var connection_status: Label = $LobbyData/LobbyBox/ConnectionStatus

var peer_name_labels: Array[Label];
@onready var peer_1_name: Label = $LobbyData/LobbyBox/Peer1Box/Peer1Name
@onready var peer_2_name: Label = $LobbyData/LobbyBox/Peer2Box/Peer2Name
@onready var peer_3_name: Label = $LobbyData/LobbyBox/Peer3Box/Peer3Name
@onready var peer_4_name: Label = $LobbyData/LobbyBox/Peer4Box/Peer4Name
var peer_ready_labels: Array[Label];
@onready var peer_1_ready: Label = $LobbyData/LobbyBox/Peer1Box/Peer1Ready
@onready var peer_2_ready: Label = $LobbyData/LobbyBox/Peer2Box/Peer2Ready
@onready var peer_3_ready: Label = $LobbyData/LobbyBox/Peer3Box/Peer3Ready
@onready var peer_4_ready: Label = $LobbyData/LobbyBox/Peer4Box/Peer4Ready
var peer_team_labels: Array[Label];
@onready var peer_1_team: Label = $LobbyData/LobbyBox/Peer1Box/Peer1Team
@onready var peer_2_team: Label = $LobbyData/LobbyBox/Peer2Box/Peer2Team
@onready var peer_3_team: Label = $LobbyData/LobbyBox/Peer3Box/Peer3Team
@onready var peer_4_team: Label = $LobbyData/LobbyBox/Peer4Box/Peer4Team
var peer_colors: Array[ColorRect];
@onready var peer_1_color: ColorRect = $LobbyData/LobbyBox/Peer1Box/Peer1Color
@onready var peer_2_color: ColorRect = $LobbyData/LobbyBox/Peer2Box/Peer2Color
@onready var peer_3_color: ColorRect = $LobbyData/LobbyBox/Peer3Box/Peer3Color
@onready var peer_4_color: ColorRect = $LobbyData/LobbyBox/Peer4Box/Peer4Color





# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	peer_name_labels = [peer_1_name, peer_2_name, peer_3_name, peer_4_name];
	peer_ready_labels = [peer_1_ready, peer_2_ready, peer_3_ready, peer_4_ready];
	peer_team_labels = [peer_1_team, peer_2_team, peer_3_team, peer_4_team];
	peer_colors = [peer_1_color, peer_2_color, peer_3_color, peer_4_color];
	for color_control: ColorRect in peer_colors:
		color_control.hide();
	#Subscription to Lobby Signals
	Lobby.data_updated.connect(on_lobby_update);
	Lobby.connection_ended.connect(on_connection_ended);
	Lobby.connection_started.connect(on_connection_started);

	create_lobby_button.pressed.connect(on_create_lobby_pressed);
	join_lobby_button.pressed.connect(on_join_lobby_pressed);
	disconnect_button.pressed.connect(on_disconnect_pressed);
	start_button.pressed.connect(on_start_pressed);
	ready_button.toggled.connect(on_ready_toggled);
	team_dropdown.item_selected.connect(on_team_select);
	race_dropdown.item_selected.connect(on_race_select);


func on_lobby_update() -> void:
	#Lobby Name
	lobby_label.text = "Lobby: %s" % Lobby.lobby_name;

	#if we are not connected to any lobby
	if (!Lobby.is_connected):
		connection_status.text = "Status: Not Connected"
		for i: int in peer_name_labels.size():
			peer_name_labels[i].text = "Peer %s" % [i+1];
			peer_ready_labels[i].text = "";
			peer_colors[i].hide();

	#if we are connected to a lobby
	else:
		connection_status.text = "Status: Connected"
		var dict_size: int = Lobby.lobby_player_dictionary.size();
		var players_arr: Array[Dictionary] = Lobby.lobby_player_dictionary.values();
		var start_ready: bool = true;
		for i: int in peer_name_labels.size():
			if (i < dict_size):
				if (!players_arr[i]["ready"]):
					peer_ready_labels[i].text = "Not Ready";
					#if any player is not ready, we will set this to false and check after for loop to decide if start button can be ready
					start_ready = false;
				else:
					peer_ready_labels[i].text = "Ready";
				peer_name_labels[i].text = "Peer %s: %s " % [i+1,players_arr[i][GlobalConstants.USERNAME_KEY]];
				peer_team_labels[i].text = "Team: %s" % GlobalConstants.TEAMS[players_arr[i][GlobalConstants.TEAM_KEY]];
				peer_colors[i].color = GlobalConstants.COLORS[players_arr[i][GlobalConstants.COLOR_KEY]]
				peer_colors[i].show();
			else:
				peer_name_labels[i].text = "Peer %s: Empty" % [i+1];
				peer_ready_labels[i].text = "";
				peer_team_labels[i].text = "";
				peer_colors[i].hide();

		if (!Lobby.multiplayer.is_server()):
			return;

		##SERVER ONLY ACTIONS
		var enough_players:bool = true;
		if(Lobby.lobby_player_dictionary.size() <= 1 || Lobby.lobby_player_dictionary.size() > Lobby.MAX_CONNECTIONS):
			enough_players = false;
		if(start_ready && enough_players):
			start_button.disabled = false;
		else:
			start_button.disabled = true;
		#if Lobby.is_connected END

func on_ready_toggled(toggle: bool) -> void:
	print(toggle);
	if (toggle):
		LocalPlayerData.update_dictionary_data(GlobalConstants.READY_KEY, true)
	else:
		LocalPlayerData.update_dictionary_data(GlobalConstants.READY_KEY, false)

func on_team_select(index: int) -> void:
	var id: int = team_dropdown.get_item_id(index);
	if (!GlobalConstants.TEAMS.has(id)):
		push_error("team wasn't in index");
		return;
	print(GlobalConstants.TEAMS[id]);
	LocalPlayerData.update_dictionary_data(GlobalConstants.TEAM_KEY, id);
	LocalPlayerData.update_dictionary_data(GlobalConstants.COLOR_KEY, id);

func on_race_select(index: int) -> void:
	var id: int = race_dropdown.get_item_id(index);
	if (!GlobalConstants.RACES.has(id)):
		push_error("team wasn't in index");
		return;
	print(GlobalConstants.RACES[id]);
	LocalPlayerData.update_dictionary_data(GlobalConstants.RACE_KEY, id);

func on_start_pressed() -> void:
	if !Lobby.multiplayer.is_server():
		return;
	var lob_dict: Dictionary[String, Dictionary] = Lobby.lobby_player_dictionary;
	if (Lobby.lobby_player_dictionary.size() <= 1 || Lobby.lobby_player_dictionary.size() > Lobby.MAX_CONNECTIONS):
		push_error("Tried to start game without enough people, or too many people");
		return;
	for peer: String in lob_dict:
		if (lob_dict[peer]["ready"] == false):
			push_error("team isnt ready yet");
			return


	##CALL START GAME RPC AS THE SERVER
	print("did we get here");
	Lobby.load_game.rpc(GlobalConstants.GAME_PATH);



func on_disconnect_pressed() -> void:
	#Setting button_pressed to false will call emit the toggle signal automatically
	ready_button.button_pressed = false;
	#LocalPlayerData.update_dictionary_data("ready", false);
	var err: Error = Lobby.remove_multiplayer_peer();

func on_connection_started() ->void:
	if(!visible):
		return;
	join_lobby_button.disabled = true;
	create_lobby_button.disabled = true;
	disconnect_button.disabled = false;
	ready_button.disabled = false;


func on_connection_ended() -> void:
	if(!visible):
		return;
	join_lobby_button.disabled = false;
	create_lobby_button.disabled = false;
	disconnect_button.disabled = true;
	ready_button.disabled = true;
	start_button.disabled = true;
	connection_status.text = "Status: Not Connected"


func on_create_lobby_pressed()-> Error:
	if(username_edit.text.is_empty()):
		return Error.FAILED
	if(lobby_edit.text.is_empty()):
		return Error.FAILED
	LocalPlayerData.update_dictionary_data(GlobalConstants.USERNAME_KEY, username_edit.text);
	var err: Error = Lobby.create_lobby(lobby_edit.text);

	return err;

func on_join_lobby_pressed()-> Error:
	if(ip_text_box.text.is_empty()):
		return Error.FAILED;
	LocalPlayerData.update_dictionary_data(GlobalConstants.USERNAME_KEY, username_edit.text);
	var err: Error = Lobby.join_lobby(ip_text_box.text);

	return err;
