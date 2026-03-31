class_name CommandController
extends Node

##Used by the local player to initiate commands and send commands to the units
##Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
##this should not have to RPC its own functions, only the people it makes do things
##Selectable layer is on LAYER 5!
#reference Game because we need that for updating data
var game: GameScene;
var entity_holder: EntityHolder;

#used by GAME UI to show options for first unit
signal selected_signal(first_unit: Node3D);
signal deselected_signal();

var mouse_dragging: bool = false  # Are we currently dragging?
var selected: Array[Node3D] = []  # Array of selected units.
var drag_start_position: Vector2 = Vector2.ZERO  # Location where drag began.
@onready var selection_rect: ColorRect = $SelectionRect
@onready var target: MeshInstance3D = $Target

var groups_dict: Dictionary[int, Array] = {};

var active_unit: int = 0;

var pending_cmd: Dictionary = {};

var debug_int: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	target.hide();
	pass # Replace with function body.

func _process(_delta: float) -> void:
	if (selected.is_empty()):
		return;

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
	if event is InputEventMouseButton:
		var loc_dict: Dictionary = game.player_data_manager.player_dict[game.player_data_manager.local_id]
		#MOUSE PRESS LOGIC
		if(event.is_action_pressed("select")):
			#Pending Command Block
			if(!pending_cmd.is_empty() && !selected.is_empty()):
				if (selected[active_unit].color != loc_dict[PlayerDataManager.COLOR_KEY] && !DebugGlobal.master_control):
					pending_cmd = {};
					return;

				if(pending_cmd.has("cost")):
					if(pending_cmd["cost"][0] > loc_dict[PlayerDataManager.MINERAL_KEY] || pending_cmd["cost"][1] > loc_dict[PlayerDataManager.GAS_KEY]):
						return;

				#the pending command requires a location input
				if(pending_cmd.has("location")):
					var attack_move: bool = false; #If we are attack move, we switch to regular attack command for command
					if(pending_cmd["command"] == GlobalConstants.Commands.ATTACK_MOVE):
						attack_move = true;
					var result: Dictionary = get_world_click(); #returns null if object is empty
					if (result.is_empty()):
						return;
					var obj: Node3D = result["collider"];
					if ("ENTITY_TYPE" in obj && attack_move):
						var node_path : String = obj.get_path();
						pending_cmd = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
						pending_cmd["target_node_path"] = node_path;
						handle_cmd(pending_cmd);
					else:
						var location : Vector3 = result["position"];
						pending_cmd["location"] = location;
						handle_cmd(pending_cmd);
				#the pending command is targeting a node
				elif(pending_cmd.has("target_node_path")):
					var result: Dictionary = get_world_click(); #returns null if object is empty
					if (result.is_empty()):
						return;
					var obj: Node3D = result["collider"];
					if "ENTITY_TYPE" in obj:
						var node_path : String = obj.get_path();
						pending_cmd["target_node_path"] = node_path;
						handle_cmd(pending_cmd);
				pending_cmd = {};
				return
			#end pending command block

			#Check if we clicked on an object
			var _err: Error
			var cntrl: bool = Input.is_action_pressed("control");
			var result: Dictionary = get_world_click(); #returns null if object is empty
			#if we hit something
			if (!result.is_empty()):
				var obj: Node3D = result["collider"];
				if("ENTITY_NAME" in obj):
					#if we are not control click, or its not our unit, clear out our selection
					if(!cntrl  || obj.team != loc_dict[PlayerDataManager.TEAM_KEY]):
						clear_selection();
					var has_entity_in_selected: bool = false;
					for i:int in range(selected.size(),0, -1):
						if(is_same(selected[i-1],obj)):
							var e: Node3D = selected[i-1];
							e.unset_selected();
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
		#create commands vars outside of logic since they all use it i guess?
		var loc_dict: Dictionary = game.player_data_manager.player_dict[game.player_data_manager.local_id]
		var cmd: Dictionary = {};
		if (selected[active_unit].color != loc_dict[PlayerDataManager.COLOR_KEY] && !DebugGlobal.master_control):
			clear_selection();
			return;
		if(!pending_cmd.is_empty()):
			pending_cmd = {};
			return;
		var result: Dictionary = get_world_click();
		if (result.is_empty()):
			target.hide();
			return;
		var obj: Node3D = result["collider"];
		if ("ENTITY_TYPE" in obj):
			var target_node_path: String = obj.get_path();
			#duplication of command dictionary can be redundant since handle_cmd does this as well
			cmd = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
			cmd["target_node_path"] = target_node_path;
			target.hide();
			#unit
		else:
			cmd = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();
			var location: Vector3 = result["position"]
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

	#########
	#For ones that will require an argument like a location or target, set up so unhandled input will pick up the cmd
	#This will catch duplicated  commands that dont remove the argument section first
	if (p_cmd.has("argument")):
		#Only make it a pending command if this does not have an entry for the argument in question
		if(!p_cmd.has(p_cmd["argument"])):
			cmd[p_cmd["argument"]] = null;
			pending_cmd = cmd;
			return;
	#########
	#No argument needed or argument is filled, request the command
	var unit_path_arr: Array[String] = [];
	if(cmd["is_group"] == true):
		#group command
		for i: int in selected.size():
			unit_path_arr.append(selected[i].get_path())
	else:
		#individual command
		var unit_path: String = selected[active_unit].get_path();
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
	var arr: Array;
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
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,0x11);
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	return raycast_result;
	#if (raycast_result.is_empty()):
		#return null;
	#var obj: Node3D = raycast_result["collider"];
	#return obj;


func clear_selection() -> void:
	for node: Node3D in selected:
		node.unset_selected();
	selected.clear();
	deselected_signal.emit();
	pending_cmd = {};
