
extends Node

###Handles implementation of actual level loading, menu, etc.
@onready var lobby_gui: LobbyGUI = $CanvasLayer/LobbyGUI
@onready var game_holder: Node = $GameHolder
@onready var main_menu: MainMenu = $CanvasLayer/MainMenu
var in_game: bool = false;
@onready var score_screen: ScoreScreen = $CanvasLayer/ScoreScreen

var game_instance: GameScene;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#subscribe to Lobby autoload for getting signals and events,
	Lobby.initialize_game.connect(on_start_game);
	Lobby.connection_ended.connect(on_connection_ended);
	score_screen.lobby_pressed.connect(on_return_to_lobby);
	main_menu.play_online_pressed.connect(on_play_online);
	lobby_gui.return_main_pressed.connect(on_return_to_main);
	score_screen.return_main_pressed.connect(on_return_to_main);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_play_online()->void:
	lobby_gui.show();
	main_menu.hide();

func on_start_game(path: String) ->void:
	lobby_gui.hide();
	lobby_gui.ready_button.toggled.emit(false);
	var packed_game_scene: PackedScene = load(path);
	game_instance = packed_game_scene.instantiate();
	game_instance.score_screen_event.connect(on_score_screen);
	in_game = true;
	game_holder.add_child(game_instance);
	pass;

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

func on_return_to_main()->void:
	var _err: Error = Lobby.remove_multiplayer_peer();
	lobby_gui.hide();
	score_screen.hide();
	main_menu.show();

func on_return_to_lobby() -> void:
	score_screen.hide();
	lobby_gui.show();

func on_connection_ended() -> void:
	if(in_game):
		push_error("Lost connection to server, pausing scene and waiting until reconnected")
		game_holder.process_mode = Node.PROCESS_MODE_DISABLED;
