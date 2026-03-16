extends Node
var master_control: bool = false;

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("master_control"):
		if(!master_control):
			master_control = true;
		else:
			master_control = false;
