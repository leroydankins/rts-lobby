class_name CommandController
extends Node

##Used by the local player to initiate commands and send commands to the units
##Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
##this should not have to RPC its own functions, only the people it makes do things

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	pass # Replace with function body.


func select_units_2d_projected() -> void:
	if(!Input.is_action_pressed("control") || selected[0].player_id != game.local_game_dict[game.PLAYER_ID_KEY]):
		clear_selection();
	var cam: Camera3D = get_viewport().get_camera_3d();
	var rect: Rect2 = Rect2();
	rect.position = selection_rect.position;
	rect.size = selection_rect.size;
	var all_entities: Array[Node3D] = entity_holder.entity_array;
	var all_units : Array[Node3D] = entity_holder.unit_array;
	for unit: Node3D in all_entities:
		print(unit);
		if(rect.has_point(cam.unproject_position(unit.global_position))):
			if(unit.player_id == game.local_game_dict[game.PLAYER_ID_KEY]):
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


func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("escape")):
		clear_selection();
	if event is InputEventMouseButton:
		#MOUSE PRESS LOGIC
		if(event.is_action_pressed("select")):
			#Pending Command Block
			if(!pending_cmd.is_empty() && !selected.is_empty()):
				if (selected[active_unit].team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
					pending_cmd = {};
					return;

				if(pending_cmd.has("cost")):
					if(pending_cmd["cost"][0] > game.local_game_dict[game.PLAYER_RESOURCE_KEY] || pending_cmd["cost"][1] > game.local_game_dict[game.PLAYER_GAS_KEY]):
						print("cannot accept command, but not removing the pending command from selection");
						return;

				#the pending command requires a location input
				if(pending_cmd.has("location")):
					var pos : Vector3 = get_click_pos();
					if(!pos == Vector3.ZERO):
						pending_cmd["location"] = get_click_pos();
						request_unit_cmd(selected[active_unit], pending_cmd);
					else: return;

				#the pending command is targeting a node
				elif(pending_cmd.has("target_node_path")):
					var mouse_pos: Vector2 = get_viewport().get_mouse_position()
					var ray_length: int = 100
					var camera: Camera3D = get_viewport().get_camera_3d();
					var from: Vector3 = camera.project_ray_origin(mouse_pos)
					var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
					var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
					var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
					ray_query.from = from
					ray_query.to = to
					ray_query.collide_with_areas = true
					var raycast_result: Dictionary = space.intersect_ray(ray_query)
					if (raycast_result.is_empty()):
						return;
					var entity: Node3D = raycast_result["collider"];
					var node_path: String = entity.get_path();
					pending_cmd["target_node_path"] = node_path;
					request_unit_cmd(selected[active_unit], pending_cmd);
				pending_cmd = {};
				return
			#end pending command block
			#Check if we clicked on an object
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			var ray_length: int = 100
			var camera: Camera3D = get_viewport().get_camera_3d();
			var from: Vector3 = camera.project_ray_origin(mouse_pos)
			var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
			var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
			var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
			ray_query.from = from
			ray_query.to = to
			ray_query.collide_with_areas = true
			var raycast_result: Dictionary = space.intersect_ray(ray_query)
			var _err: Error
			var cntrl: bool = Input.is_action_pressed("control");
			#if we didnt hit anything
			if(raycast_result.is_empty()):
				if(!cntrl):
					clear_selection();
			#if we did hit something
			else:
				var entity: Node3D = raycast_result["collider"]
				#Entity is a unit
				if("ENTITY_NAME" in entity):
					#if we are not control click, or its not our unit, clear out our selection
					if(!cntrl  || entity.team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
						clear_selection();
					var has_entity_in_selected: bool = false;
					for i:int in range(selected.size(),0, -1):
						if(is_same(selected[i-1], entity)):
							print("we hajve this unit in our group already!");
							var e: Node3D = selected[i-1];
							e.unset_selected();
							selected.remove_at(i-1);
							has_entity_in_selected = true;
					if(!has_entity_in_selected):
						entity.set_selected();
						selected.append(entity);
					_err  = emit_signal("selected_signal", selected[0]);
					print("We have this many units in this array %s" % selected.size())
					return;
				else:
					if(!cntrl):
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
		var cmd_dict: Dictionary = selected[active_unit].cmd_dict
		var cmd: Dictionary = {};
		if (selected[active_unit].team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
			print("not my team");
			clear_selection();
			return;
		if(!pending_cmd.is_empty()):
			print("clearing pending command");
			pending_cmd = {};
			return;
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var ray_length: int = 100
		var camera: Camera3D = get_viewport().get_camera_3d();
		var from: Vector3 = camera.project_ray_origin(mouse_pos)
		var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
		var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
		var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		ray_query.from = from
		ray_query.to = to
		ray_query.collide_with_areas = true
		var raycast_result: Dictionary = space.intersect_ray(ray_query)
		if (raycast_result.is_empty()):
			print("empty")
			return;
		var entity: Node3D = raycast_result["collider"];
		if ("ENTITY_TYPE" in entity):
			var target_node_path: String = entity.get_path();
			#duplication of command dictionary can be redundant since handle_cmd does this as well
			cmd = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
			cmd["target_node_path"] = target_node_path;
			#unit
		else:
			cmd = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();
			var location: Vector3 = raycast_result["position"]
			cmd["location"] = location;
		#location
		handle_cmd(cmd);


#local method that is called before requesting the command over the server. If additional arguments required will defer cmd, otherwise will continue to request_unit_cmd
func handle_cmd(p_cmd: Dictionary) -> void:
	#ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;
	#create a new dictionary to not overwrite data incase this comes from the cmd gui
	var cmd_d: Dictionary = p_cmd.duplicate();

	#########
	#For ones that will require an argument like a location or target, set up so unhandled input will pick up the cmd
	#This will catch duplicated  commands that dont remove the argument section first
	if (p_cmd.has("argument")):
		#Only make it a pending command if this does not have an entry for the argument in question
		if(!p_cmd.has(p_cmd["argument"])):
			cmd_d[p_cmd["argument"]] = null;
			pending_cmd = cmd_d;
			return;
	#########
	#No argument needed, request the command
	request_unit_cmd(selected[active_unit], cmd_d);

#client RPCs server/host to start the action, final checks here before sending command
func request_unit_cmd(unit: Node3D, cmd: Dictionary) ->void:
	if("ENTITY_TYPE" not in unit):
		return;
	#check if cmd has a cost to it and deny if cant afford
	if(cmd.has("cost")):
		var mineral_cost: int = cmd["cost"][0];
		var gas_cost: int = cmd["cost"][1];
		if (mineral_cost > game.local_game_dict[game.PLAYER_RESOURCE_KEY]):
			#Cannot do the command, play an error sound to show they couldnt do it yet
			return;
		if (gas_cost > game.local_game_dict[game.PLAYER_GAS_KEY]):
			#Cannot do the command, play an error sound to show they couldnt do it yet
			return;

	##we do not actually request player data update on RPC, this occurs after the unit accepts the command

	if (Input.is_action_pressed("shift")):
		if(unit.has_method("queue_cmd")):
			unit.queue_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
			return;
	unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	pass;


func get_click_pos() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_length: int = 100
	var camera: Camera3D = get_viewport().get_camera_3d();
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;

	#To get intersection with colliders
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	var arr: Array;
	if (raycast_result.is_empty()):
		return Vector3.ZERO;
	else:
		return raycast_result["position"]


func get_world_click() -> Node3D:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_length: int = 100
	var camera: Camera3D = get_viewport().get_camera_3d();

	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state;
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	if (raycast_result.is_empty()):
		return;
	var obj: Node3D = raycast_result["collider"];

	if ("ENTITY_TYPE" in obj):
		return obj;
	else: return null;

func clear_selection() -> void:
	print("cleared selection");
	for node: Node3D in selected:
		node.unset_selected();
	selected.clear();
	deselected_signal.emit();
	pending_cmd = {};
