class_name GridTile
extends Area3D

var index: Array[int] = [0,0];
const GREEN_COLOR: Color = Color(0.471, 1.0, 0.471, 0.627) #green
const RED_COLOR: Color = Color(0.89, 0.0, 0.0, 0.42) #red
const REGULAR_COLOR: Color = Color(0.708, 0.708, 0.708, 0.4)
const YELLOW_COLOR: Color = Color(0.814, 0.707, 0.129, 0.4) #for when its not being highlighted
var HIGHLIGHT_FLAG: bool = false;
var INVALID_FLAG: bool = false;
var USED_FLAG: bool = false;
var INVALID_DEPOT_FLAG: bool = false;
var TEMPORARY_INVALID_FLAG: bool = false;


@export var units: Array[Node3D] = [];
@onready var mesh: MeshInstance3D = $Mesh

func _ready() ->void:
	#mouse_entered.connect(on_mouse_ent);
	#mouse_exited.connect(on_mouse_ex);
	var mat: StandardMaterial3D = mesh.get_surface_override_material(0);
	mat.albedo_color = REGULAR_COLOR;
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;

func _process(_delta: float) -> void:
	if(!visible): return;
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
	print("in");
	HIGHLIGHT_FLAG = true;

func on_mouse_ex() ->void:
	print("out")
	HIGHLIGHT_FLAG = false;
