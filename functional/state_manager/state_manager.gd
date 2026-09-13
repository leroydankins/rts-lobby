@icon("res://assets/class_icons/dwarf_worker/dwarf_worker.png")
class_name StateManager
extends Node
## Referenced by game_scene.gd, in_game_menu.gd, and command_controller.gd


var _is_in_menu: bool = false;

func set_in_menu(value: bool) ->void:
	_is_in_menu = value;

func is_in_menu() -> bool:
	return _is_in_menu;
