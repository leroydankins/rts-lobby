class_name CmdGUI
extends Control

signal command_pressed(cmd: Dictionary);


@onready var texture_rect: TextureRect = $TextureRect
@onready var button: Button = $Button
@onready var label: Label = $Label

var cmd_dict: Dictionary = {};



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _null_var : int = button.pressed.connect(on_button);
	texture_rect.hide();
	button.disabled = true;
	label.hide();
	pass # Replace with function body.

func update_data(p_cmd_dict: Dictionary) -> void:
	cmd_dict = p_cmd_dict.duplicate();
	if cmd_dict.has("sprite_path"):
		var texture: Texture2D = load(cmd_dict["sprite_path"]);
		texture_rect.texture = texture;
		texture_rect.show();
	else:
		label.text = cmd_dict["name"];
		label.show();
	button.disabled = false;

	pass;
func clear_data() -> void:
	cmd_dict.clear();
	label.hide();
	button.disabled = true;
	texture_rect.hide();

func on_button() -> void:
	print("button")
	if (cmd_dict.is_empty() || !cmd_dict.has("mnemonic")):
		return;
	command_pressed.emit(cmd_dict);
