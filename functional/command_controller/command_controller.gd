class_name CommandController
extends Node

## Used by the local player to initiate commands and send commands to the units
## Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
## this should not have to RPC its own functions, only the people it makes do things
## Selectable layer is on LAYER 5!

const MAP_GRID_COLLISION_MASK: int = 0b1000000000000; #layer 13
const WORLD_ENTITY_COLLISION_MASK: int = 0b10001; #layer 5 and 1
const WORLD_COLLISION_MASK: int = 0b1 #layer 1

## Used by the local player to initiate commands and send commands to the units
## Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
## this should not have to RPC its own functions, only the people it makes do things
## Selectable layer is on LAYER 5!
# reference Game because we need that for updating data
var game: GameScene;
var entity_holder: EntityHolder;
var map_grid: MapGrid;
var state_manager: StateManager;

#used by GAME UI to show options for first unit
signal selected_signal(first_unit: Node3D);
signal deselected_signal();

var mouse_dragging: bool = false  # Are we currently dragging?
var selected: Array[Node3D] = []  # Array of selected units.
var drag_start_position: Vector2 = Vector2.ZERO  # Location where drag began.
@onready var selection_rect: ColorRect = $SelectionRect
@onready var target: MeshInstance3D = $Target
@onready var building_preview: BuildingPreview = $BuildingPreview
@onready var target_mesh : Resource = preload("uid://byfj4352ef6tj")



var groups_dict: Dictionary[int, Array] = {};

var active_unit: int = 0;

var pending_cmd: Dictionary = {};

var debug_int: int = 0;


## Used for discarding un-needed return values
var _discard: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("game");
	entity_holder = get_tree().get_first_node_in_group("entity_holder");
	map_grid = get_tree().get_first_node_in_group("map_grid");
	state_manager = get_tree().get_first_node_in_group("state_manager")
	target.hide();


func _process(_delta: float) -> void:
	# Consider moving this to input someday? Not sure
	# Initial boolean checks before initializing all local variables
	# we do not update our display if we have the menu open
	if (
		state_manager.is_in_menu() or selected.is_empty()
		or pending_cmd.is_empty() or !pending_cmd.has("grid_location")
	):
		return;
	var result: Dictionary;
	var pos: Vector3;
	## this will be the floor int value of the collider position based on vertex
	var index: Vector3i;
	## we want to snap to grid tile corners if its an even tile_size, if its odd we want dead center of center
	var preview_position: Vector3
	var size: Vector3i;
	var start_index: Vector3i;
	var x_displacement: int
	var z_displacement: int
	result = get_world_raycast(MAP_GRID_COLLISION_MASK);
	# Combining the if check to make this clearer but may cause an issue
	if (!result or !map_grid.is_location_in_tile_layer(result["position"])): #if the dictionary is empty
		building_preview.hide_preview();
		return;
	building_preview.show_preview();
	pos = result["position"];
	index = Vector3i(floor(pos.x), 0, floor(pos.z));
	size = Vector3i(pending_cmd["tile_size"][0], 0, pending_cmd["tile_size"][1]);
	preview_position = pos;
	x_displacement = floori(float(size.x) / 2)  # if tile_size is 9, this would be 9 - 5 = 4;, if this was 8, this would be 8 - 4 = 4
	z_displacement = floori(float(size.z) / 2) # maybe we dont need to do an int and we can instead just div
	if (size.x % 2): # tile.x is odd, we want to get the x starting value

		preview_position.x = floori(pos.x) + .5 # preview middle positionposition
	else: # tile.x is even
		preview_position.x = roundi(pos.x) # preview middle position
		#if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
		if ((pos.x - floori(pos.x)) >  0.5):
			x_displacement -= 1
	start_index.x = index.x - x_displacement
	if (size.z % 2): # tile.z size is odd
		preview_position.z = floori(pos.z) + .5
	else: # tile.z size is even
		preview_position.z = roundi(pos.z)
		# if it is on the upper end of the tile we do subtract one less value from start index (displacement is a negative)
		if ((pos.z - floori(pos.z)) >  0.5):
			z_displacement -= 1
	start_index.z = index.z - z_displacement
	# Call to building_preview to move preview to new location at X!
	building_preview.update_placement(preview_position,start_index);
# end Process

func _unhandled_input(event: InputEvent) -> void:
	## Local reference to our individual player information, passed by reference from [PlayerDataManager]
	var local_dict: Dictionary = game.player_data_manager.player_dict[game.player_data_manager.local_id]
	if event is InputEventMouseButton:
		# MOUSE PRESS LOGIC
		if(event.is_action_pressed("select")):

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
				if (selected[active_unit].color != local_dict[PlayerDataManager.COLOR_KEY] && !DebugGlobal.master_control):
					clear_pending_cmd();
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
							clear_pending_cmd();
							return;
					else:
						location = result["position"];
						pending_cmd["location"] = location;
# / if(pending_cmd.has("location")):

				# the pending command is targeting a node
				elif(pending_cmd.has("target_node_path")):
					result = get_world_click(); #returns null if object is empty
					if (result.is_empty()):
						return;
					obj = result["collider"];
					if "ENTITY_TYPE" in obj:
						node_path = obj.get_path();
						pending_cmd["target_node_path"] = node_path;
# / elif(pending_cmd.has("target_node_path")):

# elif(pending_cmd.has("grid_location")):
				elif(pending_cmd.has("grid_location")):
					# Local Var Defines
					building_properties = pending_cmd["building_properties"];

					# Breakout array into ints for clarity on function calls
					tile_size = pending_cmd["tile_size"];
					x_size = tile_size[0];
					z_size = tile_size[1];

					result = get_world_raycast(MAP_GRID_COLLISION_MASK)
					if(!result):
						clear_pending_cmd();
						return;
					result_position = result["position"];

					# Input the position and size to get the dictionary needded for placement
					resultant_grid_dictionary = map_grid.get_building_placement_dictionary(result_position, x_size, z_size, building_properties);

					# If this was not a part of the grid we quit and return
					if(!resultant_grid_dictionary):
						clear_pending_cmd();
						return;

					# Add gained grid_tile data and associated world position to command
					pending_cmd.merge(resultant_grid_dictionary)
# /elif(pending_cmd.has("grid_location")):

# End of conditional pending command, if this was reached we have a valid command
				# Remove the argument so handle command processes correctly
				_discard = pending_cmd.erase("argument")
				# Send back to handle_cmd function
				handle_cmd(pending_cmd)
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

			# entity is not a unit aka, its scenery or doesnt exist, lets set start dragging
			# we made it through and we didnt select anything
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
		# END OF LEFT MOUSE CLICK LOGIC
	# LEFT MOUSE DRAG LOGIC
	if mouse_dragging && event is InputEventMouseMotion:
		var m_start : Vector2 = drag_start_position;
		var m_end: Vector2 = event.position;

		var diff :Vector2 = m_end - m_start;
		var rect : Rect2 = Rect2(m_start, diff).abs();
		selection_rect.position = rect.position;
		selection_rect.size = rect.size;
	# END OF LEFT MOUSE DRAG LOGIC

	# ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;
	# Unneccessary check when in the future they will be validated as entities?
	if(!"cmd_dict" in selected[active_unit]):
		return;

	# RIGHT CLICK LOGIC
	if (event.is_action_pressed("action")):
		building_preview.clear_data()

		var cmd: Dictionary = {};
		var target_node_path: String;
		var obj: Node3D
		var result: Dictionary
		var location: Vector3
		if (selected[active_unit].color != local_dict[PlayerDataManager.COLOR_KEY] && !DebugGlobal.master_control):
			clear_selection();
			return;
		if(!pending_cmd.is_empty()):
			clear_pending_cmd();
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

## Clears the pending command and all associated nodes referencing pending command data [br][br]
## Removes the current preview mesh and preview grid tiles from display in building_preview
## Hides building_preview
func clear_pending_cmd() ->void:
	pending_cmd = {};
	building_preview.clear_data();

func clear_selection() -> void:
	for node: Node3D in selected:
		node.unset_selected();
	selected.clear();
	deselected_signal.emit();
	clear_pending_cmd();

# local method that is called before requesting the command over the server. If additional arguments required will defer cmd, otherwise will continue to request_unit_cmd
func handle_cmd(p_cmd: Dictionary) -> void:
	# Clear out any current command we have in pending command
	clear_pending_cmd();
	# ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;
	# create a new dictionary to not overwrite data incase this comes from the cmd gui
	var cmd: Dictionary = p_cmd.duplicate();
	var unit_path_arr: Array[String] = [];
	var unit_path: String
	var building_properties: Array;
	var preview_string: String;
	var tile_size: Vector3i;

	# For ones that will require an argument like a location or target, set up so unhandled input will pick up the cmd
	# This will catch duplicated commands that dont remove the argument section first
	if (cmd.has("argument")):
		if (cmd["argument"] is Array):
			for arg: String in cmd["argument"]:
				if(!cmd.has(arg)):
					cmd[arg] = null;
				if (arg == "grid_location"):
					# We will perhaps move this to background thread loading
					# TODO update this to reflect new grid
					if(cmd.has("grid_location")):
						# Will start updating location as a grid object
						tile_size = Vector3i(cmd["tile_size"][0], 0, cmd["tile_size"][1]);
						building_properties = cmd["building_properties"];
						preview_string = cmd["entity_preview"]
						building_preview.update_preview_data(preview_string,tile_size,building_properties)
			pending_cmd = cmd;
			return;
		else:
			# Only make it a pending command if this does not have an entry for the argument in question
			if(!cmd.has(cmd["argument"])):
				cmd[cmd["argument"]] = null;
				pending_cmd = cmd;
				return;
	# /end if cmd.has("argument")
	# group command
	if(cmd["is_group"] == true):
		for i: int in selected.size():
			unit_path_arr.append(selected[i].get_path())
	# individual command
	else:
		unit_path = selected[active_unit].get_path()
		unit_path_arr.append(unit_path);
		if(active_unit < selected.size() - 1):
			active_unit+= 1
		else:
			active_unit = 0
	# We must check if the command is queueable and we are queueing when we HANDLE the command, because doing it in RPC will not read local input
	if (Input.is_action_pressed("shift")):
		if (cmd["can_queue"] == true):
			# queue not an initialized term in each command, only created in this scenario and used by the receiving unit
			cmd["queue"] = true;
		pending_cmd = cmd;
	else:
		clear_pending_cmd();
	request_unit_cmd.rpc_id(get_multiplayer_authority(), unit_path_arr, cmd, game.player_data_manager.local_id); # We will need to fix this
#end handle_cmd

## client RPCs server/host to start the action, final checks here before sending command
@rpc("any_peer","call_local","reliable")
func request_unit_cmd(unit_path_arr: Array[String], cmd: Dictionary, player_id: int) ->void:
	if (!is_multiplayer_authority()):
		return;
	var player_dict: Dictionary = game.player_data_manager.player_dict[player_id];
	var target_entity: Entity; # Cast as entity in the future?
	var mineral_cost: int
	var gas_cost: int
	var node_path: String
	var cmd_time: float
	var logged_cmd: Dictionary
	## newly constructed command so that no 2 units are accessing same dictionary data [br][br]
	var constructed_cmd: Dictionary
	# Check unit type
	for unit_path: String in unit_path_arr:
		target_entity = get_tree().root.get_node(unit_path)
		if("ENTITY_TYPE" not in target_entity): # This currently is the workaround for Entity class
			continue;
		if(target_entity.color != player_dict[PlayerDataManager.COLOR_KEY]): # this does work because the player id is passed into local var player_dict
			if(!DebugGlobal.master_control):
				continue;
		# check if cmd has a cost to it and deny if cant afford
		if(cmd.has("cost")):
			mineral_cost = cmd["cost"][0];
			gas_cost = cmd["cost"][1];
			if (mineral_cost > player_dict[PlayerDataManager.MINERAL_KEY]):
				# Cannot do the command, play an error sound to show they couldnt do it yet
				continue;
			if (gas_cost > player_dict[PlayerDataManager.GAS_KEY]):
				# Cannot do the command, play an error sound to show they couldnt do it yet
				continue;
		node_path = target_entity.get_path();
		cmd_time = game.get_elapsed_time();
		constructed_cmd = cmd.duplicate();

		# The host is calling this function already, request the command
		target_entity.request_cmd.rpc_id(get_multiplayer_authority(), constructed_cmd);
		# We may not need to RPC this if we are already the authority as Command Controller

		logged_cmd = {
			#ReplayConstants.TIME_KEY
			"time" = cmd_time,
			#ReplayConstants.PATH_KEY
			"path" = node_path,
			#ReplayConstants.COMMAND_KEY
			"command" = cmd,
		}
		# Currently doesnt do anything yet
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
				selected.append(unit);
	if(selected.is_empty()):
		for unit: Node3D in all_entities:
			if(rect.has_point(cam.unproject_position(unit.global_position))):
				unit.set_selected();
				selected.append(unit);
				return;
	if(!selected.is_empty()):
		selected_signal.emit(selected[0])
	pass;
