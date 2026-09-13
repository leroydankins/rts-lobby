class_name BuildingPreview
extends Node3D

const GREEN_COLOR: Color = Color(0.471, 1.0, 0.471, 0.627) #green
const RED_COLOR: Color = Color(0.89, 0.0, 0.0, 0.42) #red
const REGULAR_COLOR: Color = Color(0.708, 0.708, 0.708, 0.4)
const YELLOW_COLOR: Color = Color(0.814, 0.707, 0.129, 0.4) #for when its not being highlighted
const GREEN_MATERIAL: StandardMaterial3D = preload("uid://cqv5j3d2sdxl6")
const RED_MATERIAL: StandardMaterial3D = preload("uid://c1xulthtr4co4")
var mesh: Mesh = preload("uid://ccej8qr77u1p1")
@onready var building: MeshInstance3D = $Building
@onready var grid: MeshInstance3D = $Grid
## Each RID has a dictionary of the following fields
##[code] RID [/code] :  [int]
##[code] index[/code] :  [Vector3i]
##[code] position[/code] : [Vector3]
var rid_dic_array: Array[Dictionary];

var map_grid: MapGrid;

@export var current_size: Vector3i
@export var current_mesh: String;
@export var current_properties: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_grid = get_tree().get_first_node_in_group("map_grid");
	pass # Replace with function body.

func clear_data() ->void:
	update_mesh("");
	update_size(Vector3i.ZERO)
	update_properties([]);
	hide();

func update_preview_data(new_mesh: String, new_size: Vector3i, new_properties: Array)->void:
	update_mesh(new_mesh);
	update_size(new_size);
	update_properties(new_properties);
	show();

func hide_preview() ->void:
	hide();
	if(rid_dic_array):
		for rid_dic: Dictionary in rid_dic_array:
			RenderingServer.instance_set_visible(rid_dic["RID"],false)

func show_preview() ->void:
	show();
	if(rid_dic_array):
		for rid_dic: Dictionary in rid_dic_array:
			RenderingServer.instance_set_visible(rid_dic["RID"],true)

## Update Placement Function [br][br]
## Description: Takes in a new Vector3 representing the tiles in use and updates the [grid] mesh if it is not the current size [br][br]
## Inputs: [br]
## [Vector3] new_position [br]
## [Vector3i] start_index[br]
## Outputs: None [br]
func update_placement(new_center_position:Vector3, start_index: Vector3i) ->void:
	global_position = new_center_position;
	print(new_center_position)
	if(map_grid.is_tiles_valid(start_index, current_size, current_properties)):
		# We can call the tiles green!
		for rid_dic: Dictionary in rid_dic_array:
			## Obtain their Y height
			#var y_pos: float = map_grid.get_tile_y_value(start_index + rid_dic["index"])
			#var rid_pos: Vector3 = Vector3(rid_dic["position"].x, rid_dic["position"].y + y_pos, rid_dic["position"].z)
			# Update their transform
			RenderingServer.instance_set_transform(rid_dic["RID"], Transform3D(Basis(), new_center_position + rid_dic["position"])) # Need to update per tile location, not center po
			# Update their color
			RenderingServer.instance_geometry_set_material_override(rid_dic["RID"],GREEN_MATERIAL)
	else:
		# We can call the tiles red!
		for rid_dic: Dictionary in rid_dic_array:
			## Obtain their Y height
			#var y_pos: float = map_grid.get_tile_y_value(start_index + rid_dic["index"])
			#var rid_pos: Vector3 = Vector3(rid_dic["position"].x, rid_dic["position"].y + y_pos, rid_dic["position"].z)
			# Update their transform
			RenderingServer.instance_set_transform(rid_dic["RID"], Transform3D(Basis(), new_center_position + rid_dic["position"])) # Need to update per tile location, not center po
			# Update their color
			RenderingServer.instance_geometry_set_material_override(rid_dic["RID"],RED_MATERIAL)



## Update Mesh Function [br][br]
## Description: Takes in a string Unique ID of a mesh resource and updates the [property building] mesh if it is not the current mesh [br][br]
## Inputs: [String] new_mesh: UID of building mesh resource for preview of building [br]
## Outputs: None [br]
func update_mesh(new_mesh_string: String) ->void:
	if(current_mesh == new_mesh_string):
		return;
	if new_mesh_string == "":
		building.mesh = null;
	else:
		var new_mesh : Mesh  = load(new_mesh_string)
		building.mesh = new_mesh;
		var y_height: float = new_mesh.size.y * 0.5;
		building.position = Vector3(0,0 + y_height, 0);
	current_mesh = new_mesh_string;

## Update Mesh Function [br][br]
## Description: Takes in a new Vector3i representing the tiles in use and updates the grid's mesh if it is not the current size [br][br]
## Inputs: [Vector3i] new_size: Vector3i of grid size, Y is unused but allows for accessing vector in z direction for consistency [br]
## Outputs: None [br]
func update_size(new_size: Vector3i) ->void:
	if(current_size == new_size):
		return;
	current_size = new_size
	# Clear out all the current ones
	for rid_dic: Dictionary in rid_dic_array:
		RenderingServer.free_rid(rid_dic["RID"]);
	rid_dic_array = [];
	if (!current_size): # Evaluates to false if Vector3i = (0,0,0)
		return
	var xform: Transform3D
	var instance: RID;
	# Set the scenario from the world. This ensures it
	# appears with the same objects as the scene.
	var scenario: RID = get_world_3d().scenario;
	for i: int in range(current_size.x):
		for j: int in range(current_size.z):
			var x_float: float = float(current_size.x);
			var z_float: float = float(current_size.z);
			var x_pos: float = -(x_float / 2) + i + 0.5
			var z_pos: float = -(z_float / 2) + j + 0.5
			var relative_pos: Vector3 = Vector3(x_pos, .25, z_pos)
			# Create a visual instance (for 3D).
			instance= RenderingServer.instance_create()
			RenderingServer.instance_set_scenario(instance, scenario)
			# Add a mesh to it.
			# Remember to keep this reference.
			RenderingServer.instance_set_base(instance, mesh)
			# Move the mesh around.
			xform = Transform3D(Basis(), global_position + Vector3(x_pos, .25, z_pos))
			RenderingServer.instance_set_transform(instance, xform)
			RenderingServer.instance_geometry_set_transparency(instance,.5)
			print(xform)
			var rid_dictionary: Dictionary = {
				"RID" = instance,
				"index" = Vector3i(i,0,j), # Give me a second
				"position" = relative_pos
			}
			rid_dic_array.append(rid_dictionary);

	#RenderingServer.instance_set_visible(rid_array[3],false)
	#RenderingServer.instance_geometry_set_material_override(rid_array[6],RED_MATERIAL)
	## update the mesh on all instances that use it, so can be useful
	#RenderingServer.mesh_surface_set_material(mesh.get_rid(),0,GREEN_MATERIAL);
	#print("time to do this coloring in microseconds is %s usec" % [Time.get_ticks_usec() - time3])

func update_properties(new_properties: Array) ->void:
	if(current_properties == new_properties):
		return;
	current_properties = new_properties
