class_name MainMenu
extends Control
signal play_ai_pressed();
signal play_online_pressed();
signal options_pressed();
signal tutorial_pressed();
## Reworking play online button to create game, lobby_gui will be agnostic to online or offline
signal create_game_pressed();
## This will be used to join an online game [br][br]
## Search tree will show up for searching for a lobby already created
signal join_game_pressed();



@export var play_ai: Button;
@export var play_online: Button;
@export var options: Button;
@export var tutorial: Button;

var _null_var : int 

func _ready() ->void:
	_null_var = play_ai.pressed.connect(on_play_ai);
	_null_var = play_online.pressed.connect(on_play_online);
	_null_var = options.pressed.connect(on_options);
	_null_var = tutorial.pressed.connect(on_tutorial);
	pass;

func on_play_ai()->void:
	play_ai_pressed.emit();
	pass;
func on_play_online()->void:
	play_online_pressed.emit();
	pass;
func on_options()->void:
	options_pressed.emit();
	pass;
func on_tutorial()->void:
	tutorial_pressed.emit();
	pass;

func on_create_game()->void:
	create_game_pressed.emit();
	pass;
func on_join_game() ->void:
	join_game_pressed.emit();
