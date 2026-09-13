class_name MapGridSpace
extends RefCounted
const GREEN_COLOR: Color = Color(0.471, 1.0, 0.471, 0.627) #green
const RED_COLOR: Color = Color(0.89, 0.0, 0.0, 0.42) #red
const REGULAR_COLOR: Color = Color(0.708, 0.708, 0.708, 0.4)
const YELLOW_COLOR: Color = Color(0.814, 0.707, 0.129, 0.4) #for when its not being highlighted
const GREEN_MATERIAL: StandardMaterial3D = preload("uid://cqv5j3d2sdxl6")
const RED_MATERIAL: StandardMaterial3D = preload("uid://c1xulthtr4co4")

var index: Array[int] = [0,0];
var rid_index: RID
var y_layer: float;
var used_flag: bool = false;
var highlight_flag: bool = false;
var invalid_flag: bool = false;
var invalid_depot_flag: bool = false;
var temporary_invalid_flag: bool = false;


func set_invalid_flag(setting: bool)->void:
	#visible = false;
	invalid_flag = setting;
	#col.disabled = true;

func clear_rid()->void:
	RenderingServer.free_rid(rid_index);

#func show_tile() ->void:
	#var mat: StandardMaterial3D = mesh.get_surface_override_material(0);
	#if(HIGHLIGHT_FLAG):
		#if(INVALID_FLAG):
			#if (mat.albedo_color != RED_COLOR):
				#mat.albedo_color = RED_COLOR;
		#elif(USED_FLAG):
			#if (mat.albedo_color != RED_COLOR):
				#mat.albedo_color = RED_COLOR;
		#elif(TEMPORARY_INVALID_FLAG):
			#if (mat.albedo_color != RED_COLOR):
				#mat.albedo_color = RED_COLOR;
		#else:
			#if (mat.albedo_color != GREEN_COLOR):
				#mat.albedo_color = GREEN_COLOR;
	#else:
		#if(INVALID_FLAG):
			#if (mat.albedo_color != RED_COLOR):
				#mat.albedo_color = RED_COLOR;
		#elif(USED_FLAG):
			#if (mat.albedo_color != YELLOW_COLOR):
				#mat.albedo_color = YELLOW_COLOR;
		#else:
			#if (mat.albedo_color != REGULAR_COLOR):
				#mat.albedo_color = REGULAR_COLOR;
