extends Node3D

@onready var game: GameScene = $GameScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game.player_resource = 2000;
	game.player_gas = 1000;
	var player_dictionary: Dictionary[String, Variant] = {
	"username" = "test_user",
	"ready" = true,
	"team" = 0,
	"color" = 0,
	"race" = 0,
	#"player_id" = str(1),
	#"player_username" = "test_user",
	#"player_race" = 0,
	#"player_team" = 0,
	#"player_resource" = 20000,
	#"player_gas" = 500,
	#"player_color" = 0,
	}
	Lobby.lobby_player_dictionary[str(1)] = player_dictionary
	game.on_start();
	#game.player_game_dict["1"] = player_dictionary;
	#game.local_id = str(1);
	#game.start_game.rpc();
