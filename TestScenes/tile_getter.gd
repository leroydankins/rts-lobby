
extends Node

const BUILDING_GRID_COLLISION_MASK: int = 0b1000000000000; #layer 13
const BUILDING_1: Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5),
	"tile_size": [1,1],
	"building_array": [GlobalConstants.BuildingType.CENTER, GlobalConstants.BuildingType.RESOURCE_DEPOT],
	"argument": ["grid_location", "location"],
	"grid_location" : [],
}
const BUILDING_2: Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5),
	"tile_size": [2,2],
	"building_array": [],
	"grid_location" : [],
}
const BUILDING_3 :Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5),
	"tile_size": [3,3],
	"building_array": [],
	"grid_location" : [], #this is placeholder, real commands dont have this by default it comes from the handle cmd situation in real game
}
const BUILDING_4 :Dictionary = {
	"file_path" : GlobalConstants.DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",
	"entity_size": Vector3(1.5,1.5,1.5), #this should be the actual size of the entity that we use for placement and y axis alignment
	"tile_size": [4,4],
	"building_array": [GlobalConstants.BuildingType.CENTER, GlobalConstants.BuildingType.RESOURCE_DEPOT],
	"grid_location" : [],
}
var pending_cmd: Dictionary = {};
@onready var preview_mesh: MeshInstance3D = $PreviewMesh

@export var building_grid: BuildingGrid;
@export var entity_holder: EntityHolder;

var previous_index: Array[int] = []; #we use this so we dont have to do all the math every frame maybe?
var previous_size: Array = [];
var prev_x_bool: bool;
var prev_z_bool: bool;

func _physics_process(_delta: float) -> void:
	if (pending_cmd.is_empty()):
		return;
	var result: Dictionary = get_world_position(BUILDING_GRID_COLLISION_MASK);
	if !result.is_empty():
		if(!preview_mesh.visible):
			preview_mesh.show();
			#clear temporary flags
		var mesh: Mesh #declaring it here helps with an unsafe access warning on the var y line
		if(preview_mesh.mesh == null):
			#We will perhaps move this to background thread loading
			mesh = load(pending_cmd["entity_preview"]);
			preview_mesh.mesh = mesh
		else:
			mesh = preview_mesh.mesh;
		var pos: Vector3 = result["position"];
		var aabb: AABB = mesh.get_aabb()
		var mesh_size: Vector3 = aabb.size; #done to get rid of unsafe access warning on var y declaration
		var tile: GridTile = result["collider"];
		var tile_index: Array[int] = tile.index;
		var tile_size: Array = pending_cmd["tile_size"];
		if (tile_index == previous_index && tile_size == previous_size): #this is to deal with micro-tile adjustments?
			var x_bool: bool;
			var z_bool: bool;
			if (pos.x - floori(pos.x) > .5): #if we didnt change which tile
				x_bool = 1;
			if (pos.z - floori(pos.z) > .5): #if we didnt change which tile
				z_bool = 1;
			if (x_bool == prev_x_bool && z_bool == prev_z_bool):
				return;
			else:
				prev_x_bool = x_bool;
				prev_z_bool = z_bool;
				building_grid.clear_highlight()
		else:
			building_grid.clear_highlight();

		#we want to snap to grid tile corners if its an eventile_size, if its odd we want dead center of center
		var x: float
		var y: float = pos.y + mesh_size.y / 2
		var z: float
		var x_size: int = tile_size[0];
		var z_size: int = tile_size[1];
		var x_start_index: int;
		var z_start_index: int;

		if (tile_size[0] % 2): #if the xtile_size is odd, we want to get the x starting value
			x = floori(pos.x) + .5 #mesh position
			var x_displacement: int = x_size - ceili(float(x_size) / 2) #iftile_size is 9, this would be 9 - 5 = 4;, if this was 8, this would be 8 -
			x_start_index = tile_index[0] - x_displacement #if index is 13, this would be 14 - 2 = 12, then 12,13,14,15,16 would be lit for x tiles
		else: #if the x tile_size is even
			x = roundi(pos.x) #mesh position
			#if pos.x is greater than .5 then we don't subtract a value?
			var x_disp: int
			if ((pos.x - floori(pos.x)) <  0.5):
				x_disp = x_size / 2
			else:
				x_disp = (x_size / 2) - 1 # wont be a float because
			x_start_index = tile_index[0] - x_disp

		if (tile_size[1] % 2): #if the z tile_size is odd
			z = floori(pos.z) + .5
			var z_displacement: int = z_size - ceili(float(z_size) / 2)
			z_start_index = tile_index[1] - z_displacement
		else: #if the z tile_size is even
			z = roundi(pos.z) #for mesh position
			var z_disp: int
			if ((pos.z - floori(pos.z)) < 0.5):
				z_disp = z_size / 2
			else:
				z_disp = (z_size / 2) - 1 # wont be a float because
			z_start_index = tile_index[1] - z_disp

		building_grid.highlight_tiles(x_start_index,z_start_index, tile_size);
		preview_mesh.global_position = Vector3(x,y,z);
		previous_index = tile_index;
		previous_size = tile_size;
	else:
		prev_x_bool = 0;
		prev_z_bool = 0;
		previous_index = [];
		previous_size = [];
		if(preview_mesh.visible):
			preview_mesh.hide();
			building_grid.clear_highlight();

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("1")):
		building_grid.display_tiles()
		pending_cmd = BUILDING_1.duplicate();
		preview_mesh.show();
	elif(event.is_action_pressed("2")):
		building_grid.display_tiles()
		pending_cmd = BUILDING_2.duplicate();
		preview_mesh.show();
	elif(event.is_action_pressed("3")):
		building_grid.display_tiles()
		pending_cmd = BUILDING_3.duplicate();
		preview_mesh.show();
	elif(event.is_action_pressed("escape")):
		building_grid.hide_tiles();
		preview_mesh.hide();
		pending_cmd = {};
	if(event.is_action_pressed("select")):
		if(pending_cmd.is_empty()):
			return;
		var cmd_duplicate: Dictionary = pending_cmd.duplicate();
		#the pending command requires a location input
		#used for placing or checking locations on the building grid
		if(pending_cmd.has("grid_location")):
			var tile_dict: Dictionary = get_tile_placement();
			if (tile_dict.is_empty()):
				return;
			var tiles : Array = tile_dict["tiles"]
			#check if tiles are valid and available
			print("checking tiles x: ", tiles[0], " \n and z: ", tiles[1], " \n with size: ", tiles[2]);
			var building_arr: Array = [];
			if (pending_cmd.has("building_type")):
				building_arr = pending_cmd["building_array"];
			var is_valid: bool = building_grid.is_tiles_valid(tiles[0],tiles[1],tiles[2], building_arr) #x start, z start, size
			if !is_valid:
				return;
			var world_position: Vector3 = tile_dict["world_position"]
			pending_cmd["position"] = world_position;
			pending_cmd["grid_tiles"] = tiles;
			handle_cmd(pending_cmd);
			#building_grid.hide_tiles();
			preview_mesh.hide();
			building_grid.clear_highlight();
			pending_cmd = {};
			#Next section will be handled at the unit level when they go to place the building but we still need to placeholder it so we cant queue 2 on that spot

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
	print("handling command")
	entity_holder.instantiate_building(spawn_dict);
	pass;

func get_world_position(collision_mask: int) -> Dictionary:
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

func get_tile_placement() -> Dictionary:
	var result: Dictionary = get_world_position(BUILDING_GRID_COLLISION_MASK);
	if !result.is_empty():
		if(!preview_mesh.visible):
			preview_mesh.show();
			#clear temporary flags
		var mesh: Mesh #declaring it here helps with an unsafe access warning on the var y line
		var pos: Vector3 = result["position"];
		var tile: GridTile = result["collider"];
		var tile_index: Array[int] = tile.index;
		var tile_size: Array = pending_cmd["tile_size"];
		var entity_size: Vector3 = pending_cmd["entity_size"];
		#we want to snap to grid tile corners if its an even tile_size, if its odd we want dead center of center
		var x: float
		var y: float = pos.y
		var z: float
		var x_size: int = tile_size[0];
		var z_size: int = tile_size[1];
		var x_start_index: int;
		var z_start_index: int;
		if (tile_size[0] % 2): #if the x tile_size is odd, we want to get the x starting value
			x = floori(pos.x) + .5 #mesh position
			var x_displacement: int = x_size - ceili(float(x_size) / 2) #if tile_size is 9, this would be 9 - 5 = 4;, if this was 8, this would be 8 -
			x_start_index = tile_index[0] - x_displacement #if index is 13, this would be 14 - 2 = 12, then 12,13,14,15,16 would be lit for x tiles
		else: #if the x tile_size is even
			x = roundi(pos.x) #mesh position
			#if pos.x is greater than .5 then we don't subtract a value?
			var x_disp: int
			if ((pos.x - floori(pos.x)) <  0.5):
				x_disp = x_size / 2
			else:
				x_disp = (x_size / 2) - 1 # wont be a float because
			x_start_index = tile_index[0] - x_disp

		if (tile_size[1] % 2): #if the z tile_size is odd
			z = floori(pos.z) + .5
			var z_displacement: int = z_size - ceili(float(z_size) / 2)
			z_start_index = tile_index[1] - z_displacement
		else: #if the z tile_size is even
			z = roundi(pos.z) #for mesh position
			var z_disp: int
			if ((pos.z - floori(pos.z)) < 0.5):
				z_disp = z_size / 2
			else:
				z_disp = (z_size / 2) - 1 # wont be a float because
			z_start_index = tile_index[1] - z_disp

		#check if tiles are valid for placement maybe outside this method?
		var placement_dict: Dictionary = {
			# array of [starting x tile, starting z tile, size of tiles]
			"tiles" : [x_start_index,z_start_index, tile_size],
			"world_position": Vector3(x,y,z),
		}
		return placement_dict;
	else: return {};
