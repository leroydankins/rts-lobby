extends Area3D
@export var matrix_value: Array[int] = [];
@export var in_use: bool = false;

@export var units: Array[Node3D] = [];


func show_tile() ->void:
	visible = true;

func set_value(p_use: bool) -> void:
	in_use = p_use;
func _ready() -> void:
	area_entered.connect(on_entered);
	body_entered.connect(on_entered);

func on_entered(entity: Node3D) ->void:
	pass;
