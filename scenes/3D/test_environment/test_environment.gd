extends Node3D

@onready var game: GameScene = $GameScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player_dictionary: Dictionary[String, Variant] = {
	"player_id" = str(1),
	"player_username" = "test_user",
	"player_race" = 0,
	"player_team" = 0,
	"player_resource" = 20000,
	"player_gas" = 500
	}
	game.player_game_dict["1"] = player_dictionary;
	game.local_game_dict = player_dictionary;
	game.start_game.rpc();
