class_name MapGrid
extends Node3D

## Handles the grid system used for building placement. [br][br]
##
## MapGrid contains a 2D array grid of building squares for placement of building entities[br][br]
## Each index in the array grid represents one square, and is a packed byte array of flags and information[br][br]
## Data type as a struct: [Flags.TEMPORARY_INVALID_FLAG] HIGHLIGHT_FLAG, INVALID_FLAG, USED_FLAG, INVALID_DEPOT_FLAG][br]
## Grid data is used to update shader on terrain materials[br]
##
## [CommandController] utilizes functions in this script to establish command data for instantiation of buildings[br]
##
## Each

## Placement of each flag in the stored grid indices
enum Flags {
	Y_LAYER,
	USED_FLAG,
	HIGHLIGHT_FLAG,
	INVALID_TILE_FLAG,
	TEMPORARY_INVALID_FLAG, #This is only used for when we are highlighting for placement
	INVALID_DEPOT_FLAG,
}
## Layers enum that goes up to the byte sizing
var y_layers: Array[int] = [];
## Y Layer tolerance for validity checks
const Y_TOL: float = 0.05

## Collision Mask Layer 14 used to bake the MapGrid matrix
const GRID_BAKE_MASK: int = 0b0010000000000000 # 8196 or mask 13th bit layer 14
## Variable which determines the scale of grid tiles
@export var grid_square_size: float = 1
## Determines the MxN grid size, must be equal to map size
@export var grid_size: int = 10 # goes in both directions
## Actual Grid Array, may not need to be exported
@export var grid: Array[Array] = [];


## Vector array of what squares are currently highlighted to make iterating and removing highlight quick during physics process
var highlight_arr: Array[Array] = [];

func _ready() -> void:
	setup();
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## incomplete [br]
## functionality may be kept in physical representation of grid
func display_tiles()->void:
	pass;
## functionality may be kept in physical representation of grid
func hide_tiles() ->void:
	pass;

## Called during each physics process tick when the player is placing a building on the map, indicates what tiles are currently being moused over
func highlight_tiles(x_start: int, z_start:int, size:Array) ->void:
	var x_size: int = size[0];
	var z_size: int = size[1];
	var valid: bool = true;
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	var arr: Array
	if(x_start < 0):
		x_size += x_start
		x_start = 0;
		valid = false;
	if (z_start < 0):
		z_size += z_start;
		z_start = 0;
		valid = false;
	if (max_x > grid_size):
		#invalid size fitting
		max_x = grid_size #so we only get valid tiles
		valid = false;
	if(max_z > grid_size):
		max_z = grid_size; #so we only get valid tiles
		valid = false;
	for i: int in range(x_start, max_x):
		for j: int in range (z_start, max_z):
			arr = grid[i][j];
			if(!valid):
				arr[Flags.TEMPORARY_INVALID_FLAG] = true;
			else:
				arr[Flags.TEMPORARY_INVALID_FLAG] = false;
			if highlight_arr.has(arr):
				continue;
			if (arr[Flags.INVALID_TILE_FLAG]):
				continue;
			arr[Flags.HIGHLIGHT_FLAG] = 1 ;
			if(!valid):
				arr[Flags.TEMPORARY_INVALID_FLAG] = true;
			highlight_arr.append(arr);

func clear_highlight()->void:
	if(!highlight_arr):
		return;
	for i: int in range(highlight_arr.size()-1,-1, -1):
		highlight_arr[i][Flags.HIGHLIGHT_FLAG] = 0;
		highlight_arr.pop_back()

## This function will be called to allow snapping buildings to the grid, so long as you already know what tiles you need! [br][br]
## If you want to get the tiles from a world position, use [method get_building_placement_dictionary]
func get_tile_world_position(x_start: int, z_start: int, x_size: int, z_size: int) -> Vector3:
	return Vector3.ZERO;

## Takes in a [param Vector3] position, [param int] x_size, [param int] z_size, and the [param Array] of building properties to return the placement information dictionary.[br][br]
## Validates that the tileset is contiguous and placeable [br][br]
## Returns a Dictionary with the following values. [br] [br]
## [b] grid_tiles [/b] : [param x_start_index] : int ,  [param z_start_index] : int , [param tile_size_array] : int [br] [br]
## [b] building_position [/b]: [param position] : Vector3
func get_building_placement_dictionary(world_pos: Vector3, x_size: int, z_size: int, building_properties : Array) -> Dictionary:
	#if position is outside of grid space then we cut it
	if (world_pos.x < 0 || world_pos.z < 0 || world_pos.x > grid_size * grid_square_size || world_pos.z > grid_size * grid_square_size):
		return {};

	var tile_index: Array[int]; #this will be the floor int value of the collider position
	var building_position: Vector3 = world_pos;
	var placement_dict: Dictionary
	# Starting index will be calculated based on x/z size and world position
	var x_start: int;
	var z_start: int;
	var x_displacement: int
	var z_displacement: int
	tile_index = [floori(world_pos.x),floori(world_pos.z)]; #this will be the floor int value of the collider position


	x_displacement = floori(float(x_size) / 2)  #if tile_size is 9, this would be 9 - 5 = 4;, if this was 8, this would be 8 - 4 = 4
	z_displacement = floori(float(z_size) / 2) #maybe we dont need to do an int and we can instead just div

	#X Index % X Building Position
	if (x_size % 2): #if the xtile_size is odd, we want to get the x starting value
			building_position.x = floori(world_pos.x) + .5 #building position
			x_start = tile_index[0] - x_displacement #if index is 13, this would be 14 - 2 = 12, then 12,13,14,15,16 would be lit for x tiles
	else: #if the x tile_size is even
		building_position.x = roundi(world_pos.x) #building position
		#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
		if ((building_position.x - floori(world_pos.x)) >  0.5):
			x_displacement -= 1
		x_start = tile_index[0] - x_displacement

	# Z Index & Z Building Position
	if (z_size % 2): #if the z tile_size is odd
		building_position.z = floori(world_pos.z) + .5 #building position
		z_start = tile_index[1] - z_displacement
	else: #if the z tile_size is even
		building_position.z = roundi(world_pos.z) #building position
		#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
		if ((building_position.z - floori(world_pos.z)) >  0.5):
			z_displacement -= 1
		z_start = tile_index[1] - z_displacement

	#Y Layer & Y Building Position
	var tile_data : PackedByteArray = grid[x_start][z_start];
	building_position.y = tile_data[Flags.Y_LAYER];

	#Validate the placement with is_tiles_valid?
	if (!is_tiles_valid(x_start, z_start, x_size, z_size, building_properties)):
		return {};

	placement_dict = {
		# array of [starting x tile, starting z tile, x size, z size]
		"grid_tiles" : [x_start, z_start, x_size, z_size],
		"building_position": building_position,
	}
	return placement_dict;





################################# INTERNAL FUNCTIONS

## Bakes the matrix of in-game grid tiles that all buildings adhere[br][br]
## Creates an array of raycasts for each corner index and comparison is used to validate all flat tile spaces[br][br]
## Currently, runs on _ready and thus takes a solid amount of time (30ms) to run for a 100x100 grid.[br][br]
## [b]This must be baked as a @tool script function in implementation[/b]
func setup()->void:
	var time: float = Time.get_ticks_usec()
	var ray_length: int = 15;
	var vec_dict: Dictionary
	var vec_arr: PackedFloat32Array;
	var y_check_var: float;
	var y_layer: int
	## [Y_LAYER, USED_FLAG, HIGHLIGHT_FLAG, INVALID_TILE_FLAG, TEMPORARY_INVALID_FLAG,  INVALID_DEPOT_FLAG]
	var data_arr: PackedByteArray
	var from: Vector3;
	var to: Vector3;
	var ray_query: PhysicsRayQueryParameters3D;
	var space: PhysicsDirectSpaceState3D
	var raycast_result: Dictionary;
	#We should be doing this only in positive values due to the fact that this shit is ass
	for x: int in (grid_size + 1):
		for z: int in (grid_size + 1):
			# Iterate through each of the
			from = global_position + Vector3(x,0,z);
			to = from + Vector3.DOWN * ray_length
			ray_query = PhysicsRayQueryParameters3D.create(from,to,GRID_BAKE_MASK);
			space = get_viewport().get_world_3d().direct_space_state;
			ray_query.collide_with_areas = true
			raycast_result = space.intersect_ray(ray_query)
			## This way is slightly more performant but I cannot make grabbing the locations very easy this way
			#if(raycast_result.is_empty()):
				#vec_arr.append(0);
			#else:
				#var result_pos: Vector3 = raycast_result["position"]
				#vec_arr.append(result_pos.y);
			if(raycast_result.is_empty()): # if no ground was intercepted, we instantly can call it invalid
				vec_dict[[x,z]] = -1;
			else:
				vec_dict[[x,z]] = raycast_result["position"].y;

	for i: int in grid_size:
		grid.append([])
		for j: int in grid_size:
			data_arr = [0,0,0,0,0,0];
			y_check_var = vec_dict[[i,j]]
			y_layer = roundi(y_check_var);
			if (
				y_check_var != vec_dict[[i+1,j]] or y_check_var != vec_dict[[i,j+1]]
				or y_check_var != vec_dict[[i+1,j+1]]
			):
				data_arr[Flags.INVALID_TILE_FLAG] = 1;
			# After this, we consider the tile to be valid for placement
			elif(!y_layers.has(y_layer)): # We only care that we encompass all Y layers for validating Vector3 checks by the controller
				y_layers.append(y_layer)
			data_arr[Flags.Y_LAYER] = y_layer #The value must be less than 128 since we are representing this with a Byte in the flag array
			grid[i].append(data_arr)
	var time2: float = Time.get_ticks_usec();
	print ("time is %s" % [(time2 - time) / 1000])


## Validates if the tiles remain in bounds of the grid map
func is_in_bounds(x_start: int, z_start: int, x_size: int, z_size: int) -> bool:
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	if (
		x_start < 0 or z_start < 0
		or max_x >= grid_size or max_z >= grid_size
	):
		return false;
	else:
		return true;

### Checks if values are on different y platforms
#func is_contig(x_start: int, z_start: int, x_size: int, z_size: int) -> bool:
	#var max_x: int = x_start + x_size;
	#var max_z: int = z_start + z_size;
	##Initialize to first one
	#var y_val: int = grid[x_start][z_start][Flags.Y_LAYER];
	#for i: int in range(x_start, max_x):
		#for j: int in range (z_start, max_z):
			#if (y_val  != grid[i][j][Flags.Y_LAYER]):
				#return false;
	#return true;









################################## EXTERNALLY CALLED FUNCTIONS


## [CommandController], [EntityHolder] check validity of tile selection
func is_tiles_valid(x_start: int, z_start: int, x_size: int, z_size: int, building_properties: Array) ->bool:
	var is_valid: bool = true;
	var is_depot: bool = false;
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	if (building_properties.has(GlobalConstants.BuildingType.DEPOT)):
		is_depot = true;
		#we need to check if adjacent tiles cannot have a depot
	# If they are not contiguous, its not valid
	# We can call is_in_bounds for this but not hiding logic right away
	if (
		x_start < 0 or z_start < 0
		or max_x > grid_size or max_z > grid_size
	):
		is_valid = false;
		return is_valid;

	for i: int in range(x_start, max_x):
		for j: int in range (z_start, max_z):
			var tile: Array = grid[i][j];
			if (is_depot && tile[Flags.INVALID_DEPOT_FLAG]):
				return false;
			if (tile[Flags.INVALID_TILE_FLAG] || tile[Flags.USED_FLAG] || tile[Flags.TEMPORARY_INVALID_FLAG]):
				return false #one of the flags or tiles is invalid so we cant do it
	return is_valid;

## [CommandController] Check if given Vector3 is a valid tile within a tolerance by [CommandController]
func is_location_in_tile_layer(location: Vector3) ->bool:
	var x_val: int = roundi(location.x)
	var y_val: int = roundi(location.y)
	var z_val: int = roundi(location.z)
	if (x_val < 0 || z_val < 0 || x_val >= grid_size || z_val >= grid_size):
		return false;

	if (abs(y_val - location.y) >= Y_TOL):
	# invalid y check
		return false;
	if (!y_layers.has(y_val)):
		return false;
	#if (grid[x_val][z_val][Flags.INVALID_FLAG] == 1):
		#return false;
	return true;

## Used to check validity of single tile by CommandController
func is_valid(x_val: int, z_val: int) ->bool:
	if (
		x_val < 0 or z_val < 0
		or x_val >= grid_size or z_val >= grid_size
	):
		return false;
	if (grid[x_val][z_val][Flags.INVALID_TILE_FLAG] == 1):
		return false;
	return true;

## [EntityHolder] when instantiating a building on the grid in game [br]
## Called after validity checks in an RPC so there is no early offramp if invalid
func use_tiles(x_start: int, z_start: int, x_size: int, z_size: int) ->void:
	# We do not do a validity check since this is called from RPC EntityHolder
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	for i: int in range(x_start, max_x):
		for j: int in range(z_start, max_z):
			var tile: Array = grid[i][j];
			if(tile[Flags.INVALID_TILE_FLAG]):
				push_error("using an invalid flag, should have been caught in checks");
			print("Using tile: %s, %s" % [i,j])
			grid[i][j][Flags.USED_FLAG] = 1;

## Called after validity checks in an RPC so there is no early offramp if invalid
func free_tiles(x_start: int, z_start: int, x_size: int, z_size: int) ->void:
	# We do not do a validity check since this is called from RPC EntityHolder
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	for i: int in range(x_start, max_x):
		for j: int in range(z_start, max_z):
			var tile: Array = grid[i][j];
			if(tile[Flags.INVALID_TILE_FLAG]):
				push_error("using an invalid flag, should have been caught in checks?");
			print("Freeing tile: %s, %s" % [i,j])
			grid[i][j][Flags.USED_FLAG] = 0;
