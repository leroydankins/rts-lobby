extends Control
@onready var create_lobby_button: Button = $HostData/HostBox/CreateLobbyButton
@onready var username_edit: TextEdit = $LoginData/LoginBox/HBoxContainer/UsernameEdit
@onready var lobby_edit: TextEdit = $HostData/HostBox/HBoxContainer/LobbyEdit

@onready var join_lobby_button: Button = $JoinData/JoinBox/JoinLobbyButton
@onready var ip_text_box: TextEdit = $JoinData/JoinBox/HBoxContainer2/IPTextBox

@onready var lobby_data: Control = $LobbyData
@onready var lobby_label: Label = $LobbyData/LobbyBox/LobbyLabel
@onready var lobby_player_count: Label = $LobbyData/LobbyBox/LobbyPlayerCount

var peer_labels: Array[Label];

@onready var peer_1_name: Label = $LobbyData/LobbyBox/Peer1Name
@onready var peer_2_name: Label = $LobbyData/LobbyBox/Peer2Name
@onready var peer_3_name: Label = $LobbyData/LobbyBox/Peer3Name
@onready var peer_4_name: Label = $LobbyData/LobbyBox/Peer4Name

var in_lobby: bool = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	peer_labels = [peer_1_name, peer_2_name, peer_3_name, peer_4_name];
	Lobby.data_updated.connect(on_lobby_update);
	create_lobby_button.pressed.connect(on_create_lobby);
	join_lobby_button.pressed.connect(on_join_lobby);
	pass # Replace with function body.

func on_lobby_update() -> void:
	var dict_size: int = Lobby.lobby_player_dictionary.size();
	var players_arr: Array[Dictionary] = Lobby.lobby_player_dictionary.values();
	lobby_label.text = "Lobby: %s" % Lobby.lobby_name;
	lobby_player_count.text = " %s / %s Players Connected" % [dict_size, str(Lobby.MAX_CONNECTIONS)];
	for i: int in peer_labels.size():
		if (i < dict_size):
			peer_labels[i].text = "Peer %s: %s" % [i+1,players_arr[i]["username"]];
		else:
			peer_labels[i].text = "Peer %s: Not Connected" % [i+1];



func on_create_lobby()-> Error:
	if(username_edit.text.is_empty()):
		return Error.FAILED
	if(lobby_edit.text.is_empty()):
		return Error.FAILED

	LocalPlayerData.local_player["username"] = username_edit.text;
	var err: Error = Lobby.create_game(lobby_edit.text);
	if err == Error.OK:
		in_lobby = true;
	return err;

func on_join_lobby()-> Error:
	if(ip_text_box.text.is_empty()):
		return Error.FAILED;
	LocalPlayerData.local_player["username"] = username_edit.text;
	var err: Error = Lobby.join_game(ip_text_box.text);
	if err == Error.OK:
		in_lobby = true;
	return err;
