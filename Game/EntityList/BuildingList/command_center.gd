extends Area2D

const BUILD_COMPLETE: int = 60;
@onready var temp_team_label: Label = $TempTeamLabel
@onready var marker: Marker2D = $Marker2D


#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	5 : GlobalConstants.BUILD_WORKER_DICTIONARY,
	6 : GlobalConstants.CANCEL_ACTION_DICTIONARY,
	7 : GlobalConstants.HALT_ACTION_DICTIONARY,
	8 : GlobalConstants.RESUME_ACTION_DICTIONARY
}

var build_dictionary: Dictionary[int, Dictionary]

var team: int = 0;
var color: int = 0;
var game: Game;
var build_time: int;
var build_item: Dictionary;
var build_queue: Array[int];
var build_progress: float;
var build_speed_mult: float = 1;

#STATE MACHINE
enum BuildingState{
	IDLE,
	ACTIVE,
	HALTED
}
var current_state: BuildingState = BuildingState.IDLE;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _null_var: int = input_event.connect(on_input);
	game = get_tree().get_first_node_in_group("Game");
	var text : String = GlobalConstants.TEAMS[team];
	temp_team_label.text = "Team: %s" % text;
	pass # Replace with function body.

#Only process if you are the server, properties will get synced to other players across RPC calls
func _process(delta: float) -> void:
	if (!multiplayer.is_server()):
		return;
	match current_state:
		BuildingState.IDLE:
			if (!build_queue.is_empty() && build_item.is_empty()):
				start_build();
		BuildingState.HALTED:
			#we just vibe in halted state
			return;
		#if we are active
		BuildingState.ACTIVE:
			#If we dont have an item to build, return
			if (build_item == null):
				#if we have something in the queue, start it
				if(!build_queue.is_empty()):
					start_build();
					return;
				#Switch states
				else:
					current_state = BuildingState.IDLE
				return;
			#add to progress of build
			build_progress += 1 * delta * build_speed_mult;
			if build_progress >= build_time:
				#rpc call build item
				finish_build();
				pass;


func start_build() -> void:
	#When we start a build, assign the dictionary to build_item and get rid of it in the queue
	build_item = cmd_dict[build_queue.pop_front()]
	#if there was nothing in the queue then we just close out our build data
	if (build_item == null || build_item.is_empty()):
		build_time = 0;
		build_progress = 0;
	print(build_item);
	assert (build_item.has("build_time")) #assert to make sure no bug occurred from building
	build_time = build_item.build_time;
	current_state = BuildingState.ACTIVE


func pause_build() -> void:
	pass;

func finish_build() -> void:
	if (!multiplayer.is_server()):
		return;
	if (build_item.has("is_unit")):
		if (build_item.is_unit == true):
			spawn_unit(build_item.file_path);
	#Else finish research technology or whatever
	else:
		pass
	build_item.clear();
	build_time = 0;
	build_progress = 0;
	if (!build_queue.is_empty()):
		start_build();





func cancel_build() ->void:
	build_progress = 0;



func on_input(_viewport: Node, event: InputEvent, _shape_idx :int) -> void:
	if event.is_action_pressed("select"):
		print(name + "was clicked");
		if (team == LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
			print("valid click!");



func spawn_unit(filepath: String) -> void:
	if (!multiplayer.is_server()):
		return;
	var spawn_dict: Dictionary ={
	#temp use of a direct constant, the filepath will depend on starting race
	"file_path" = filepath,
	"team" = team,
	"position" = marker.global_position,
	"color" = color
	}
	game.add_entity_from_dict.rpc(spawn_dict);
	pass;

@rpc("any_peer","call_local","reliable")
func request_command(command: int) ->void:
	if(!multiplayer.is_server()):
		return
	print("requesting command %s" % command);
	if (!cmd_dict.has(command)):
		return;
	#if command is something that has to request game, like spawn a unit, request here and dont process command
	match command:
		#Build worker
		0:
			var spawn_dict: Dictionary ={
			#temp use of a direct constant, the filepath will depend on starting race
			"file_path" = GlobalConstants.WORKER_FILEPATH,
			"team" = team,
			"position" = marker.global_position,
			"color" = color
			}
			game.add_entity_from_dict.rpc(spawn_dict);
			return
		5:
			build_queue.append(5);
		6:
			if(build_item != null):
				cancel_build();
			pass;
	process_command.rpc(command);
	pass;

@rpc("authority","call_local","reliable")
func process_command(command: int) ->void:
	print("processing command %s" % command)
	#match command:
		#0:
			#if(game == null):
				#return;
			#var spawn_dict: Dictionary ={
			##temp use of a direct constant, the filepath will depend on starting race
			#"file_path" = GlobalConstants.WORKER,
			#"team" = team,
			#"position" = marker.global_position,
			#"color" = color
			#}
			#game.add_entity_from_dict.rpc(spawn_dict);
			#pass; #build a dictionary for the unit to create and ask the game scene to add it
