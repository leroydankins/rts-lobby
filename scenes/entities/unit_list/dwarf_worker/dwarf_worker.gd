extends Node3D
const ENTITY_NAME: String = "DwarfWorker"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.UNIT;
const PREVIEW: Texture2D = preload(GlobalConstants.UNIT_PLACEHOLDER_TEXTURE);
@onready var highlight_mesh: MeshInstance3D = $HighlightMesh


var team: int = 0;
var color: int = 0;
@export var player_id: String = "";
#LOCAL VARIABLE, DO NOT SYNC ACROSS PLAYERS
var is_selected: bool = false;


const MOVE_SPEED: float = 3;
const MINE_DISTANCE: float = 3;
@onready var wait_timer: Timer = $WaitTimer
@onready var anim: AnimationPlayer = $Anim




var game: GameScene;
var entity_holder: EntityHolder;
var resource_depot: Node3D

var health: float = 25;

var cmd_dict_array: Array[Dictionary] = []

#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: {},
	2: {},
	3: {},
	4: {},
	5: GlobalConstants.BUILD_DWARF_SETTLEMENT_DICTIONARY,
	6: GlobalConstants.CANCEL_ACTION_DICTIONARY,
	7: {},
	8: {},
	}

#Export functions to allow for property syncing
@export var target_pos: Vector2;
@export var target: Node;
@export var cmd_queue: Array[Dictionary] = [];
@export var cmd_history: Array[Dictionary] = [];
@export var held_resource: Array = [];

var build_started: bool = false;

var wait_bool: bool = false;
var building: Node3D;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	wait_timer.timeout.connect(on_wait_timer_finish);
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
		"we are waiting"
		return;
	#have to go in separate function to not interrupt returns on multiplayer sync
	match cmd_queue[0]["command"]:
		#CANCEL QUEUE
		GlobalConstants.Commands.CANCEL:
			print("clear");
			cmd_queue.clear();
			return;
		#MOVE TO LOCATION
		GlobalConstants.Commands.MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd_queue[0]["location"];
			global_position += (t_pos-global_position)/(t_pos-global_position).length() * delta * MOVE_SPEED
			if (abs(t_pos - global_position).length() <= 1):
				finish_cmd();
		#BUILD BUILDING
		#######WILL HAVE TO REWORK THIS
		GlobalConstants.Commands.BUILD:
			#drop command since it doesnt work
			if (!cmd_queue[0].has("file_path") || !cmd_queue[0].has("location")):
				"we did not have the right arguments"
				#move on to next cmd
				finish_cmd();
			var t_pos: Vector3 = cmd_queue[0]["location"];

			if (!build_started):
				global_position += (t_pos-global_position)/(t_pos-global_position).length() * delta * MOVE_SPEED
				if (abs(t_pos - global_position).length() <= 5):
					build_started = true;
					wait_bool = true;
					var building_file_path : String = cmd_queue[0]["file_path"];
					spawn_building(building_file_path);
					#wait for reference to the object and wait_bool is set to false to continue

			#if build started
			else:
				if(abs(building.global_position - global_position).length() <= 5):
					var direction_vector: Vector3 = Vector3(building.global_position.x - global_position.x, global_position.y, building.global_position.z - global_position.z)
					global_position -= abs((direction_vector)/(direction_vector).length()) * delta * MOVE_SPEED
					return;
				if (!building.is_constructed):
					building.construction_value += 1 * delta;
					#add to the value of the building
					pass;

				else:
					print("build command completed!")
					finish_cmd()
		#END BUILD BUILDING

		GlobalConstants.Commands.TARGET:
			#This will only branch out to other types of commands, we do not stay in the target command
			#assign location to local var so that we dont have to keep going through dictionary every frame
			#if the target is not valid, dump the command?

			if(!is_instance_valid(target)):
				finish_cmd();
				return;
			var pos: Vector3 = target.global_position;
			if (abs(pos - global_position) <= 25):
				pass;
			else:
				global_position += (pos-global_position)/(pos-global_position).length() * delta * MOVE_SPEED
		#END OF TARGET

		GlobalConstants.Commands.FOLLOW:
			#Find refernced target in the tree, RPC passes this data as a string nodepath
			var tar: Node3D = get_tree().root.get_node(cmd_queue[0]["target_node_path"]);
			if (tar == null || !is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;

			var pos: Vector3 = tar.global_position;
			#Change this later
			if (tar.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
				if (abs(pos - global_position).length() <= 3):
					finish_cmd();
					return;
			elif (abs(pos - global_position).length() <= 1):
				return;
			var movement_vector: Vector2 = Vector2(pos.x-global_position.x, pos.z - global_position.z).normalized();
			global_position += Vector3(movement_vector.x, 0, movement_vector.y) * delta * MOVE_SPEED
		#End of follow
		GlobalConstants.Commands.MINE:
			#Eventually we dont want to get the target every frame, but whatever we need a more fleshed out game to change this and its just an optimization
			#Find refernced target in the tree, RPC passes this data as a string nodepath
			var tar: Node3D = get_tree().root.get_node(cmd_queue[0]["target_node_path"]);
			if (tar == null || !is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
		###MOVE TO RESOURCE
			if(held_resource.is_empty()):
				var pos: Vector3 = tar.global_position;
				#if close enough
				if (abs(pos - global_position).length() <= 1):
					if (tar.in_use):
						return;
					if (tar.resource_amount <= 0):
						print("resource is empty")
						##TODO
						#switch to nearby resource or finish command
						finish_cmd();
						return;
					wait_bool = true;
					tar.in_use = true;
					anim.play("extract_resource");
					##get the resource here for now, target resources are syncronized with the multiplayer sync
					#var arr: Array = tar.extract_resource()
					##held resource = [resource_amount, resource_type]
					#assert(arr.size() == 2)
					#held_resource = arr;
					#check if there are resources in it

				#else we arent close enough
				else:
					global_position += (pos-global_position)/(pos-global_position).length() * delta * MOVE_SPEED
				#only execute 1 mining_state per process frame
				return;
			#else we have resources in hand
		###RETURN RESOURCE
			else:
				#CURRENTLY HARD CODED HOME BUILDING UWU
				if(resource_depot == null || !is_instance_valid(resource_depot)):
					#find home building?
					##TODO
					finish_cmd();
					return;
				var pos : Vector3 = resource_depot.global_position;
				global_position += (pos-global_position)/(pos-global_position).length() * delta * MOVE_SPEED
				#use colliders to actually stop the movement here
				if (abs(pos - global_position).length() <= 75):
					#Final game will use event system and signals to handle this instead of direct coupling I guess? FUTURE ETHAN PROBLEM LOL
					game.gain_resources(player_id, held_resource);
					#play mining animation
					held_resource.clear();
					wait_bool = true;
					wait_timer.start()

		#DEFAULT CASE
		_:
			print(cmd_queue[0]);
			finish_cmd();


func set_selected() -> void:
	is_selected = true;
	highlight_mesh.set_deferred("visible", true);

func unset_selected() -> void:
	is_selected = false;
	highlight_mesh.set_deferred("visible", false);

#called only by multipalyer instance
func finish_cmd() -> void:
	#pause to reset state and set up for next command
	wait_bool = true;
	if(!cmd_queue.is_empty()):
	#get next command in sequence
		var cmd: Dictionary = cmd_queue.pop_front();
		#log the previous command
		cmd_history.append(cmd);

	#reinit state data
	build_started = false;

	if(!cmd_queue.is_empty()):
		pass;

	#Allow the process function to start again after reinitializing state data
	wait_bool = false;
	pass;

@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	if(cmd_data.has("cost")):
		var cost_arr: Array = cmd_data["cost"];
		var success: bool = game.spend_resources(player_id,cost_arr);
		if (!success):
			print("not enough money pal. return");
			return;
	for i: int in cmd_queue.size():
		if(cmd_queue[i].has("cost")):
			if (i == 0 && build_started):
				#backwards way of doing this if statement lol, fix later
				continue;
			#refund the cost if you are clearing out the queue
			var minerals: int = cmd_queue[i]["cost"][0];
			var gas: int = cmd_queue[i]["cost"][1];
			#for those reading this, I know this is probably bad code smell or whatever to be calling a parent method but whatever dude
			game.request_player_data_update.rpc(player_id,game.PLAYER_RESOURCE_KEY, minerals)
			game.request_player_data_update.rpc(player_id,game.PLAYER_GAS_KEY, gas)
		pass;

	#finish whatever you were doing, put that command into history dictionary
	finish_cmd();
	#Clear the queued commands queued after refunding for them all, if you do not want to clear the queue, use queue_cmd()
	cmd_queue.clear();

	var cmd_mnemonic: String = cmd_data["mnemonic"]
	match cmd_mnemonic:
		#Target unit
		"GC001":
			if (!cmd_data.has("target_node_path")):
				return;
			#Find refernced target in the tree, RPC passes this data as a string nodepath
			var tar: Node = get_tree().root.get_node(cmd_data["target_node_path"])
			if (tar == null || !is_instance_valid(tar)):
				push_error("target did not exist");
				return;

			if("ENTITY_TYPE" not in tar):
				print("just an object in the scene, not entity that can be targeted, ignore it");
				return;

			#decide what to do based on entity type
			match tar.ENTITY_TYPE:
				GlobalConstants.EntityType.UNIT:
					#Is this unit an enemy? Attack, else, follow
					if (tar.team != team):
						cmd_data["command"] = GlobalConstants.Commands.ATTACK;
					else:
						cmd_data["command"] = GlobalConstants.Commands.FOLLOW;
					cmd_queue.append(cmd_data);
					return;
				GlobalConstants.EntityType.BUILDING:
					if (tar.team != team):
						cmd_data["command"] = GlobalConstants.Commands.ATTACK;
					else:
						if tar.BUILDING_TYPE.has(GlobalConstants.BuildingType.RESOURCE_DEPOT):
							resource_depot = tar;
						cmd_data["command"] = GlobalConstants.Commands.FOLLOW;
					cmd_queue.append(cmd_data);
					print("whatever")
					return;
				GlobalConstants.EntityType.RESOURCE:
					print("targeting a resource")
					cmd_data["command"] = GlobalConstants.Commands.MINE;
					cmd_queue.append(cmd_data);
					return;
		#Cancel action
		"GC002":
			#do we pass here because request command already does this??
			pass;
		#Move to location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			cmd_queue.append(cmd_data)
		#Build Forge at Vector2
		"WK002":
			print("got to the start of build forge command")
			if(!cmd_data.has("location")):
				"command dictionary did not have location"
				return;
			if(!cmd_data.has("file_path")):
				"command dictionary did not have file path"
				return;
			cmd_queue.append(cmd_data);
			pass;
		#Build Base at Vector2
		"WK001":
			print("got to the start of build base command")
			if(!cmd_data.has("location")):
				"command dictionary did not have location"
				return;
			if(!cmd_data.has("file_path")):
				"command dictionary did not have file path"
				return;
			cmd_queue.append(cmd_data);

@rpc("any_peer","call_local","reliable")
func queue_cmd(cmd_data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	if(cmd_data.has("cost")):
		var cost_arr: Array = cmd_data["cost"];
		var success: bool = game.spend_resources(player_id,cost_arr);
		if (!success):
			return;

	#DOES NOT CLEAR
	var cmd: String = cmd_data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			if (!cmd_data.has("target_node_path")):
				return;
			#Find refernced target in the tree, RPC passes this data as a string nodepath
			var tar: Node = get_tree().root.get_node(cmd_data["target_node_path"])
			if (tar == null || !is_instance_valid(tar)):
				push_error("target did not exist");
				return;

			if("ENTITY_TYPE" not in tar):
				print("just an object in the scene, not entity that can be targeted, ignore it");
				return;
			#decide what to do based on entity type
			match tar.ENTITY_TYPE:
				GlobalConstants.EntityType.UNIT:
					#Is this unit an enemy? Attack, else, follow
					if (tar.team != team):
						cmd_data["command"] = GlobalConstants.Commands.ATTACK;
					else:
						cmd_data["command"] = GlobalConstants.Commands.FOLLOW;
					cmd_queue.append(cmd_data);
					return;
				GlobalConstants.EntityType.BUILDING:
					if (tar.team != team):
						cmd_data["command"] = GlobalConstants.Commands.ATTACK;
					else:
						cmd_data["command"] = GlobalConstants.Commands.FOLLOW;
					cmd_queue.append(cmd_data);
					return;
				GlobalConstants.EntityType.RESOURCE:
					print("targeting a resource")
					cmd_data["command"] = GlobalConstants.Commands.MINE;
					cmd_queue.append(cmd_data);
					return;
		#Cancel action
		"GC002":
			#if we say cancel action do we just not care that its queued?
			finish_cmd();
			cmd_queue.clear();
			pass;
		#Move to location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			cmd_queue.append(cmd_data)
		#Build Forge at Vector2
		"WK002":
			print("got to the start of build forge command")
			if(!cmd_data.has("location")):
				"command dictionary did not have location"
				return;
			if(!cmd_data.has("file_path")):
				"command dictionary did not have file path"
				return;
			cmd_queue.append(cmd_data);
			pass;
		#Build Base at Vector2
		"WK003":
			print("got to the start of build base command")
			if(!cmd_data.has("location")):
				"command dictionary did not have location"
				return;
			if(!cmd_data.has("file_path")):
				"command dictionary did not have file path"
				return;
			cmd_queue.append(cmd_data);


###WORKER SPECIFIC FUNCTIONS


#special case where the object needs to add the child to keep refernce
@rpc("authority", "call_local", "reliable")
func spawn_building_rpc(dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return
	if (dict.is_empty()):
		return;
	var obj: Node3D = load(dict["file_path"]).instantiate();
	obj.team = dict["team"];
	obj.player_id = dict["player_id"];
	obj.global_position = dict["position"];
	#color is an int, the object will access the actual color via GlobalConstants
	obj.color = dict["color"];
	building = obj;
	building.is_constructed = false;
	entity_holder.register_entity(obj);
	wait_bool = false;
	target_pos = Vector2.ZERO;
	pass;

#this only gets called by the multiplayer host because it is called from process, which is only done by the host
func spawn_building(filepath: String) -> void:
	if (!multiplayer.is_server()):
		return;
	var spawn_dict: Dictionary ={
	#temp use of a direct constant, the filepath will depend on starting race
	"file_path" = filepath,
	"team" = team,
	"player_id" = player_id,
	"position" = cmd_queue[0]["location"],
	"color" = color,
	}
	spawn_building_rpc.rpc(spawn_dict);
	pass;

func on_wait_timer_finish() ->void:
	wait_bool = false;

func extract_resources() -> void:
	var cmd: Dictionary = cmd_queue[0];
	if cmd["command"] != GlobalConstants.Commands.MINE:
		finish_cmd();
		return;
	var tar: Node3D = get_tree().root.get_node(cmd_queue[0]["target_node_path"]);
	if (tar == null || !is_instance_valid(tar)):
		push_error("target did not exist")
		finish_cmd();
		return;

	if(!tar.has_method("extract_resource")):
		return;

	if (tar.resource_amount <= 0):
		print("resource is empty")
		##TODO
		#switch to nearby resource or finish command
		finish_cmd();
		return;
	#get the resource here for now, target resources are syncronized with the multiplayer sync
	var arr: Array = tar.extract_resource()
	#held resource = [resource_amount, resource_type]
	assert(arr.size() == 2)
	held_resource = arr;
	wait_bool = false;
	tar.in_use = false;
