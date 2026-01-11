extends Area2D

const BUILD_COMPLETE: int = 60;
const QUEUE_LIMIT: int = 4;
@onready var temp_team_label: Label = $TempTeamLabel
@onready var marker: Marker2D = $Marker2D

var build_worker_cmd: Dictionary = {
	"mnemonic" : "CC001",
	"name" : "Dwarf Worker",
	"description" : "Builds a worker",
	"file_path" : GlobalConstants.WORKER_FILEPATH,
	"build_time" : 5,
	"sprite_path" : "res://Resources/CommandSprites/placeholder_unit.png"
}

#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	5 : build_worker_cmd,
	6 : GlobalConstants.CANCEL_ACTION_DICTIONARY,
}


var cmd_dict2: Dictionary = {
	"CC001" : {
		"name" : "Worker",
		"description" : "Builds a worker",
		"file_path" : GlobalConstants.WORKER_FILEPATH,
		"build_time" : 10,
		"sprite_path" : "res://Resources/CommandSprites/placeholder_unit.png"
		}
}

var build_dictionary: Dictionary[int, Dictionary]

var team: int = 0;
var color: int = 0;
var game: Game;
var build_time: int;
var build_item: Dictionary;
var build_queue: Array[Dictionary];
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
			if (build_item == null || build_item.is_empty()):
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
				print("finish build")
				#rpc call build item
				finish_build();
				pass;


func start_build() -> void:
	#When we start a build, assign the dictionary to build_item and get rid of it in the queue
	build_item = build_queue.pop_front()
	print(build_item)
	#if there was nothing in the queue then we just close out our build data
	if (build_item == null || build_item.is_empty()):
		build_time = 0;
		build_progress = 0;
		return;
	assert (build_item.has("build_time")) #assert to make sure no bug occurred from building
	build_time = build_item.build_time;
	current_state = BuildingState.ACTIVE


func pause_build() -> void:
	pass;

func finish_build() -> void:
	if (!multiplayer.is_server()):
		return;
	spawn_unit(build_item["file_path"]);
	print("got here the first time")
	#Else finish research technology or whatever
	build_item = {};
	build_time = 0;
	build_progress = 0;
	if (!build_queue.is_empty()):
		start_build();




@rpc("authority","call_local","reliable")
func cancel_build() ->void:
	current_state = BuildingState.IDLE
	build_item = {};
	build_time = 0;
	build_progress = 0;
	build_queue.clear();




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
func request_cmd(data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if !data.has("mnemonic"):
		push_error("command invalid");
		return;
	var cmd: String = data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			print("Targeting unit does nothing for buildings")
			return;
		#Cancel action
		"GC002":
			if(build_item != null):
				cancel_build.rpc();
			return;
		#Target location
		"GC003":
			if (!data.has("location")):
				return;
			#need to set up unit command queueing for pre-setting first command
			var location: Vector2 = data["location"];
		#Build Dwarf
		"CC001":
			build_queue.append(build_worker_cmd);
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
			if (build_queue.size() >= QUEUE_LIMIT):
				print("queue limit, cannot queue more")
				return;
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
