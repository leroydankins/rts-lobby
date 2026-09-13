class_name Main
extends Node

###Handles implementation of actual level loading, menu, etc.
@onready var lobby_gui: LobbyGUI = $CanvasLayer/LobbyGUI
@onready var game_holder: Node = $GameHolder
@onready var main_menu: MainMenu = $CanvasLayer/MainMenu
var in_game: bool = false;
@onready var score_screen: ScoreScreen = $CanvasLayer/ScoreScreen
@onready var join_lobby_scene: JoinLobbyScene = $CanvasLayer/JoinLobbyScene
@onready var lobby_screen: LobbyScreen = $CanvasLayer/LobbyScreen

@onready var dc_to_menu_button: Button = $CanvasLayer/GameDCScreen/PanelContainer/CenterContainer/VBoxContainer/DCToMenuButton
@onready var game_dc_screen: Control = $CanvasLayer/GameDCScreen


var game_instance: GameScene;
var _null_var: int;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# subscribe to Lobby autoload for getting signals and events,
	_null_var = Lobby.initialize_game.connect(on_start_game);
	_null_var = Lobby.connection_ended.connect(on_connection_ended);
	_null_var = Lobby.connection_started.connect(on_connected_to_lobby);


	# Connect to menu screen presses
	_null_var = score_screen.lobby_pressed.connect(on_return_to_lobby);
	_null_var = main_menu.play_online_pressed.connect(on_play_online);
	_null_var = main_menu.create_game_pressed.connect(on_create_game);
	_null_var = main_menu.join_game_pressed.connect(on_join_game);



	# Subscribe to each control's return to main signal
	_null_var = lobby_gui.return_main_pressed.connect(on_return_to_main);
	_null_var = score_screen.return_main_pressed.connect(on_return_to_main);
	_null_var = join_lobby_scene.return_main_pressed.connect(on_return_to_main);
	_null_var = lobby_screen.return_main_pressed.connect(on_return_to_main);


	# Return to main menu when we dc from game
	_null_var = dc_to_menu_button.pressed.connect(on_dc_menu_button);



func on_play_online()->void:
	lobby_gui.show();
	main_menu.hide();

func on_create_game() ->void:
	main_menu.hide();
	# currently transition to game_lobby_gui and set it as host
	lobby_screen.show();
	lobby_screen.set_host();
	var _error: Error = Lobby.create_local_lobby();

func on_join_game() ->void:
	main_menu.hide();
	join_lobby_scene.show();

func on_start_game(path: String) ->void:
	lobby_gui.hide();
	lobby_screen.hide();
	lobby_gui.ready_button.toggled.emit(false);
	var packed_game_scene: PackedScene = load(path);
	game_instance = packed_game_scene.instantiate();
	game_instance.score_screen_event.connect(on_score_screen);
	in_game = true;
	game_holder.add_child(game_instance);


func on_connected_to_lobby() ->void:
	if(join_lobby_scene.visible):
		join_lobby_scene.hide();
		lobby_screen.show();
		lobby_screen.set_client()


func on_score_screen() -> void:
	game_instance.score_screen_event.disconnect(on_score_screen);
	#should have sent total game data to score screen already when the game ended?
	#collect player data from match
	var player_dictionary: Dictionary = game_instance.get_player_data();

	#collect time history of units, money, supply, buildings
	var _player_history: Dictionary = game_instance.get_player_history();

	#save the game to local file
	var _cmd_array: Dictionary = game_instance.get_cmd_array();

	#var _replay: Replay = game_instance.get_game_replay(); ?

	#save the replay to whatever lol
	score_screen.populate_score_screen(player_dictionary);
	in_game = false;
	game_instance.queue_free();
	score_screen.show();

## Called whenever a menu screen emits return to main, disconnects from any online lobbies and hides all possible menu screens except [MainMenu]
func on_return_to_main()->void:
	var _err: Error = Lobby.end_lobby();
	lobby_gui.hide();
	score_screen.hide();
	lobby_screen.hide();
	join_lobby_scene.hide();
	main_menu.show();

func on_return_to_lobby() -> void:
	score_screen.hide();
	lobby_gui.show();

func on_connection_ended() -> void:
	if(in_game):
		push_error("Lost connection to server, pausing scene and waiting until reconnected")
		game_holder.process_mode = Node.PROCESS_MODE_DISABLED;
		game_dc_screen.show();


func on_dc_menu_button() ->void:
	game_dc_screen.hide();
	in_game = false;
	game_instance.queue_free();
	main_menu.show();
