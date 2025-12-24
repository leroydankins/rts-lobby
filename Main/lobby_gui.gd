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


#Lobby Status Vars
@onready var lobby_label: Label = $LobbyData/LobbyBox/LobbyLabel
@onready var connection_status: Label = $LobbyData/LobbyBox/ConnectionStatus

var peer_labels: Array[Label];
@onready var peer_1_name: Label = $LobbyData/LobbyBox/Peer1Name
@onready var peer_2_name: Label = $LobbyData/LobbyBox/Peer2Name
@onready var peer_3_name: Label = $LobbyData/LobbyBox/Peer3Name
@onready var peer_4_name: Label = $LobbyData/LobbyBox/Peer4Name



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	peer_labels = [peer_1_name, peer_2_name, peer_3_name, peer_4_name];
	Lobby.data_updated.connect(on_lobby_update);
	Lobby.connection_ended.connect(on_connection_ended);
	Lobby.connection_started.connect(on_connection_started);
	create_lobby_button.pressed.connect(on_create_lobby_pressed);
	join_lobby_button.pressed.connect(on_join_lobby_pressed);
	disconnect_button.pressed.connect(on_disconnect_pressed);
	start_button.pressed.connect(on_start_pressed);
	ready_button.toggled.connect(on_ready_toggled);


func on_lobby_update() -> void:
	#Lobby Name
	lobby_label.text = "Lobby: %s" % Lobby.lobby_name;
	if (!Lobby.is_connected):
		connection_status.text = "Status: Not Connected"
		for i: int in peer_labels.size():
			peer_labels[i].text = "Peer %s" % [i+1];

	else:
		connection_status.text = "Status: Connected"
		var dict_size: int = Lobby.lobby_player_dictionary.size();
		var players_arr: Array[Dictionary] = Lobby.lobby_player_dictionary.values();
		for i: int in peer_labels.size():
			if (i < dict_size):
				peer_labels[i].text = "Peer %s: %s" % [i+1,players_arr[i]["username"]];
			else:
				peer_labels[i].text = "Peer %s: Empty" % [i+1];

func on_ready_toggled(toggle: bool) -> void:
	if (toggle):
		LocalPlayerData.update_dictionary_data("ready", true)
		print("readied up");
	else:
		LocalPlayerData.update_dictionary_data("ready", false)
		print("unreadied up");

func on_start_pressed() -> void:
	if !Lobby.multiplayer.is_server():
		return;
	var lob_dict: Dictionary[String, Variant] = Lobby.lobby_player_dictionary;
	if (Lobby.lobby_player_dictionary.size() <= 1 || Lobby.lobby_player_dictionary.size() > Lobby.MAX_CONNECTIONS):
		push_error("Tried to start game without enough people, or too many people");
		return;
	for peer: String in lob_dict:
		if (lob_dict[peer]["ready"] == false):
			push_error("team isnt ready yet");
			return
	##CALL START GAME RPC

func on_disconnect_pressed() -> void:
	var err: Error = Lobby.remove_multiplayer_peer();

func on_connection_started() ->void:
	if(!visible):
		return;
	join_lobby_button.disabled = true;
	create_lobby_button.disabled = true;
	disconnect_button.disabled = false;
	ready_button.disabled = false;
	if(Lobby.multiplayer.is_server()):
		start_button.disabled = false;


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
	LocalPlayerData.update_dictionary_data("username", username_edit.text);
	var err: Error = Lobby.create_game(lobby_edit.text);

	return err;

func on_join_lobby_pressed()-> Error:
	if(ip_text_box.text.is_empty()):
		return Error.FAILED;
	LocalPlayerData.local_player["username"] = username_edit.text;
	var err: Error = Lobby.join_game(ip_text_box.text);

	return err;
