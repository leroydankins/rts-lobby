class_name CmdGUI
extends Control

signal command_pressed(cmd: Dictionary);

var game: GameScene
@onready var texture_rect: TextureRect = $TextureRect
@onready var button: Button = $Button
@onready var command_label: Label = $CommandInfoContainer/VBoxContainer/CommandLabel
@onready var cost_label: Label = $CommandInfoContainer/VBoxContainer/CostLabel
@onready var command_info_container: PanelContainer = $CommandInfoContainer
@onready var hover_timer: Timer = $HoverTimer
@onready var hotkey_label: Label = $HotkeyContainer/HotkeyLabel
@onready var hotkey_container: PanelContainer = $HotkeyContainer

var cmd_dict: Dictionary = {};
#Mineral, gas
var cost: Array = [];


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#may want to rework this to not have every single freaking node reference the game scene fuckin hell dude
	game = get_tree().get_first_node_in_group("Game")
	var _null_var : int = button.pressed.connect(on_button);
	texture_rect.hide();
	button.disabled = true;
	hotkey_container.hide();
	command_info_container.hide();
	mouse_entered.connect(on_mouse_enter);
	mouse_exited.connect(on_mouse_exit);
	hover_timer.timeout.connect(on_hover_timeout);
	pass # Replace with function body.

func _process(_delta: float) ->void:
	if(!cost.is_empty()):
		var resources: Array = [game.local_game_dict[game.PLAYER_RESOURCE_KEY], game.local_game_dict[game.PLAYER_GAS_KEY]];
		if (cost[0] > resources[0] || cost[1] > resources[1]):
			button.disabled = true;
		else:
			button.disabled = false;

func update_data(p_cmd_dict: Dictionary) -> void:
	cmd_dict = p_cmd_dict
	if cmd_dict.has("sprite_path"):
		var texture: Texture2D = load(cmd_dict["sprite_path"]);
		texture_rect.texture = texture;
		texture_rect.show();
	if(cmd_dict.has("hotkey")):
		hotkey_label.text = "[%s]" % cmd_dict["hotkey"];
		hotkey_container.show();
	if(cmd_dict.has("cost")):
		cost = cmd_dict["cost"];
	else:
		cost = [];
	var desc: String = cmd_dict["description"];
	command_label.text = desc;
	button.disabled = false;

func clear_data() -> void:
	cmd_dict = {};
	cost = [];
	hotkey_container.hide();
	hotkey_label.text = "";
	command_info_container.hide();
	command_label.text = "";
	button.disabled = true;
	texture_rect.hide();

func _input(event: InputEvent) -> void:
	if(button.disabled == true):
		return;
	if (cmd_dict.is_empty() || !cmd_dict.has("hotkey")):
		return;
	if(event.is_action_pressed(cmd_dict["hotkey"])):
		command_pressed.emit(cmd_dict);
		get_viewport().set_input_as_handled();
		return;

func on_hover_timeout() ->void:
	command_info_container.show();

func on_mouse_enter() ->void:
	hover_timer.start();

func on_mouse_exit() ->void:
	hover_timer.stop();
	command_info_container.hide();

func on_button() -> void:
	if (cmd_dict.is_empty()):
		return;
	command_pressed.emit(cmd_dict);
