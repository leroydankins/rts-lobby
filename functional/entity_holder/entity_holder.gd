class_name EntityHolder
extends Node3D

var entity_array: Array[Node3D] = [];
var unit_array: Array[Node3D] = [];
var building_array: Array[Node3D] = [];
var resource_array: Array[Node3D] = [];
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entities: Array[Node] = get_children();
	for entity: Node3D in entities:
		entity_array.append(entity);
		if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
			unit_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
			building_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
			resource_array.append(entity);
	print("we have %s many entities in the scene" % entity_array.size());
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func register_entity(entity: Node3D) -> void:
	entity_array.append(entity);
	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
		unit_array.append(entity);
	elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
		building_array.append(entity);
	add_child(entity);

func scrub_lists() ->void:
	pass;
