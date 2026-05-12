@tool
extends Node
@export var building_grid: BuildingGrid;
@export var col: CollisionShape3D;
@onready var grid_tile: PackedScene = preload("uid://cj2g37cbu27v")
@export var grid: Array[Array] = [];

@export var add_grid_tile_bool: bool = true:
	set(new_value):
		if(Engine.is_editor_hint()):
			bake();
@export var unbake_bool: bool = true:
	set(new_value):
		if(Engine.is_editor_hint()):
			unbake();
@export var tile_size: float = 1:
	set(new_size):
		tile_size = new_size;
		building_grid.tile_size = new_size;
		if Engine.is_editor_hint():
			update_size(grid_size_x, grid_size_z);
@export var grid_size_x: int = 10:
	set(new_x):
		grid_size_x = new_x;
		building_grid.grid_size_x = new_x;
		if Engine.is_editor_hint():
			update_size(grid_size_x, grid_size_z);
@export var grid_size_z: int = 10:
	set(new_z):
		grid_size_z = new_z;
		building_grid.grid_size_z = new_z;
		if Engine.is_editor_hint():
			update_size(grid_size_x, grid_size_z);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func bake()->void:
	if(Engine.is_editor_hint()):
		unbake(); #always clear last run first
		var time: float = Time.get_ticks_msec();
		for i: int in range(grid_size_x):
			var new_arr : Array = [];
			grid.append(new_arr);
			for j: int in range(grid_size_z):
				grid[i].append(null);
				var tile: GridTile = grid_tile.instantiate()
				building_grid.add_child(tile,false,Node.INTERNAL_MODE_BACK);
				tile.owner = get_tree().edited_scene_root
				tile.position = Vector3(tile_size * i + (tile_size/2), 0, tile_size * j + (tile_size/2));
				grid[i][j] = tile;
				tile.index = [i,j];
				##as we get better at determining what is valid through checking world space, we will set flags for the tiles
				#tile.set_up();
		building_grid.grid = grid;
		var time2: float = Time.get_ticks_msec();
		var amt: int = grid_size_x * grid_size_z;
		print ("Time to bake %s grids was %s ms" % [amt, time2-time]);

func unbake()->void:
	if(Engine.is_editor_hint()):
		for thing: Node in building_grid.get_children(true):
			if(thing is GridTile):
				building_grid.remove_child(thing);
				thing.free();
		grid = [];
		building_grid.grid  = [];
		var time2: float = Time.get_ticks_msec();


func update_size(x: float, z: float) ->void:
	col.position = Vector3((x * tile_size) /2, 0, (z * tile_size)/2);
	if(x <= 0 || z <= 0):
		return;
	col.shape.size.x = x * tile_size;
	col.shape.size.z = z * tile_size;
