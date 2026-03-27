class_name EntityHolder
extends Node3D

var global_entity_array: Array[Node3D] = [];
var global_unit_array: Array[Node3D] = [];
var global_building_array: Array[Node3D] = [];
var global_resource_array: Array[Node3D] = [];
var player_arr: Dictionary[int, Dictionary] = {};

var player_data_manager: PlayerDataManager;

#ENTITY HOLDER WILL KEEP ARRAYS OF ALL THE PLAYERS UNITS, WE WILL ADD THEM TO GROUPS AND ITERATE THROUGH GROUPS TO GET SUPPLY
#WE WILL THEN UPDATE THIS INFORMATION BY SAYING INDIVIDUAL PLAYER NOW HAS BLANK SUPPLY 3/23
#we need to have a dictionary for each player that details the team, units, supply, etc

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_data_manager = get_tree().get_first_node_in_group("PlayerDataManager")
	var entities: Array[Node] = get_children();
	for entity: Node3D in entities:
		global_entity_array.append(entity);
		if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
			global_building_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
			global_unit_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
			global_resource_array.append(entity);

	pass;


@rpc("authority", "call_local", "reliable")
func instantiate_entity(spawn_dict: Dictionary, cmd: Dictionary) -> void: #Called in most scenarios, only builders need direct access to node for building
	var entity: Node3D = load(spawn_dict["file_path"]).instantiate();
	entity.team = spawn_dict["team"];
	#color is an int, the object will access the actual color via GlobalConstants
	entity.color = spawn_dict["color"];

	if(spawn_dict.has("resource_depot") && "resource_depot" in entity):
		var depot_path: String = spawn_dict["resource_depot"];
		var depot: Node3D = get_tree().root.get_node(depot_path);
		entity.resource_depot = depot

	register_entity(entity);
	entity.global_position = spawn_dict["position"];
	entity.global_position.y += entity.ENTITY_HEIGHT_OFFSET;

	##We need to create a controller that this command goes through if its NOT the command controller, for command logging
	if(multiplayer.is_server()):
		if(cmd.is_empty()):
			return;
		entity.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	return

@rpc("authority", "call_local", "reliable")
func register_entity(entity: Node3D) -> void:
	global_entity_array.append(entity);
	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
		global_building_array.append(entity);
		player_arr[entity.color]["buildings"].append(entity);
	elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
		global_unit_array.append(entity);
		player_arr[entity.color]["units"].append(entity);
	add_child(entity);

@rpc("authority", "call_local", "reliable")
func remove_entity(entity_path: String) -> void:
	var entity: Node3D = get_tree().root.get_node(entity_path);
	var ent_color: int = entity.color;
	for i: int in range(global_entity_array.size()-1,-1, -1):
		if (entity == global_entity_array[i]):
			global_entity_array.remove_at(i);
			break;
		pass;
	match entity.ENTITY_TYPE:
		GlobalConstants.EntityType.UNIT:
			for i: int in range(global_unit_array.size()-1,-1, -1):
				if (entity == global_unit_array[i]):
					global_unit_array.remove_at(i);
					break;
			for i:int in range(player_arr[ent_color]["units"].size()-1,-1,-1):
				if(entity == player_arr[ent_color]["units"][i]):
					player_arr[ent_color]["units"].remove_at(i);
					break;
		GlobalConstants.EntityType.BUILDING:
			for i: int in range(global_building_array.size()-1,-1, -1):
				if (entity == global_building_array[i]):
					global_building_array.remove_at(i);
					break;
			for i:int in range(player_arr[ent_color]["buildings"].size()-1,-1,-1):
				if(entity == player_arr[ent_color]["buildings"][i]):
					player_arr[ent_color]["buildings"].remove_at(i);
					break;
			#check to see if that was the last building and end game
			if(multiplayer.is_server()):
				if(player_arr[ent_color]["buildings"].is_empty()):
					print("we know we are out of buildings?");
					player_data_manager.player_lost.rpc(ent_color);
	remove_child(entity);

@rpc("authority", "call_local", "reliable")
func initialize_player_arr(players: Array[int]) ->void:
	for player: int in players:
		var dict: Dictionary = {
			"units" = [],
			"buildings" = [],
		}
		player_arr[player] = dict;
		#for each unit in the scene already, if they have the same color as player_arr key, then add them

func scrub_lists() ->void:
	pass;
