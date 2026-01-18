class_name InputController;
extends Control

##Used by the local player to initiate commands and send commands to the units
##Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
##this should not have to RPC its own functions, only the people it makes do things

#used by GAME UI to show options for first unit
signal selected_signal(first_unit: Node);
signal deselected_signal();

var dragging: bool = false  # Are we currently dragging?
var selected: Array[Node2D] = []  # Array of selected units.
var drag_start: Vector2 = Vector2.ZERO  # Location where drag began.
var select_rect: RectangleShape2D = RectangleShape2D.new()  # Collision shape for drag box.

@export var is_active: bool = false;
var groups_dict: Dictionary[int, Array] = {};
var current_selection : Array[Node2D] = [];

var active_unit: int = 0;

var pending_cmd: Dictionary = {};
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (!is_active):
		return;
	pass

func _unhandled_input(event: InputEvent) -> void:
	if(!is_active):
		return;
	if(event.is_action_pressed("escape")):
		selected.clear();
		selected_signal.emit(null);
		deselected_signal.emit();
		pending_cmd = {};
	if event is InputEventMouseButton and event.is_action("select"):
		#MOUSE PRESS LOGIC
		if event.pressed:
			#if we are pending a command input and still have a unit selected
			if(!pending_cmd.is_empty() && !selected.is_empty()):
				if (selected[active_unit].team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
					print("not my team");
					pending_cmd = {};
					return;
				#the pending command requires a location input
				if(pending_cmd.has("location")):
					pending_cmd["location"] = get_global_mouse_position();
					request_unit_cmd(selected[active_unit], pending_cmd);
				#the pending command is targeting a node
				elif(pending_cmd.has("target_node_path")):
					var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state;
					var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
					query.position = get_global_mouse_position();
					query.collide_with_areas = true;
					var objects_arr: Array[Dictionary] = space.intersect_point(query);
					if (!objects_arr.is_empty()):
						print("object")
						var entity: Node = objects_arr[0]["collider"]
						var node_path: String = entity.get_path();
						pending_cmd["target_node_path"] = node_path;
						request_unit_cmd(selected[active_unit], pending_cmd);
				pending_cmd = {};
				return;
				pending_cmd = {};


			#end pending command block

			#Check if we clicked on an object
			var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state;
			var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position();
			query.collide_with_areas = true;
			var objects_arr: Array[Dictionary] = space.intersect_point(query);
			if (!objects_arr.is_empty()):
				print("object")
				var entity: Node = objects_arr[0]["collider"]
				selected.clear();
				selected.append(entity)
				emit_signal("selected_signal", selected[0]);
				return;
			else:
				selected.clear();
				emit_signal("deselected_signal");
				emit_signal("selected_signal", null);
		# If the mouse was clicked and nothing is selected, start dragging
			if selected.size() == 0:
				dragging = true
				drag_start = event.position
		#END OF MOUSE PRESS LOGIC

		# If the mouse is released and is dragging, stop dragging
		else:
			if dragging:
				dragging = false
				queue_redraw()
	#End left click actions


	#ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;
	#create commands vars outside of logic since they all use it i guess?
	var cmd_dict: Dictionary = selected[active_unit].cmd_dict
	var cmd: Dictionary = {};

	#RIGHT CLICK LOGIC
	if (event.is_action_pressed("action")):
		if (selected[0].team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
			print("not my team");
			return;
		if(!pending_cmd.is_empty()):
			print("clearing pending command");
			pending_cmd = {};
			return;
		var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state;
		var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
		query.position = get_global_mouse_position();
		query.collide_with_areas = true;
		var objects_arr: Array[Dictionary] = space.intersect_point(query);
		#If we right clicked on an object
		if (!objects_arr.is_empty()):
			print("object")
			var entity: Node = objects_arr[0]["collider"]
			var target_node_path: String = entity.get_path();
			#Target unit
			cmd["mnemonic"] = "GC001";
			cmd["command"] = GlobalConstants.Commands.TARGET;
			cmd["target_node_path"] = target_node_path;
		#Target location
		else:
			cmd["mnemonic"] = "GC003";
			cmd["command"] = GlobalConstants.Commands.MOVE;
			var location : Vector2 = get_global_mouse_position();
			cmd["location"] = location;
		#TEMPORARY
		request_unit_cmd(selected[active_unit], cmd);


	if (event.is_action_pressed("action_5")):
		if (selected[0].team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
			print("not my team");
			return;
		if (!cmd_dict[5].is_empty()):
			if (!cmd_dict[5].has("mnemonic")):
				push_error("invalid cmd dictionary");
				return;
			cmd["mnemonic"] = cmd_dict[5]["mnemonic"];
			if(cmd_dict[5].has("argument")):
				#do argument specific stuff here
				match (cmd_dict[5]["argument"]):
					"location":
						pass;
			else:
				request_unit_cmd(selected[active_unit], cmd);

#client RPCs server/host to start the action, final checks here before sending command
func request_unit_cmd(unit: Node2D, cmd: Dictionary) ->void:
	if (Input.is_action_pressed("shift")):
		if(unit.has_method("queue_cmd")):
			unit.queue_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
			return;
	unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	pass;
