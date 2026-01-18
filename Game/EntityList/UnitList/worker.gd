extends Area2D
const OBJECT_NAME: String = "Worker"
const MOVE_SPEED: float = 250;

var team: int = 0;
var color: int = 0;
var game: Game;


var health: float = 0;
var cmd_dict_array: Array[Dictionary] = []
#command dictionaries need to be initialized before cmd_dict or in GlobalConstants otherwise it will be empty
var build_brewery: Dictionary = {
	"name" : "Build Brewery",
	"mnemonic" : "WK001",
	"description" : "Breweries are needed to expand your supply, more beer more dwarves",
	"argument" : "location",
	"sprite_path" : "res://Resources/CommandSprites/building_placeholder.png"
}
var build_barracks : Dictionary = {
	"name" : "Build Barracks",
	"mnemonic" : "WK002",
	"description" : "Barracks build ground soldiers",
	"argument" : "location",
	"sprite_path" : "res://Resources/CommandSprites/building_placeholder.png"
}
#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: {},
	2: {},
	3: {},
	4: {},
	5: GlobalConstants.BUILD_BASE_DICTIONARY,
	6: GlobalConstants.CANCEL_ACTION_DICTIONARY,
	7: {},
	8: {},
	}

#temp functions
@export var target_pos: Vector2;
@export var target: Node;
@export var cmd_queue: Array[Dictionary] = [];
@export var cmd_history: Array[Dictionary] = [];

var build_started: bool = false;

var wait_bool: bool = false;
var building: Node2D;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!multiplayer.is_server()):
		return;
	if(cmd_queue.is_empty()):
		#current_state = UnitState.IDLE;
		return;
	#Wait bool is to allow time for RPC calls to server before continuing
	if(wait_bool):
		"we are waiting when we shouldnt"
		return;
	#have to go in separate function to not interrupt returns on multiplayer sync
	match cmd_queue[0]["command"]:
		GlobalConstants.Commands.CANCEL:
			print("clear");
			#current_state = UnitState.IDLE;
			cmd_queue.clear();
			return;
		GlobalConstants.Commands.MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector2 = cmd_queue[0]["location"];

			global_position += (t_pos-global_position)/(t_pos-global_position).length() * delta * MOVE_SPEED
			if (abs(t_pos - global_position).length() <= 2):
				finish_cmd();


		#BUILD BUILDING
		GlobalConstants.Commands.BUILD:
			#drop command since it doesnt work
			if (!cmd_queue[0].has("file_path") || !cmd_queue[0].has("location")):
				"we did not have the right arguments"
				#move on to next cmd
				finish_cmd();
			var t_pos: Vector2 = cmd_queue[0]["location"];

			if (!build_started):
				global_position += (t_pos-global_position)/(t_pos-global_position).length() * delta * MOVE_SPEED
				if (abs(t_pos - global_position).length() <= 10):
					build_started = true;
					wait_bool = true;
					var building_file_path : String = cmd_queue[0]["file_path"];
					spawn_building(building_file_path);
					#wait for reference to the object and wait_bool is set to false to continue

			#if build started
			else:
				if(abs(building.global_position - global_position).length() <= 75):
					global_position -= abs((building.global_position-global_position)/(building.global_position-global_position).length()) * delta * MOVE_SPEED
					return;
				if (building.current_state == GlobalConstants.BuildingState.UNCONSTRUCTED):
					building.construction_value += 1 * delta;
					#add to the value of the building
					pass;

				else:
					print("build command completed!")
					finish_cmd()
		#END BUILD BUILDING

		GlobalConstants.Commands.TARGET:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			if(!is_instance_valid(target)):
				target = cmd_queue[0]["target"];
			var pos: Vector2 = target.global_position;
			if (abs(pos - global_position) <= 25):
				pass;
			else:
				global_position += (pos-global_position)/(pos-global_position).length() * delta * MOVE_SPEED

		#DEFAULT CASE
		_:
			print(cmd_queue[0]);
			finish_cmd();

	#sync data? location
	if (!multiplayer.is_server()):
		return;

	pass



#special case where the object needs to add the child to keep refernce
@rpc("authority", "call_local", "reliable")
func spawn_building_rpc(dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return
	if (dict.is_empty()):
		return;
	var obj: Node2D = load(dict["file_path"]).instantiate();
	obj.team = dict["team"];
	obj.global_position = dict["position"];
	#color is an int, the object will access the actual color via GlobalConstants
	obj.color = dict["color"];
	building = obj;
	building.current_state = GlobalConstants.BuildingState.UNCONSTRUCTED;
	game.entity_holder.add_child(obj);
	print("we built", building.OBJECT_NAME)
	wait_bool = false;
	target_pos = Vector2.ZERO;
	pass;

func spawn_building(filepath: String) -> void:
	if (!multiplayer.is_server()):
		return;
	var spawn_dict: Dictionary ={
	#temp use of a direct constant, the filepath will depend on starting race
	"file_path" = filepath,
	"team" = team,
	"position" = cmd_queue[0]["location"],
	"color" = color,
	}
	spawn_building_rpc.rpc(spawn_dict);
	pass;

@rpc("authority","call_local","unreliable_ordered")
func sync_properties(bytes: PackedByteArray) -> void:
	#var pos: Vector2 = bytes_to_var(bytes);
	#global_position = pos;
	pass;

func finish_cmd() -> void:
	#pasue to reset state and set up for next command
	wait_bool = true;
	#reinit state data
	build_started = false;
	wait_bool = false;
	#get next command in sequence
	var cmd: Dictionary = cmd_queue.pop_front();
	#log the previous command
	cmd_history.append(cmd);
	pass;

@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	cmd_queue.clear();
	var cmd: String = cmd_data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			if (!cmd_data.has("target_node_path")):
				return;
			target = get_tree().root.get_node(cmd_data["target_node_path"])
			if target == null:
				push_error("target did not exist");
		#Cancel action
		"GC002":
			pass;
		#Move to location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			print('procssed command')
			cmd_queue.append(cmd_data)
		#Build Base at Vector2
		"WK003":
			print("got to the start of build base command")
			if(!cmd_data.has("location")):
				"command dictionary did not have location"
				return;
			if(!cmd_data.has("file_path")):
				"command dictionary did not have file path"
				return;
			#these are resetting state of command but not letting it finish the current command
			wait_bool = false;
			build_started = false;
			#clear out the current command queue since we are not queueing this command
			print(str(cmd_data["command"], "is now in the cmd queue!!"))
			cmd_queue.append(cmd_data);

@rpc("any_peer","call_local","reliable")
func queue_cmd(cmd_data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	#DOES NOT CLEAR
	var cmd: String = cmd_data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			if (!cmd_data.has("target_node_path")):
				return;
			target = get_tree().root.get_node(cmd_data["target_node_path"])
			if target == null:
				push_error("target did not exist");
		#Cancel action
		"GC002":
			pass;
		#Move to location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			print('procssed command')
			cmd_queue.append(cmd_data)
		#Build Base at Vector2
		"WK003":
			print("got to the start of build base command")
			if(!cmd_data.has("location")):
				"command dictionary did not have location"
				return;
			if(!cmd_data.has("file_path")):
				"command dictionary did not have file path"
				return;
			print(str(cmd_data["command"], "is now in the cmd queue!!"))
			cmd_queue.append(cmd_data);

@rpc("any_peer","call_local","reliable")
func request_command(command: int) ->void:
	if(!multiplayer.is_server()):
		return
	print("requesting command %s" % command);
	#if command is something that has to request game, like spawn a unit, request here and dont process command
	match command:
		0:
			return;
	process_command.rpc(command);
	pass;

@rpc("authority","call_local","reliable")
func process_command(command: int) ->void:
	print("processing command %s" % command)
	match command:
		0:
			pass; #build a dictionary for the unit to create and ask the game scene to add it
