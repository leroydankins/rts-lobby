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
			building_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
			unit_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
			resource_array.append(entity);



@rpc("authority", "call_local", "reliable")
func instantiate_entity(spawn_dict: Dictionary, cmd: Dictionary) -> void:
	var entity: Node3D = load(spawn_dict["file_path"]).instantiate();
	entity.team = spawn_dict["team"];
	entity.player_id = spawn_dict["player_id"];
	#color is an int, the object will access the actual color via GlobalConstants
	entity.color = spawn_dict["color"];
	if(spawn_dict.has("resource_depot") && "resource_depot" in entity):
		var depot_path: String = spawn_dict["resource_depot"];
		var depot: Node3D = get_tree().root.get_node(depot_path);
		entity.resource_depot = depot
	register_entity(entity);
	entity.global_position = spawn_dict["position"];
	##We need to create a controller that this command goes through if its NOT the command controller, for command logging
	if(multiplayer.is_server()):
		entity.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	return

@rpc("authority", "call_local", "reliable")
func register_entity(entity: Node3D) -> void:
	entity_array.append(entity);
	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
		building_array.append(entity);
	elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
		unit_array.append(entity);
	add_child(entity);

@rpc("authority", "call_local", "reliable")
func remove_entity(entity_path: String) -> void:
	var entity: Node3D = get_tree().root.get_node(entity_path);
	for i: int in range(entity_array.size()-1,-1, -1):
		if (entity == entity_array[i]):
			entity_array.remove_at(i);
		pass;
	match entity.ENTITY_TYPE:
		GlobalConstants.EntityType.UNIT:
			for i: int in range(unit_array.size()-1,-1, -1):
				if (entity == unit_array[i]):
					unit_array.remove_at(i);
		GlobalConstants.EntityType.BUILDING:
			for i: int in range(building_array.size()-1,-1, -1):
				if (entity == building_array[i]):
					building_array.remove_at(i);
	remove_child(entity);



func scrub_lists() ->void:
	pass;
