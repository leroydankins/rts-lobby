
extends Node

###Handles implementation of actual level loading, menu, etc.
@onready var lobby_gui: Control = $CanvasLayer/LobbyGUI
@onready var game_holder: Node = $GameHolder
var in_game: bool = false;
@onready var score_screen: ScoreScreen = $CanvasLayer/ScoreScreen

var game_instance: GameScene;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#subscribe to Lobby autoload for getting signals and events,
	Lobby.initialize_game.connect(on_start_game);
	Lobby.connection_ended.connect(on_connection_ended);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_start_game(path: String) ->void:
	lobby_gui.hide();
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
	game_instance.queue_free();
	score_screen.show();


func on_connection_ended() -> void:
	if(in_game):
		push_error("Lost connection to server, pausing scene and waiting until reconnected")
		game_holder.process_mode = Node.PROCESS_MODE_DISABLED;
