class_name CmdGUI
extends Control

signal command_pressed(cmd_mnemonic: String);


@onready var texture_rect: TextureRect = $TextureRect
@onready var button: Button = $Button
@onready var label: Label = $Label

var cmd_int: int;
var cmd_mnemonic: String = "";
var cmd_name: String = "";
var cmd_description: String = "";
var build_time: int;
var sprite_path: String = "";
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _null_var : int = button.pressed.connect(on_button);
	texture_rect.hide();
	button.disabled = true;
	label.hide();
	pass # Replace with function body.

func update_data(cmd_dict: Dictionary) -> void:
	cmd_mnemonic = cmd_dict["mnemonic"];
	cmd_name = cmd_dict["name"];
	cmd_description = cmd_dict["description"];
	sprite_path = cmd_dict["sprite_path"];
	if !sprite_path.is_empty():
		var texture: Texture2D = load(sprite_path);
		texture_rect.texture = texture;
		texture_rect.show();
	else:
		label.text = cmd_name;
		label.show();
	button.disabled = false;

	pass;
func clear_data() -> void:
	cmd_name = "";
	cmd_description = "";
	build_time = 0;
	sprite_path = "";
	label.hide();
	button.disabled = true;
	texture_rect.hide();

func on_button() -> void:
	print("button")
	if (cmd_mnemonic.is_empty()):
		return;
	command_pressed.emit(cmd_mnemonic);
