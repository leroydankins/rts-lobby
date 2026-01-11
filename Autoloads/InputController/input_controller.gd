class_name InputController;
extends Node2D

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
	if event is InputEventMouseButton and event.is_action("select"):
		if event.pressed:
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
		# If the mouse is released and is dragging, stop dragging
		else:
			if dragging:
				dragging = false
				queue_redraw()

	#ONLY PROCESS THESE IF WE HAVE SELECTED UNITS
	if(selected.is_empty()):
		return;
	if (event.is_action_pressed("action")):
		if (selected.size() == 1):
			request_unit_action(selected[0], 0);
		print("event!")
	if (event.is_action_pressed("action_5")):
		request_unit_action(selected[0], 5)


#tells unit on client to send rpc to server to request function call, the server will then send out the rpc to all units
func request_unit_action(unit: Node2D, action: int) ->void:
	assert(selected[0].has_method("request_command"));
	unit.request_command.rpc_id(Lobby.multiplayer_server_id, action);
	pass;
