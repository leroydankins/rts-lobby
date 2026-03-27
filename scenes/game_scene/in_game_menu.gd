class_name InGameMenu
extends Control

signal resume_pressed();
signal score_screen_pressed();
signal return_to_game_pressed();
signal quit_pressed();
signal options_pressed();

#end game buttons
@onready var return_to_game: Button = $MenuContainer/VBoxContainer/ReturnContainer/ReturnToGame
@onready var score_screen: Button = $MenuContainer/VBoxContainer/ScoreContainer/ScoreScreen
@onready var options: Button = $MenuContainer/VBoxContainer/OptionsContainer/Options

#pause buttons
@onready var resume_game: Button = $MenuContainer/VBoxContainer/ResumeContainer/ResumeGame
@onready var quit_game: Button = $MenuContainer/VBoxContainer/QuitContainer/QuitGame

@onready var result_label: Label = $MenuContainer/VBoxContainer/ResultLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide();
	#To discard the returned int rn 3/20
	var _null_var: int;
	_null_var = return_to_game.pressed.connect(on_return);
	_null_var = score_screen.pressed.connect(on_score);
	_null_var = options.pressed.connect(on_options);
	_null_var = resume_game.pressed.connect(on_resume);
	_null_var = quit_game.pressed.connect(on_quit);

func on_return() -> void:
	return_to_game_pressed.emit();


func on_score() -> void:
	score_screen_pressed.emit();


func on_options() -> void:
	score_screen_pressed.emit();


func on_resume() -> void:
	resume_pressed.emit();


func on_quit() -> void:
	quit_pressed.emit();


#Gets called externally by game scene
func show_victory() -> void:
	result_label.show();
	result_label.text = "Victory!";
	#hide pause menu buttons
	resume_game.hide();
	quit_game.hide();

#Gets called externally by game scene
func show_defeat() -> void:
	result_label.show();
	result_label.text = "Defeat!"
	#hide pause menu buttons
	resume_game.hide();
	quit_game.hide();
	#show finished game buttons



#Gets called externally by game scene
func toggle_menu() -> void:
	if(is_visible()):
		visible = false;
	#if solo game, we are also pausing the world but it will be handled in game script?
	#we dont pause if its multiplayer (most of this game is about multiplayer so
	pass;
