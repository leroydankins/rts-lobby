class_name GridTile
extends Area3D
const AREA_SIZE: int = 1;
const GRID_BAKE_MASK: int = 0b0010000000000000 #8196 or mask 13th bit
const TOLERANCE: float = .2
const GREEN_COLOR: Color = Color(0.471, 1.0, 0.471, 0.627) #green
const RED_COLOR: Color = Color(0.89, 0.0, 0.0, 0.42) #red
const REGULAR_COLOR: Color = Color(0.708, 0.708, 0.708, 0.4)
const YELLOW_COLOR: Color = Color(0.814, 0.707, 0.129, 0.4) #for when its not being highlighted

@export var index: Array[int] = [0,0];

@export var HIGHLIGHT_FLAG: bool = false;
@export var INVALID_FLAG: bool = false;
@export var USED_FLAG: bool = false;
@export var INVALID_DEPOT_FLAG: bool = false;
var TEMPORARY_INVALID_FLAG: bool = false;

@export var units: Array[Node3D] = [];
@onready var mesh: MeshInstance3D = $Mesh
@onready var col: CollisionShape3D = $CollisionShape3D


func _ready() ->void:
	#mouse_entered.connect(on_mouse_ent);
	#mouse_exited.connect(on_mouse_ex);
	var mat: StandardMaterial3D = mesh.get_surface_override_material(0);
	mat.albedo_color = REGULAR_COLOR;
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;

func _process(_delta: float) -> void:
	if(!visible || INVALID_FLAG): return;
	show_tile();


func show_tile() ->void:
	var mat: StandardMaterial3D = mesh.get_surface_override_material(0);
	if(HIGHLIGHT_FLAG):
		if(INVALID_FLAG):
			if (mat.albedo_color != RED_COLOR):
				mat.albedo_color = RED_COLOR;
		elif(USED_FLAG):
			if (mat.albedo_color != RED_COLOR):
				mat.albedo_color = RED_COLOR;
		elif(TEMPORARY_INVALID_FLAG):
			if (mat.albedo_color != RED_COLOR):
				mat.albedo_color = RED_COLOR;
		else:
			if (mat.albedo_color != GREEN_COLOR):
				mat.albedo_color = GREEN_COLOR;
	else:
		if(INVALID_FLAG):
			if (mat.albedo_color != RED_COLOR):
				mat.albedo_color = RED_COLOR;
		elif(USED_FLAG):
			if (mat.albedo_color != YELLOW_COLOR):
				mat.albedo_color = YELLOW_COLOR;
		else:
			if (mat.albedo_color != REGULAR_COLOR):
				mat.albedo_color = REGULAR_COLOR;

func on_mouse_ent() ->void:
	HIGHLIGHT_FLAG = true;

func on_mouse_ex() ->void:
	HIGHLIGHT_FLAG = false;


func set_up() ->void:
	#we need to create an array of our grid corner results
	var result_arr: PackedVector3Array = [];

	#find which points we cast our ray from in local space
	var v_0: Vector3 = Vector3(-.5 * AREA_SIZE, 0, -.5 * AREA_SIZE); #bottom left
	var v_1: Vector3 = Vector3(.5 * AREA_SIZE, 0, -.5 * AREA_SIZE); #top left
	var v_2: Vector3 = Vector3(.5 * AREA_SIZE, 0, .5 * AREA_SIZE); #top right
	var v_3: Vector3 = Vector3(-.5 * AREA_SIZE, 0, .5 * AREA_SIZE); # bottom right
	var vector_arr: PackedVector3Array = [v_0, v_1, v_2, v_3];
	#cast each ray and store the vector location that we intercepted a ground
	var ray_length: int = 15
	for vec: Vector3 in vector_arr:
		var from: Vector3 = global_position + vec
		var to: Vector3 = from + Vector3.DOWN * ray_length
		var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
		var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,GRID_BAKE_MASK);
		ray_query.collide_with_areas = true
		var raycast_result: Dictionary = space.intersect_ray(ray_query)
		#if no ground was intercepted, we instantly can call it invalid
		if(raycast_result.is_empty()):
			disable()
			return
		var result_pos: Vector3 = raycast_result["position"]
		var _suck_cess: bool = result_arr.append(result_pos);
	#compare each vector location y axis to each other, if it is greater than a given tolerance we call it uneven and dont allow placement
	var y_pos: float = result_arr[0].y
	for vec: Vector3 in result_arr:
		if (y_pos - vec.y  > .2):
			disable()
			return;
	#place the collision body along the vector that we found?
	col.global_position = Vector3(global_position.x, y_pos, global_position.z) #Since we didnt return uneven, lets move the collider to this spot as well?


func disable()->void:
	visible = false;
	INVALID_FLAG = true;
	col.disabled = true;
