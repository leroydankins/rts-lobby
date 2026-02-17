
extends Node

###Handles implementation of actual level loading, menu, etc.
@onready var lobby_gui: Control = $CanvasLayer/LobbyGUI
@onready var game_holder: Node = $GameHolder
var in_game: bool = false;


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
	var game_scene: PackedScene = load(path);
	var game_instance: Node3D = game_scene.instantiate();
	in_game = true;
	game_holder.add_child(game_instance);
	pass;



func on_connection_ended() -> void:
	if(in_game):
		push_error("Lost connection to server, pausing scene and waiting until reconnected")
		game_holder.process_mode = Node.PROCESS_MODE_DISABLED;
