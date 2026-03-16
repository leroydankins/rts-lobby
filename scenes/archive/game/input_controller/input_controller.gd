class_name InputController;
extends Control

##Used by the local player to initiate commands and send commands to the units
##Keeps arrays of all selected units, can have hotkeys for multiple units, uses Input to read inputs before anything else and then stops their input
##this should not have to RPC its own functions, only the people it makes do things

#reference Game because we need that for updating data
var game: Game;

#used by GAME UI to show options for first unit
signal selected_signal(first_unit: Node);
signal deselected_signal();

var dragging: bool = false  # Are we currently dragging?
var selected: Array[Node2D] = []  # Array of selected units.
var drag_start: Vector2 = Vector2.ZERO  # Location where drag began.
var select_rect: RectangleShape2D = RectangleShape2D.new()  # Collision shape for drag box.

@export var is_active: bool = false;
var groups_dict: Dictionary[int, Array] = {};

var active_unit: int = 0;

var pending_cmd: Dictionary = {};

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
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
			#Pending Command Block
			if(!pending_cmd.is_empty() && !selected.is_empty()):
				if (selected[active_unit].team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
					print("not my team");
					pending_cmd = {};
					return;

				if(pending_cmd.has("cost")):
					if(pending_cmd["cost"][0] > game.local_game_dict[game.PLAYER_RESOURCE_KEY] || pending_cmd["cost"][1] > game.local_game_dict[game.PLAYER_GAS_KEY]):
						print("cannot accept command, but not removing the pending command from selection");
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
				return
			#end pending command block

			#Check if we clicked on an object
			var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state;
			var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position();
			query.collide_with_areas = true;
			var objects_arr: Array[Dictionary] = space.intersect_point(query);
			var _err: Error
			if (!objects_arr.is_empty()):
				print("object")
				var entity: Node = objects_arr[0]["collider"]
				selected.clear();
				selected.append(entity)
				_err  = emit_signal("selected_signal", selected[0]);
				return;
			else:
				selected.clear();
				_err = emit_signal("deselected_signal");
				_err = emit_signal("selected_signal", null);
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
				return;
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
			#duplication of command dictionary can be redundant since handle_cmd does this as well
			cmd = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
			cmd["target_node_path"] = target_node_path;
		#Target location
		else:
			cmd = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();

			var location : Vector2 = get_global_mouse_position();
			cmd["location"] = location;
		#TEMPORARY
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
			print(true);
			cmd_d[p_cmd["argument"]] = null;
			pending_cmd = cmd_d;
			return;
	#########
	#No argument needed, request the command
	request_unit_cmd(selected[active_unit], cmd_d);

#client RPCs server/host to start the action, final checks here before sending command
func request_unit_cmd(unit: Node2D, cmd: Dictionary) ->void:
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
		#print(game.local_game_dict["player_id"]);
		#game.request_player_data_update.rpc(game.local_game_dict["player_id"],game.PLAYER_RESOURCE_KEY, -1 * mineral_cost);
		#game.request_player_data_update.rpc(game.local_game_dict["player_id"],game.PLAYER_GAS_KEY, -1 * gas_cost);
	if (Input.is_action_pressed("shift")):
		if(unit.has_method("queue_cmd")):
			unit.queue_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
			return;
	unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	pass;
