extends PanelContainer

const MAX_PLAYERS: int = 4;

###THIS IS JUST INFORMATION DURING DEVELOPMENT
###This will not be visible option in gameplay :/
@onready var p1_box: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var p1_color: ColorRect = $VBoxContainer/HBoxContainer/ColorRect
@onready var p1_label: Label = $VBoxContainer/HBoxContainer/Label
@onready var p2_box: HBoxContainer = $VBoxContainer/HBoxContainer2
@onready var p2_color: ColorRect = $VBoxContainer/HBoxContainer2/ColorRect
@onready var p2_label: Label = $VBoxContainer/HBoxContainer2/Label
@onready var p3_box: HBoxContainer = $VBoxContainer/HBoxContainer3
@onready var p3_color: ColorRect = $VBoxContainer/HBoxContainer3/ColorRect
@onready var p3_label: Label = $VBoxContainer/HBoxContainer3/Label
@onready var p4_box: HBoxContainer = $VBoxContainer/HBoxContainer4
@onready var p4_color: ColorRect = $VBoxContainer/HBoxContainer4/ColorRect
@onready var p4_label: Label = $VBoxContainer/HBoxContainer4/Label

var p1_username: String = "";
var p2_username: String = "";
var p3_username: String = "";
var p4_username: String = "";



var game: Game;
@onready var text_arr : Array[Control] = [p1_label, p2_label, p3_label, p4_label];
@onready var box_arr : Array[Control] = [p1_box, p2_box, p3_box, p4_box]
@onready var username_arr : Array[String] = [p1_username,  p2_username, p3_username, p4_username];
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	if event.is_action_released("tab"):
		if(!visible):
			show();
			var i: int = 0;
			for key: String in game.player_game_dict:
				print(key);
				box_arr[i].show();
				username_arr[i] = game.player_game_dict[key][Game.PLAYER_USERNAME_KEY]
				i += 1;
		else:
			hide();



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!visible):
		return;
	if (game == null):
		return;
	var i: int = 0;
	for key: String in game.player_game_dict:
		if(i >= MAX_PLAYERS):
			return;
		if(text_arr[i].is_visible_in_tree()):
			var min: int = game.player_game_dict[key][Game.PLAYER_RESOURCE_KEY];
			var gas: int = game.player_game_dict[key][Game.PLAYER_GAS_KEY];
			text_arr[i].text = "%s: min: %s gas: %s" % [username_arr[i], str(min), str(gas)]
			i += 1;
	while (i < MAX_PLAYERS):
		box_arr[i].hide();
		i+= 1;
