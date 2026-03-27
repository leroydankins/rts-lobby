class_name AggroComponent
extends Area3D
signal aggrod(enemy: Node3D);

@onready var parent: Node3D = get_parent();
@onready var col: CollisionShape3D = $CollisionShape3D
@export var aggro_range: int;
@export var can_aggro: bool = false;
@export var auto_aggro: bool = true;
var enemy_array: Array[Node3D] = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	col.shape.radius = aggro_range;
	area_entered.connect(on_aggro_entered);
	body_entered.connect(on_aggro_entered);
	area_exited.connect(on_aggro_exited);
	body_exited.connect(on_aggro_exited);
	if(auto_aggro):
		can_aggro = true;
	pass # Replace with function body.

func on_aggro_entered(entity: Node3D) ->void:
	if(entity.team == parent.team):
		return;
	enemy_array.append(entity);


func on_aggro_exited(entity: Node3D) ->void:
	if(entity.team == parent.team):
		return;
	for i: int in enemy_array.size():
		if (entity == enemy_array[i]):
			enemy_array.remove_at(i);
			break;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(can_aggro):
		if (!enemy_array.is_empty()):
			print(can_aggro)
			aggrod.emit(enemy_array[0])
	pass
