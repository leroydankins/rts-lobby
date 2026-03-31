class_name MainMenu
extends Control
signal play_ai_pressed();
signal play_online_pressed();
signal options_pressed();
signal tutorial_pressed()

@export var play_ai: Button;
@export var play_online: Button;
@export var options: Button;
@export var tutorial: Button;


func _ready() ->void:
	play_ai.pressed.connect(on_play_ai);
	play_online.pressed.connect(on_play_online);
	options.pressed.connect(on_options);
	tutorial.pressed.connect(on_tutorial);
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
