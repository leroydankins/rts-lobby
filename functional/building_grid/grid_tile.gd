extends MeshInstance3D

@export var matrix_value: Array[int] = [];
@export var in_use: bool = false;



func show_tile() ->void:
	visible = true;

func set_value(p_use: bool) -> void:
	in_use = p_use;
