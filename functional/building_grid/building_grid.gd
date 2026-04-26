@tool
class_name BuildingGrid
extends Area3D

@onready var grid_tile: PackedScene = load("uid://cj2g37cbu27v")

@export var tile_size: float = 1:
	set(new_size):
		tile_size = new_size;
		if Engine.is_editor_hint():
			update_size(grid_size_x, grid_size_z);
@export var grid_size_x: int = 10:
	set(new_x):
		grid_size_x = new_x;
		if Engine.is_editor_hint():
			update_size(grid_size_x, grid_size_z);
@export var grid_size_z: int = 10:
	set(new_z):
		grid_size_z = new_z;
		if Engine.is_editor_hint():
			update_size(grid_size_x, grid_size_z);
var grid: Array[Array] = [];

@export var col: CollisionShape3D;



func _ready()->void:
	if(!Engine.is_editor_hint()):
		print("not doing this regularly");
		setup();



func setup()->void:
	for i: int in range(grid_size_x):
		grid.append([]);
		for j: int in range(grid_size_z):
			grid[i].append(null);
			var tile: GridTile = grid_tile.instantiate()
			add_child(tile);
			tile.position = Vector3(tile_size * i + (tile_size/2), 0, tile_size * j + (tile_size/2));
			grid[i][j] = tile;
			tile.index = [i,j];
			#as we get better at determining what is valid through checking world space, we will set flags for the tiles
			tile.INVALID_FLAG = false;
			tile.HIGHLIGHT_FLAG = false;
			tile.USED_FLAG = false;
	update_size(grid_size_x, grid_size_z);

func is_tile_valid(x: int, z: int, building_array: Array )->bool: #returns if its valid
	var tile:GridTile = grid[x][z];
	var is_depot: bool = false;
	if building_array.has(GlobalConstants.BuildingType.RESOURCE_DEPOT):
		is_depot = true;
	if (is_depot && tile.INVALID_DEPOT_FLAG):
		return false;
	if (tile.INVALID_FLAG || tile.USED_FLAG || tile.TEMPORARY_INVALID_FLAG):
		return false;
	return (x >= 0 && z >= 0 && x < grid_size_x && z < grid_size_z && !grid[x][z].INVALID_FLAG);

func is_tiles_valid(x_start: int, z_start: int, size: Array, building_type: Array) ->bool:
	var x_size: int = size[0];
	var z_size: int = size[1];
	var is_valid: bool = true;
	var is_depot: bool = false;
	if (building_type.has(GlobalConstants.BuildingType.RESOURCE_DEPOT)):
		is_depot = true;

	if(x_start < 0): #x min case
		x_size += x_start
		x_start = 0;
		is_valid = false;
		return is_valid;
	if (z_start < 0): #z min case
		z_size += z_start;
		z_start = 0;
		is_valid = false;
		return is_valid
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	if (max_x > grid_size_x): #x max case
		max_x = grid_size_x
		is_valid = false;
		return is_valid
	if(max_z > grid_size_z): # z max case
		max_z = grid_size_z;
		is_valid = false;
		return is_valid
	for i: int in range(x_start, max_x):
		for j: int in range (z_start, max_z):
			print(i,j)
			var tile: GridTile = grid[i][j];
			if (tile.INVALID_FLAG || tile.USED_FLAG || tile.TEMPORARY_INVALID_FLAG):
				return false #one of the flags or tiles is invalid so we cant do it
	return is_valid;

func is_tile(x:int, z: int) ->bool: #returns if its just a tile, used or not
	return (x >= 0 && z >= 0 && x < grid_size_x && z < grid_size_z)

func free_tile(x: int, z: int) ->void:
	grid[x][z].USED_FLAG = false;

func free_tiles(x: int, z: int, size: Array) ->void:
	for i: int in range(x, x + size[0]):
		for j: int in range(z, z + size[1]):
			if(is_tile(i,j)):
				grid[i][j].USED_FLAG = false;

func clear_highlight() -> void:
	for i: int in range(0, grid_size_x):
		for j: int in range(0, grid_size_z):
			var tile: GridTile = grid[i][j];
			tile.HIGHLIGHT_FLAG = false;
			tile.TEMPORARY_INVALID_FLAG = false;

func display_tiles() -> void:
	for i: int in range(0, grid_size_x):
		for j: int in range (0, grid_size_z):
			var tile: GridTile = grid[i][j];
			tile.visible = true;

func hide_tiles() -> void:
	for i: int in range(0, grid_size_x):
		for j: int in range (0, grid_size_z):
			var tile: GridTile = grid[i][j];
			tile.visible = false;

func highlight_tiles(x_start: int, z_start:int, size:Array) ->void:
	var x_size: int = size[0];
	var z_size: int = size[1];
	var valid: bool = true;
	if(x_start < 0):
		x_size += x_start
		x_start = 0;
		valid = false;
	if (z_start < 0):
		z_size += z_start;
		z_start = 0;
		valid = false;
	var max_x: int = x_start + x_size;
	var max_z: int = z_start + z_size;
	if (max_x > grid_size_x):
		#invalid size fitting
		max_x = grid_size_x #so we only get valid tiles
		valid = false;
	if(max_z > grid_size_z):
		max_z = grid_size_z; #so we only get valid tiles
		valid = false;
	for i: int in range(x_start, max_x):
		for j: int in range (z_start, max_z):
			var tile: GridTile = grid[i][j];
			tile.HIGHLIGHT_FLAG = true;
			if(!valid):
				tile.TEMPORARY_INVALID_FLAG = true;

func update_size(x: float, z: float) ->void:
	col.position = Vector3((x * tile_size) /2, 0, (z * tile_size)/2);
	if(x <= 0 || z <= 0):
		return;
	col.shape.size.x = x * tile_size;
	col.shape.size.z = z * tile_size;

func use_tile(x: int, z: int, building_array: Array) ->bool:

	if (is_tile_valid(x, z, building_array)):
		var tile: GridTile = grid[x][z]
		tile.USED_FLAG = true;
		return true; #successfully used tile
	else:
		return false;

func use_tiles(x: int, z:int, size: Array, building_array: Array)->bool:
	var tiles: Array[GridTile];
	for i: int in range(x, x + size[0]):
		for j: int in range(z, z + size[1]):
			if (is_tile_valid(i,j, building_array)):
				tiles.append(grid[i][j]);
			else:
				return false;
	for tile: int in tiles.size():
		tiles[tile].USED_FLAG = true;
		print(tiles[tile].index)
	return true;  #successfully used tiles
