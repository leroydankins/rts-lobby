extends Node3D

@export var grid_tile: PackedScene;

@export var tile_size: int = 1;
@export var grid_size: float = 10
var grid: Array[Array] = [];

func _ready()->void:
	setup();

func setup()->void:
	for i: int in range(grid_size):
		grid.append([]);
		for j: int in range(grid_size):
			grid[i].append(null);
			var tile: MeshInstance3D = grid_tile.instantiate()
			add_child(tile);
			tile.position = Vector3(tile_size * i, 0, tile_size * j);
			grid[i][j] = tile;
			print(tile);
