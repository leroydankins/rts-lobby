extends Node
##Collision Mask Layer 13 used to detect the MapGrid
const BUILDING_GRID_COLLISION_MASK: int = 0b1000000000000; #layer 13


const BUILDING_1: Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5),
	"tile_size": [1,1],
	"building_properties": [GlobalConstants.BuildingType.TOWNHALL, GlobalConstants.BuildingType.DEPOT],
	"argument": ["grid_location", "location"],
	"grid_location" : [],
}
const BUILDING_2: Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5),
	"tile_size": [2,2],
	"building_properties": [],
	"grid_location" : [],
}
const BUILDING_3 :Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5),
	"tile_size": [3,3],
	"building_properties": [],
	"grid_location" : [], #this is placeholder, real commands dont have this by default it comes from the handle cmd situation in real game
}
const BUILDING_4 :Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5), #this should be the actual size of the entity that we use for placement and y axis alignment
	"tile_size": [4,4],
	"building_properties": [GlobalConstants.BuildingType.TOWNHALL, GlobalConstants.BuildingType.DEPOT],
	"grid_location" : [],
}
var pending_cmd: Dictionary = {};
@onready var preview_mesh: MeshInstance3D = $PreviewMesh
@export var map_grid : MapGrid;
@export var entity_holder: EntityHolder;

var previous_index: Array[int] = []; #we use this so we dont have to do all the math every frame maybe?
var previous_size: Array = [];
var prev_x_bool: bool;
var prev_z_bool: bool;

func _physics_process(_delta: float) -> void:
	if (pending_cmd.is_empty()):
		return;
	var time: float = Time.get_ticks_usec();
	var time2: float = Time.get_ticks_usec();
	var result: Dictionary;
	var pos: Vector3;
	var tile_index: Array[int]; #this will be the floor int value of the collider position
	var tile_size: Array; #this is how many tiles we take up with our building, untyped due to constant in thing
	var x_bool: bool;
	var z_bool: bool;
	#we want to snap to grid tile corners if its an eventile_size, if its odd we want dead center of center
	var mesh_x: float
	var mesh_y: float #We will have the meshes auto size so that we dont have to move the pos aside from terrain height
	var mesh_z: float
	var x_size: int
	var z_size: int
	var x_start_index: int;
	var z_start_index: int;
	var x_displacement: int
	var z_displacement: int
	var mesh: Mesh #declaring it here helps with an unsafe access warning on the var y line

	result = get_world_raycast(BUILDING_GRID_COLLISION_MASK);
	if (!result): #if the dictionary is empty
		prev_x_bool = 0;
		prev_z_bool = 0;
		previous_index = [];
		previous_size = [];
		if(preview_mesh.visible):
			preview_mesh.hide();
			map_grid.clear_highlight();
	else: #dictionary is not empty
		pos = result["position"];
		mesh_y = pos.y
		tile_index= [floori(pos.x),floori(pos.z)]; #this will be the floor int value of the collider position
		tile_size = pending_cmd["tile_size"];
		x_size = tile_size[0];
		z_size = tile_size[1];
		if(!map_grid.is_location_in_tile_layer(pos)):
			preview_mesh.hide();
			map_grid.clear_highlight();
			return;

		if(!preview_mesh.visible):
			preview_mesh.show();
			#clear temporary flags

		if(preview_mesh.mesh == null):
			#We will perhaps move this to background thread loading
			mesh = load(pending_cmd["entity_preview"]);
			preview_mesh.mesh = mesh
		else:
			mesh = preview_mesh.mesh;

		if (tile_index == previous_index && tile_size == previous_size): #this is to deal with micro-tile adjustments?
			if (pos.x - floori(pos.x) > .5): #if we didnt change which tile
				x_bool = 1;

			if (pos.z - floori(pos.z) > .5): #if we didnt change which tile
				z_bool = 1;

			if (x_bool == prev_x_bool && z_bool == prev_z_bool):
				return;
			else:
				prev_x_bool = x_bool;
				prev_z_bool = z_bool;
				map_grid.clear_highlight()
		else:
			map_grid.clear_highlight();

		#
		x_displacement = floori(float(x_size) / 2)  #if tile_size is 9, this would be 9 - 5 = 4;, if this was 8, this would be 8 - 4 = 4
		z_displacement = floori(float(z_size) / 2) #maybe we dont need to do an int and we can instead just div
		if (x_size % 2): #if the xtile_size is odd, we want to get the x starting value
				mesh_x = floori(pos.x) + .5 #mesh position
				x_start_index = tile_index[0] - x_displacement #if index is 13, this would be 14 - 2 = 12, then 12,13,14,15,16 would be lit for x tiles
		else: #if the x tile_size is even
			mesh_x = roundi(pos.x) #mesh position
			#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
			if ((pos.x - floori(pos.x)) >  0.5):
				x_displacement -= 1
			x_start_index = tile_index[0] - x_displacement

		if (z_size % 2): #if the z tile_size is odd
			mesh_z = floori(pos.z) + .5
			z_start_index = tile_index[1] - z_displacement
		else: #if the z tile_size is even
			mesh_z = roundi(pos.z) #for mesh position
			#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
			if ((pos.z - floori(pos.z)) >  0.5):
				z_displacement -= 1
			z_start_index = tile_index[1] - z_displacement

		map_grid.highlight_tiles(x_start_index,z_start_index, tile_size);
		preview_mesh.global_position = Vector3(mesh_x,mesh_y,mesh_z);
		previous_index = tile_index;
		previous_size = tile_size;



func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("1")):
		map_grid.display_tiles()
		pending_cmd = BUILDING_1.duplicate();
		preview_mesh.show();
	elif(event.is_action_pressed("2")):
		map_grid.display_tiles()
		pending_cmd = BUILDING_2.duplicate();
		preview_mesh.show();
	elif(event.is_action_pressed("3")):
		map_grid.display_tiles()
		pending_cmd = BUILDING_3.duplicate();
		preview_mesh.show();
	elif(event.is_action_pressed("escape")):
		map_grid.hide_tiles();
		preview_mesh.hide();
		pending_cmd = {};
	#Rework
	if(event.is_action_pressed("select")):
		if(pending_cmd.is_empty()):
			return;
		var cmd_duplicate: Dictionary = pending_cmd.duplicate(); #this is already a duplicate in prod I think
		#the pending command requires a location input
		#used for placing or checking locations on the building grid
		if(cmd_duplicate.has("grid_location")):
			# Local Var Defines
			var building_properties: Array = cmd_duplicate["building_properties"];

			# Breakout array into ints for clarity on function calls
			var tile_size: Array = cmd_duplicate["tile_size"];
			var x_size: int = tile_size[0];
			var z_size: int = tile_size[1];

			var result: Dictionary
			var result_position: Vector3
			var resultant_grid_dictionary: Dictionary


			result = get_world_raycast(BUILDING_GRID_COLLISION_MASK)
			if(!result):
				pending_cmd = {};
				return;

			result_position = result["position"];

			if(!map_grid.is_location_in_tile_layer(result_position)):

				pending_cmd = {};
				return;

			resultant_grid_dictionary = map_grid.get_building_placement_dictionary(result_position, x_size, z_size, building_properties);
			#If this was not a part of the grid
			if(!resultant_grid_dictionary):

				pending_cmd = {};
				preview_mesh.hide();
				return;


			#Add gained grid_tile data and associated world position to command
			cmd_duplicate.merge(resultant_grid_dictionary)

			#process command
			handle_cmd(cmd_duplicate);

			#clear data
			preview_mesh.hide();
			map_grid.hide_tiles();
			map_grid.clear_highlight();
			pending_cmd = {};

	if (event.is_action_pressed("action")):
		var result : Dictionary = get_world_raycast(0);
		pass;


func reset_prev()->void:
	previous_index = []; #we use this so we dont have to do all the math every frame maybe?
	previous_size = [];
	prev_x_bool = false;
	prev_z_bool = false;

func handle_cmd(cmd: Dictionary) -> void:
	#we dont need full handle cmd functionality for this test script, just call the add building cmd directly at entity_holder
	if (cmd.is_empty()):
		return;
	var spawn_dict: Dictionary = cmd.duplicate();
	#placeholder shi rn since we arent in a full scene
	spawn_dict["color"] = 0;
	spawn_dict["team"] = 0;
	entity_holder.request_instantiate_building.rpc_id(get_multiplayer_authority(), spawn_dict);
	pass;

## Returns the values of [method PhysicsDirectSpaceState3D.intersect_ray] [br]
## Follow the link to that method to see returning dictionary
func get_world_raycast(collision_mask: int) -> Dictionary:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_length: int = 100
	var camera: Camera3D = get_viewport().get_camera_3d();
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,collision_mask);
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	return raycast_result;
