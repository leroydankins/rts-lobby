@tool
class_name MapTool
extends Area3D
var col: CollisionShape3D;

#@export var add_grid_tile_bool: bool = true:
	#set(new_value):
		#if(Engine.is_editor_hint()):
			#bake();
#
#@export var unbake_bool: bool = true:
	#set(new_value):
		#if(Engine.is_editor_hint()):
			#unbake();
@export var tile_size: float = 1:
	set(new_size):
		if Engine.is_editor_hint():
			tile_size = new_size;
			update_size(grid_size_x, grid_size_z);

@export var grid_size_x: int = 10:
	set(new_x):
		if Engine.is_editor_hint():
			grid_size_x = new_x;
			update_size(grid_size_x, grid_size_z);

@export var grid_size_z: int = 10:
	set(new_z):
		if Engine.is_editor_hint():
			grid_size_z = new_z;
			update_size(grid_size_x, grid_size_z);

func _enter_tree() ->void:
	if Engine.is_editor_hint():
		set_collision_layer(0);
		set_collision_mask(0)
		for node: Node in get_children():
			print("what")
			node.free();
		if(get_children().size() == 0):
			col = CollisionShape3D.new()
			col.name = "CollisionShape3D"
			add_child(col);
			col.owner = get_tree().edited_scene_root;
			var p_shape: BoxShape3D = BoxShape3D.new()
			col.shape = p_shape;
			print(get_children())
			p_shape.size.y = 10;
			update_size(grid_size_x, grid_size_z);


#func bake()->void:
	#if(Engine.is_editor_hint()):
		#unbake(); #always clear last run first
		#var time: float = Time.get_ticks_msec();
		#for i: int in range(grid_size_x):
			#var new_arr : Array = [];
			#grid.append(new_arr);
			#for j: int in range(grid_size_z):
				#grid[i].append(null);
				#var tile: GridTile = grid_tile.instantiate()
				#building_grid.add_child(tile,false,Node.INTERNAL_MODE_BACK);
				#tile.owner = get_tree().edited_scene_root
				#tile.position = Vector3(tile_size * i + (tile_size/2), 0, tile_size * j + (tile_size/2));
				#grid[i][j] = tile;
				#tile.index = [i,j];
				###as we get better at determining what is valid through checking world space, we will set flags for the tiles
				##tile.set_up();
		#building_grid.grid = grid;
		#var time2: float = Time.get_ticks_msec();
		#var amt: int = grid_size_x * grid_size_z;
		#print ("Time to bake %s grids was %s ms" % [amt, time2-time]);

#func unbake()->void:
	#if(Engine.is_editor_hint()):
		#for thing: Node in building_grid.get_children(true):
			#if(thing is GridTile):
				#building_grid.remove_child(thing);
				#thing.free();
		#grid = [];
		#building_grid.grid  = [];
		#var time2: float = Time.get_ticks_msec();

func update_size(x: float, z: float) ->void:
	if(get_children().size() == 0):
		return;
	var p_col: CollisionShape3D = get_node("CollisionShape3D");
	var p_shape: BoxShape3D = p_col.shape
	p_col.position = Vector3((x * tile_size) /2, 0, (z * tile_size)/2);
	if(x <= 0 || z <= 0):
		return;
	p_shape.size.x = x * tile_size;
	p_shape.size.z = z * tile_size;
