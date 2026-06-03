class_name CommandController
extends Node

## Used by the local player to initiate commands and send commands to the units
## Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
## this should not have to RPC its own functions, only the people it makes do things
## Selectable layer is on LAYER 5!

const BUILDING_GRID_COLLISION_MASK: int = 0b1000000000000; #layer 13
const WORLD_ENTITY_COLLISION_MASK: int = 0b10001; #layer 5 and 1
const WORLD_COLLISION_MASK: int = 0b1 #layer 1

## Used by the local player to initiate commands and send commands to the units
## Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
## this should not have to RPC its own functions, only the people it makes do things
## Selectable layer is on LAYER 5!
#reference Game because we need that for updating data
var game: GameScene;
var entity_holder: EntityHolder;
var map_grid: MapGrid;

#used by GAME UI to show options for first unit
signal selected_signal(first_unit: Node3D);
signal deselected_signal();

var mouse_dragging: bool = false  # Are we currently dragging?
var selected: Array[Node3D] = []  # Array of selected units.
var drag_start_position: Vector2 = Vector2.ZERO  # Location where drag began.
@onready var selection_rect: ColorRect = $SelectionRect
@onready var target: MeshInstance3D = $Target
@onready var preview_mesh: MeshInstance3D = $PreviewMesh
@onready var target_mesh : Resource = preload("uid://byfj4352ef6tj")

var groups_dict: Dictionary[int, Array] = {};

var active_unit: int = 0;

var pending_cmd: Dictionary = {};

var debug_int: int = 0;
## Used in Process functions for showing the preview mesh
var previous_index: Array[int] = []; #we use this so we dont have to do all the math every frame maybe?
var previous_size: Array = [];
var prev_x_bool: bool;
var prev_z_bool: bool;

## Used for discarding un-needed return values
var _discard: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	map_grid = get_tree().get_first_node_in_group("MapGrid");

	target.hide();


func _process(_delta: float) -> void:
	if (selected.is_empty()):
		preview_mesh.hide();
		return;
	if (pending_cmd.is_empty()):
		preview_mesh.hide();
		return;
	if (pending_cmd.has("entity_preview")):
		preview_mesh.hide();
		return;
	var result: Dictionary;
	var pos: Vector3;
	var tile_index: Array[int]; ## this will be the floor int value of the collider position based on vertex
	var tile_size: Array; ## this is how many tiles we take up with our building, untyped due to constant in thing
	var x_bool: bool;
	var z_bool: bool;
	## we want to snap to grid tile corners if its an even tile_size, if its odd we want dead center of center
	var mesh_x: float
	var mesh_y: float ## We will have the meshes auto size so that we dont have to move the pos aside from terrain height
	var mesh_z: float
	var x_size: int
	var z_size: int
	var x_start_index: int;
	var z_start_index: int;
	var x_displacement: int
	var z_displacement: int
	var mesh: Mesh #declaring it here helps with an unsafe access warning on the var y line

	result = get_world_raycast(BUILDING_GRID_COLLISION_MASK);
	if (!result): #if the dictionary is empty
		prev_x_bool = 0;
		prev_z_bool = 0;
		previous_index = [];
		previous_size = [];
		if(preview_mesh.visible):
			preview_mesh.hide();
			map_grid.clear_highlight();
	else: #dictionary is not empty
		pos = result["position"];
		# Define the mesh's Y pos early because we can
		mesh_y = pos.y
		tile_index= [floori(pos.x),floori(pos.z)];
		tile_size = pending_cmd["tile_size"];
		x_size = tile_size[0];
		z_size = tile_size[1];
		if(!map_grid.is_location_in_tile_layer(pos)):
			preview_mesh.hide();
			map_grid.clear_highlight();
			return;

		if(!preview_mesh.visible):
			preview_mesh.show();
			#clear temporary flags

		if(preview_mesh.mesh == null):
			#We will perhaps move this to background thread loading
			mesh = load(pending_cmd["entity_preview"]);
			preview_mesh.mesh = mesh
		else:
			mesh = preview_mesh.mesh;

		if (tile_index == previous_index && tile_size == previous_size): #this is to deal with micro-tile adjustments?
			if (pos.x - floori(pos.x) > .5): #if we didnt change which tile in the x direction
				x_bool = 1;
			if (pos.z - floori(pos.z) > .5): #if we didnt change which tile in the z direction
				z_bool = 1;
			if (x_bool == prev_x_bool && z_bool == prev_z_bool):
				return;
			else:
				prev_x_bool = x_bool;
				prev_z_bool = z_bool;
				map_grid.clear_highlight()
		else:
			map_grid.clear_highlight();

		x_displacement = floori(float(x_size) / 2)  #if tile_size is 9, this would be 9 - 5 = 4;, if this was 8, this would be 8 - 4 = 4
		z_displacement = floori(float(z_size) / 2) #maybe we dont need to do an int and we can instead just div
		if (x_size % 2): #if the xtile_size is odd, we want to get the x starting value
				mesh_x = floori(pos.x) + .5 #mesh position
				x_start_index = tile_index[0] - x_displacement #if index is 13, this would be 14 - 2 = 12, then 12,13,14,15,16 would be lit for x tiles
		else: #if the x tile_size is even
			mesh_x = roundi(pos.x) #mesh position
			#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
			if ((pos.x - floori(pos.x)) >  0.5):
				x_displacement -= 1
			x_start_index = tile_index[0] - x_displacement

		if (z_size % 2): #if the z tile_size is odd
			mesh_z = floori(pos.z) + .5
			z_start_index = tile_index[1] - z_displacement
		else: #if the z tile_size is even
			mesh_z = roundi(pos.z) #for mesh position
			#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
			if ((pos.z - floori(pos.z)) >  0.5):
				z_displacement -= 1
			z_start_index = tile_index[1] - z_displacement

		map_grid.highlight_tiles(x_start_index,z_start_index, tile_size);
		preview_mesh.global_position = Vector3(mesh_x,mesh_y,mesh_z);
		previous_index = tile_index;
		previous_size = tile_size;
#end Process


func select_units_2d_projected() -> void:
	var loc_dict: Dictionary = game.player_data_manager.player_dict[game.player_data_manager.local_id]
	if(!Input.is_action_pressed("control") || selected[0].team != loc_dict[PlayerDataManager.TEAM_KEY]):
		clear_selection();
	var cam: Camera3D = get_viewport().get_camera_3d();
	var rect: Rect2 = Rect2();
	rect.position = selection_rect.position;
	rect.size = selection_rect.size;
	var all_entities: Array[Node3D] = entity_holder.global_entity_array;
	var all_units : Array[Node3D] = entity_holder.global_unit_array;
	for unit: Node3D in all_units:
		if(rect.has_point(cam.unproject_position(unit.global_position))):
			if(unit.team == loc_dict[PlayerDataManager.TEAM_KEY]):
				unit.set_selected();
				print("what")
				selected.append(unit);
	if(selected.is_empty()):
		for unit: Node3D in all_entities:
			if(rect.has_point(cam.unproject_position(unit.global_position))):
				unit.set_selected();
				selected.append(unit);
				return;
	if(!selected.is_empty()):
		print("selected uniuts!!")
		selected_signal.emit(selected[0])
	pass;


func _unhandled_input(event: InputEvent) -> void:
	## Local reference to our individual player information, passed by reference from [PlayerDataManager]
	var local_dict: Dictionary = game.player_data_manager.player_dict[game.player_data_manager.local_id]
	if event is InputEventMouseButton:
		# MOUSE PRESS LOGIC
		if(event.is_action_pressed("select")):
			var cmd_duplicate: Dictionary
			var result: Dictionary
			var obj: Node3D;
			var location: Vector3
			var _err: Error
			var cntrl: bool
			var node_path: String;
			# Attack Move Vars
			var attack_move: bool
			# Grid Location Vars
			var building_properties: Array;
			var tile_size: Array
			var x_size: int
			var z_size: int
			var result_position: Vector3
			var resultant_grid_dictionary: Dictionary
			# Vars used in Selecting
			## Used when control clicking an object to see if we have already selected it [br]
			## If we have the objected in our selected array already, we unselect it
			var has_entity_in_selected: bool;

			# Pending Command Block
			if(!pending_cmd.is_empty() && !selected.is_empty()):
				cmd_duplicate = pending_cmd.duplicate();
				if (selected[active_unit].color != local_dict[PlayerDataManager.COLOR_KEY] && !DebugGlobal.master_control):
					pending_cmd = {};
					return;

				if(pending_cmd.has("cost")):
					if(pending_cmd["cost"][0] > local_dict[PlayerDataManager.MINERAL_KEY] || pending_cmd["cost"][1] > local_dict[PlayerDataManager.GAS_KEY]):
						return;
				# copy command before we edit the arguments

				# the pending command requires a location input
				if(pending_cmd.has("location")):
					attack_move = false; #If we are attack move, we switch to regular attack command for command
					if(pending_cmd["command"] == GlobalConstants.Commands.ATTACK_MOVE):
						attack_move = true;
					result = get_world_click(); #returns null if object is empty
					if (result.is_empty()):
						return;
					obj = result["collider"];
					if ("ENTITY_TYPE" in obj):
						if(attack_move):
							node_path = obj.get_path();
							pending_cmd = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
							pending_cmd["target_node_path"] = node_path;

					else:
						location = result["position"];
						pending_cmd["location"] = location;

				#the pending command is targeting a node
				elif(pending_cmd.has("target_node_path")):
					result = get_world_click(); #returns null if object is empty
					if (result.is_empty()):
						return;
					obj = result["collider"];
					if "ENTITY_TYPE" in obj:
						node_path = obj.get_path();
						pending_cmd["target_node_path"] = node_path;

				# /elif(pending_cmd.has("target_node_path")):

				#used for placing or checking locations on the building grid
				elif(pending_cmd.has("grid_location")):
					# Local Var Defines
					building_properties = pending_cmd["building_properties"];

					# Breakout array into ints for clarity on function calls
					tile_size = pending_cmd["tile_size"];
					x_size = tile_size[0];
					z_size = tile_size[1];

					result = get_world_raycast(BUILDING_GRID_COLLISION_MASK)
					if(!result):
						pending_cmd = {};
						preview_mesh.hide();
						return;
					result_position = result["position"];

					if(!map_grid.is_location_in_tile_layer(result_position)):
						pending_cmd = {};
						preview_mesh.hide();
						return;

					# Input the position and size to get the dictionary needded for placement
					resultant_grid_dictionary = map_grid.get_building_placement_dictionary(result_position, x_size, z_size, building_properties);

					# If this was not a part of the grid we quit and return
					if(!resultant_grid_dictionary):
						pending_cmd = {};
						preview_mesh.hide();
						return;

					# Add gained grid_tile data and associated world position to command
					pending_cmd.merge(resultant_grid_dictionary)
				# /elif(pending_cmd.has("grid_location")):

				# End of conditional pending command, if this was reached we have a valid command

				# Clear data
				preview_mesh.mesh = null;
				preview_mesh.hide()
				map_grid.hide_tiles();
				map_grid.clear_highlight();
				# Remove the argument so handle command processes correctly
				_discard = pending_cmd.erase("argument")
				# Send back to handle_cmd function
				handle_cmd(pending_cmd)
				if(Input.is_action_pressed("shift")):
					pending_cmd = cmd_duplicate;
				else:
					pending_cmd = {};
				return
			# End pending command block

			# Check if we clicked on an object
			cntrl = Input.is_action_pressed("control");
			result = get_world_click(); #returns null if object is empty

			# If we hit something with our click
			if (!result.is_empty()):
				obj = result["collider"];
				if("ENTITY_NAME" in obj):
					# If we are not control click, or its not our unit, clear out our selection
					if(!cntrl  || obj.team != local_dict[PlayerDataManager.TEAM_KEY]):
						clear_selection();

					has_entity_in_selected = false;
					for i : int in range(selected.size(),0, -1):
						if(is_same(selected[i-1],obj)):
							# Tell the specific unit it is no longer selected if it was already in our array
							selected[i-1].unset_selected();
							selected.remove_at(i-1);
							has_entity_in_selected = true;
					if(!has_entity_in_selected):
						obj.set_selected();
						selected.append(obj);
					selected_signal.emit(selected[0]);
					return;

			#if we didn't hit anything
			else:
				if (!cntrl):
					clear_selection();

			#entity is not a unit aka, its scenery or doesnt exist, lets set start dragging
			#we made it through and we didnt select anything
			mouse_dragging = true;
			drag_start_position = event.position;
			selection_rect.show();
			selection_rect.position =drag_start_position;
			selection_rect.size = Vector2.ZERO;

		elif (event.is_action_released("select")):
			if(mouse_dragging == true):
				select_units_2d_projected()
			mouse_dragging = false;
			selection_rect.hide();


		#END OF MOUSE PRESS LOGIC

	if mouse_dragging && event is InputEventMouseMotion:
		var m_start : Vector2 = drag_start_position;
		var m_end: Vector2 = event.position;

		var diff :Vector2 = m_end - m_start;
		var rect : Rect2 = Rect2(m_start, diff).abs();
		selection_rect.position = rect.position;
		selection_rect.size = rect.size;

	#End left click actions

	#ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;

	if(!"cmd_dict" in selected[active_unit]):
		return;

	#RIGHT CLICK LOGIC
	if (event.is_action_pressed("action")):
		preview_mesh.hide();

		var cmd: Dictionary = {};
		var target_node_path: String;
		var obj: Node3D
		var result: Dictionary
		var location: Vector3
		if (selected[active_unit].color != local_dict[PlayerDataManager.COLOR_KEY] && !DebugGlobal.master_control):
			clear_selection();
			return;
		if(!pending_cmd.is_empty()):
			pending_cmd = {};
			return;
		result = get_world_click();
		if (result.is_empty()):
			target.hide();
			return;
		obj = result["collider"];
		if ("ENTITY_TYPE" in obj):
			target_node_path = obj.get_path();
			#duplication of command dictionary can be redundant since handle_cmd does this as well
			cmd = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
			cmd["target_node_path"] = target_node_path;
			target.hide();
			#unit
		else:
			cmd = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();
			location = result["position"]
			cmd["location"] = location;
			target.global_position = location;
			target.show();
		handle_cmd(cmd);


#local method that is called before requesting the command over the server. If additional arguments required will defer cmd, otherwise will continue to request_unit_cmd
func handle_cmd(p_cmd: Dictionary) -> void:
	#ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;
	#create a new dictionary to not overwrite data incase this comes from the cmd gui
	var cmd: Dictionary = p_cmd.duplicate();
	var unit_path_arr: Array[String] = [];
	var unit_path: String
	#########
	# For ones that will require an argument like a location or target, set up so unhandled input will pick up the cmd
	# This will catch duplicated commands that dont remove the argument section first
	if (cmd.has("argument")):
		if (cmd["argument"] is Array):
			for arg: String in cmd["argument"]:
				if(!cmd.has(arg)):
					cmd[arg] = null;
				if (arg == "grid_location"):
					map_grid.display_tiles()
			pending_cmd = cmd;
			return;
		else:
			#Only make it a pending command if this does not have an entry for the argument in question
			if(!cmd.has(cmd["argument"])):
				cmd[cmd["argument"]] = null;
				pending_cmd = cmd;
				return;
	#########
	#No argument needed or argument is filled, request the command
	if(cmd["is_group"] == true):
		#group command
		for i: int in selected.size():
			unit_path_arr.append(selected[i].get_path())
	else:
		#individual command
		unit_path = selected[active_unit].get_path();
		unit_path_arr.append(unit_path);
		if(active_unit < selected.size() - 1):
			active_unit+= 1;
		else:
			active_unit = 0
	##We must check if the command is queueable and we are queueing when we HANDLE the command, because doing it in RPC will not read local input
	if (Input.is_action_pressed("shift") && cmd["can_queue"] == true):
			#queue not an initialized term in each command, only created in this scenario
			cmd["queue"] = true;

	request_unit_cmd.rpc_id(get_multiplayer_authority(), unit_path_arr, cmd,game.player_data_manager.local_id); #We will need to fix this
#end handle_cmd

#client RPCs server/host to start the action, final checks here before sending command
@rpc("any_peer","call_local","reliable")
func request_unit_cmd(unit_path_arr: Array[String], cmd: Dictionary, player_id: int) ->void:
	var player_dict: Dictionary = game.player_data_manager.player_dict[player_id];
	for unit_path: String in unit_path_arr:
		var unit: Node3D = get_tree().root.get_node(unit_path)
		if("ENTITY_TYPE" not in unit):
			continue;
		if(unit.color != player_dict[PlayerDataManager.COLOR_KEY]): #this doesnt work because its called on the server
			if(!DebugGlobal.master_control):
				continue;
		#check if cmd has a cost to it and deny if cant afford
		if(cmd.has("cost")):
			var mineral_cost: int = cmd["cost"][0];
			var gas_cost: int = cmd["cost"][1];
			if (mineral_cost > player_dict[PlayerDataManager.MINERAL_KEY]):
				#Cannot do the command, play an error sound to show they couldnt do it yet
				continue;
			if (gas_cost > player_dict[PlayerDataManager.GAS_KEY]):
				#Cannot do the command, play an error sound to show they couldnt do it yet
				continue;

		var node_path: String = unit.get_path();
		var cmd_time: float = game.get_elapsed_time();
		unit.request_cmd.rpc_id(get_multiplayer_authority(), cmd);

		var logged_cmd: Dictionary = {
			#ReplayConstants.TIME_KEY
			"time" = cmd_time,
			#ReplayConstants.PATH_KEY
			"path" = node_path,
			#ReplayConstants.COMMAND_KEY
			"command" = cmd,
		}
		ReplayManager.log_cmd(logged_cmd)



func get_click_pos() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_length: int = 100
	var camera: Camera3D = get_viewport().get_camera_3d();
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;

	#To get intersection with colliders
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,1);
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)

	if (raycast_result.is_empty()):
		return Vector3.ZERO;
	else:
		return raycast_result["position"]

func get_world_click() -> Dictionary:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_length: int = 100
	var camera: Camera3D = get_viewport().get_camera_3d();
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,0b10001); #this is layer 5 and 1 for unit and world
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	return raycast_result;

func get_world_raycast(collision_mask: int) -> Dictionary:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_length: int = 100
	var camera: Camera3D = get_viewport().get_camera_3d();
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,collision_mask);
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	return raycast_result;

func clear_selection() -> void:
	for node: Node3D in selected:
		node.unset_selected();
	selected.clear();
	deselected_signal.emit();
	pending_cmd = {};
