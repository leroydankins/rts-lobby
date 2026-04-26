@tool
extends Area3D

@export var col: CollisionShape3D;

@export var shape_x: int = 1:
	set(new_x):
		shape_x = new_x;
		if Engine.is_editor_hint():
			update_size(shape_x, shape_y);

@export var shape_y: int = 1:
	set(new_y):
		shape_y = new_y;
		if Engine.is_editor_hint():
			update_size(shape_x, shape_y);

func update_size(x: float,y: float) ->void:
	position = Vector3(x/2, 0, y/2);
	if(x <= 0 || y <= 0):
		return;
	col.shape.size.x = x;
	col.shape.size.z = y;
