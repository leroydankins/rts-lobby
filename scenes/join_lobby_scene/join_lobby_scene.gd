class_name JoinLobbyScene
extends Control
## This signals to Main to hide the LobbyGUI and show the MainMenu control node
signal return_main_pressed();


@onready var username_edit: TextEdit = $JoinData/MarginContainer/JoinBox/HBoxContainer/UsernameEdit

@onready var ip_text_box: TextEdit = $JoinData/MarginContainer/JoinBox/IPBox/IPTextBox
@onready var ip_password_text_box: TextEdit = $JoinData/MarginContainer/JoinBox/IPPasswordBox/PasswordTextBox
@onready var by_ip_join_button: Button = $JoinData/MarginContainer/JoinBox/ByIPJoinButton

@onready var id_label: Label = $JoinData/MarginContainer/JoinBox/UniqueIDBox/IDLabel
@onready var password_text_box: TextEdit = $JoinData/MarginContainer/JoinBox/PasswordBox/PasswordTextBox
@onready var by_id_join_button: Button = $JoinData/MarginContainer/JoinBox/JoinLobbyButton

@onready var return_to_main_button: Button = $ReturnToMain


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _null: int = by_ip_join_button.pressed.connect(on_ip_join);
	_null = return_to_main_button.pressed.connect(on_return_to_main);
	_null = Lobby.connection_ended.connect(on_connection_ended);
	pass # Replace with function body.

## We press join but do not transition the scene from this method, we must wait until we connect to the server
func on_ip_join() ->void:
	if(ip_text_box.text.is_empty()):
		return;
	## This updates our local player id that always has a player, and will send updates if we are connected online
	LocalPlayerData.update_dictionary_data(GlobalConstants.USERNAME_KEY, username_edit.text);
	# Cannot check if we are connected here since it takes time to connect
	var err: Error = Lobby.join_lobby(ip_text_box.text);
	if(err != Error.OK):
		push_error("Unable to cnnect when joining, likely wrong address or internet issue? idk do a switch case for this")
	else:
		by_ip_join_button.disabled = true;


func on_return_to_main() ->void:
	return_main_pressed.emit();

#Re enable join game options when the connection is disconnected (or connection fails)
func on_connection_ended() ->void:
	by_ip_join_button.disabled = false;
