extends Resource
var _is_in_menu: bool = false;

func set_in_menu(value: bool) ->void:
	_is_in_menu = value;

func is_in_menu() -> bool:
	return _is_in_menu;
