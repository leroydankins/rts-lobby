class_name ScoreScreen;
extends Control

signal return_main_pressed();
signal lobby_pressed();

@onready var main_menu_button: Button = $MainMenuButton
@onready var lobby_button: Button = $LobbyButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_button.pressed.connect(on_main);
	lobby_button.pressed.connect(on_lobby);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_main() ->void:
	return_main_pressed.emit();
	pass;

func on_lobby() ->void:
	lobby_pressed.emit();
	pass;

#placeholder functions
func populate_score_screen(player_dictionary: Dictionary) -> void:
	for player: int in player_dictionary:
		#populate each data point with relevant data
		#will need to keep all data points in arrays for making the graphs show
		pass;
