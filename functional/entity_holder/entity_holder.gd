class_name EntityHolder
extends Node3D

signal player_lost(player_id: int);

@export var map_grid:  MapGrid;

var global_entity_array: Array[Node3D] = [];
var global_unit_array: Array[Node3D] = [];
##
var global_building_array: Array[Node3D] = [];
## Dictionary holding the following information: [br][br]
## [code] scene_path [/code] :   Building's location on MapGrid  in the following Array [br][br]
## Array Data : [br][br]
## [code] x_start [/code] :    Starting X Tile in MapGrid [br]
## [code] z_start [/code] :    Starting Z Tile in MapGrid [br]
## [code] x_size [/code] :     Length of Tiles in X Direction on MapGrid [br]
## [code] z_size [/code] :     Length of Tiles in Z Direction on MapGrid [br]
var building_dictionary: Dictionary[String, Array] = {};
## Not sure
var global_resource_array: Array[Node3D] = [];
## TBD
var player_arr: Dictionary[int, Dictionary] = {};


#ENTITY HOLDER WILL KEEP ARRAYS OF ALL THE PLAYERS UNITS, WE WILL ADD THEM TO GROUPS AND ITERATE THROUGH GROUPS TO GET SUPPLY
#WE WILL THEN UPDATE THIS INFORMATION BY SAYING INDIVIDUAL PLAYER NOW HAS BLANK SUPPLY 3/23
#we need to have a dictionary for each player that details the team, units, supply, etc

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var entities: Array[Node] = get_children();
	for entity: Node3D in entities:
		global_entity_array.append(entity);
		if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
			global_building_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
			global_unit_array.append(entity);
		elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
			global_resource_array.append(entity);

## Request to instantiate building called by client RPC [br]
## Called by requesting client (possibly already authority) [br][br]
## Validates the command has requisite data and the tiles are available for placement
## Calls [method instantiate_building] as an RPC
@rpc("any_peer","call_local","reliable")
func request_instantiate_building(spawn_dict: Dictionary) ->void:
	# Only proceed if you are host
	if (!is_multiplayer_authority()):
		return;
	# Checks are done by auhtority here before instantiating the building
	if (
		!spawn_dict.has("grid_tiles") or !spawn_dict.has("building_properties")
	):
		return;
	## Array of [x_start, z_start, x_size, z_size] integer values
	var grid_tiles: Array = spawn_dict["grid_tiles"];
	## Building Properties is an array of [enum GlobalConstants.BuildingType] values to indicate properties of instantiated building
	var building_properties: Array = spawn_dict["building_properties"];
	if !map_grid.is_tiles_valid(grid_tiles[0], grid_tiles[1], grid_tiles[2], grid_tiles[3], building_properties):
			return;
	instantiate_building.rpc(spawn_dict);


## Called via RPC from [method request_instantiate_building] after authority has checked validity
## Instantiates the building, uses the MapGrid metadata to validate request and then request MapGrid use the tiles. Logs what tiles are in use for freeing
@rpc("authority", "call_local", "reliable")
func instantiate_building(spawn_dict: Dictionary) ->void:
	var grid_tiles: Array = spawn_dict["grid_tiles"];
	var x_start: int = grid_tiles[0]
	var z_start: int = grid_tiles[1]
	var x_size: int = grid_tiles[2]
	var z_size : int = grid_tiles[3]
	var entity: Node3D
	var file_path : String = spawn_dict["file_path"]
	var pack : PackedScene = load(file_path);

	entity = pack.instantiate();

	entity.team = spawn_dict["team"];

	#color is an int, the object will access the actual color via GlobalConstants
	entity.color = spawn_dict["color"];

	map_grid.use_tiles(x_start, z_start, x_size, z_size)

	register_entity(entity);
	var entity_path: String = entity.get_path();

	entity.global_position = spawn_dict["building_position"];


## Called via RPC from the authority after doing final checks
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
		entity.request_cmd.rpc_id(get_multiplayer_authority(), cmd);

## Called locally on every player after we instantiate since you cannot rpc Nodes
## Assigns buildings to [member global_building_array] and units to [member global_unit_array] [br][br]
## Does NOT assign to Dictionary [member building_dictionary] due to requiring grid_tiles data present in instantiate building
func register_entity(entity: Node3D) -> void:
	global_entity_array.append(entity);
	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
		global_building_array.append(entity);
		if(!player_arr.is_empty()):
			player_arr[entity.color]["buildings"].append(entity);
	elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
		global_unit_array.append(entity);
		if(!player_arr.is_empty()):
			player_arr[entity.color]["units"].append(entity);
	add_child(entity);


## Iterates through
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
			## Remove them from the MapGrid
			if(!building_dictionary.has(entity_path)):
				push_warning("Building was not in the grid? May be functionality later if buildings fly like terran!! :3")
			#var grid_tiles: Array = building_dictionary[entity_path];
			## We will break the array into variables to make the code clearer
			#var x_start: int = grid_tiles[0];
			#var z_start: int = grid_tiles[1];
			#var x_size: int = grid_tiles[2];
			#var z_size: int = grid_tiles[3];
			#map_grid.free_tiles(x_start,z_start,x_size,z_size);

			# Iterate through the array backwards to ensure resizing does not interfere while we remove entities
			for i: int in range(global_building_array.size()-1,-1, -1):
				if (entity == global_building_array[i]):
					global_building_array.remove_at(i);
					break;

			# Iterate through the array backwards to ensure resizing does not interfere while we remove entities
			for i:int in range(player_arr[ent_color]["buildings"].size()-1,-1,-1):
				if(entity == player_arr[ent_color]["buildings"][i]):
					player_arr[ent_color]["buildings"].remove_at(i);
					break;
			#check to see if that was the last building and end game
			if(is_multiplayer_authority()):
				if(player_arr[ent_color]["buildings"].is_empty()):
					player_lost.emit(ent_color); #Goes to game scene who calls player data manager
	remove_child(entity);

@rpc("authority", "call_local", "reliable")
func initialize_player_arr(players: Array[int]) ->void:
	print("wtf")
	for player: int in players:
		var dict: Dictionary = {
			"units" = [],
			"buildings" = [],
		}
		player_arr[player] = dict;
		#for each unit in the scene already, if they have the same color as player_arr key, then add them

func scrub_lists() ->void:
	pass;
