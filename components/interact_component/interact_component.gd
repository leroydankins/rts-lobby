class_name InteractComponent
extends Area3D
signal entity_exit(entity: Node3D);
signal entity_enter(entity: Node3D);
@onready var col: CollisionShape3D = $CollisionShape3D
@export var interact_range: float = 1;
var interactable_array: Array = [];

func _ready() ->void:
	col.shape.radius = interact_range;
	body_entered.connect(on_entered);
	area_entered.connect(on_entered);
	body_exited.connect(on_exited);
	area_exited.connect(on_exited);

func on_entered(body: Node3D) ->void:
	if(!is_multiplayer_authority()):
		return
	#should always be something interactable because its my god damn setting!
	interactable_array.append(body);
	entity_enter.emit(body);



func on_exited(body: Node3D) ->void:
	if(!is_multiplayer_authority()):
		return
	for i: int in interactable_array.size():
		if interactable_array[i] == body:
			interactable_array.remove_at(i);
			break;
	entity_exit.emit(body);
