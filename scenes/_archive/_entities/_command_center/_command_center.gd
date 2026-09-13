extends Area2D
const ENTITY_NAME: String = "Command Center"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.BUILDING;

const PREVIEW: Texture2D = preload(GlobalConstants.BUILDING_PLACEHOLDER_TEXTURE) #building_placeholder.png




const BUILDING_TYPE: Array[int] = [GlobalConstants.BuildingType.CENTER,GlobalConstants.BuildingType.RESOURCE_DEPOT];
const CONSTRUCTION_COMPLETE: int = 10;
const BUILD_LIMIT: int = 8;
var construction_value: float = 0;
@export var is_constructed: bool = false;

@onready var temp_team_label: Label = $TempTeamLabel
@onready var marker: Marker2D = $Marker2D
@onready var temp_state_label: Label = $TempStateLabel
@onready var construct_label: Label = $ConstructLabel
@onready var target_line: Line2D = $TargetLine


#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0 : {},
	1 : {},
	2 : {},
	3 : {},
	4 : {},
	5 : GlobalConstants.BUILD_WORKER_DICTIONARY,
	6 : GlobalConstants.CANCEL_ACTION_DICTIONARY,
	7 : {},
	8 : {}
}

var build_dictionary: Dictionary[int, Dictionary]

var team: int = 0;
var color: int = 0;
#export so that in test environment everything is ok
@export var player_id: String = "";
var game: Game;

@export var target_location: Vector2;
@export var target: Node;

@export var build_time: int;
@export var build_item: Dictionary;
@export var build_queue: Array[Dictionary];
@export var build_progress: float;
@export var build_speed_mult: float = 1;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	var text : String = GlobalConstants.TEAMS[team];
	temp_team_label.text = "Team: %s" % text;
	target_line.points[1] = marker.global_position - global_position;

	pass # Replace with function body.

#Only process if you are the server, properties will get synced to other players across RPC calls
func _process(delta: float) -> void:
	temp_state_label.text = str("is constructed:", is_constructed);
	if(!is_constructed):
		construct_label.text = "Construction Progress is %s / %s" % [int(construction_value),CONSTRUCTION_COMPLETE];
		if(construction_value >= CONSTRUCTION_COMPLETE):
			is_constructed = true;
	else:
		construct_label.text = ""
	if (!multiplayer.is_server()):
		return;
	if (is_constructed):
		#If we dont have an item to build
		if (build_item == null || build_item.is_empty()):
			#if we have something in the queue, start it
			if(!build_queue.is_empty()):
				start_build();
			return;
		#add to progress of build
		build_progress += 1 * delta * build_speed_mult;
		if build_progress >= build_time:
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

func finish_build() -> void:
	if (!multiplayer.is_server()):
		return;
	if(build_item.has("file_path")):
		spawn_unit(build_item["file_path"]);
	elif (build_item.has("upgrade")):
		#match upgrade int
		#call game.update player upgrades
		pass;
	elif (build_item.has("research")):
		#call game.update player research
		#argument is array [player_id,race_id,research_id]
		pass;
	#reset build characteristics
	build_item = {};
	build_time = 0;
	build_progress = 0;
	if (!build_queue.is_empty()):
		start_build();

#TEMPORARY, MOVE THIS TO BE ACTION CALLED VIA A COMMAND REQUEST HANDLE COMMAND
#called when game UI
@rpc("any_peer","call_local","reliable")
func cancel_queued(p_int: int) -> void:
	#refund the cost if you are clearing out the queue
	if(!multiplayer.is_server()):
		return;
	print("canceled!")
	var queued: Dictionary = build_queue.pop_at(p_int);
	if(!queued.has("cost")):
		return;
	var _success: int = game.refund_resources(player_id,queued["cost"]);


@rpc("any_peer","call_local","reliable")
func cancel_build() ->void:
	if(!multiplayer.is_server()):
		return;
	if(build_item.is_empty()):
		return;
	var cost_arr : Array = build_item["cost"]
	#call refund resources on cost  to player id
	var _success: bool = game.refund_resources(player_id,cost_arr);
	build_item = {};
	build_time = 0;
	build_progress = 0;
	if (!build_queue.is_empty()):
		start_build();



func spawn_unit(filepath: String) -> void:
	if (!multiplayer.is_server()):
		return;
	var spawn_dict: Dictionary ={
	#temp use of a direct constant, the filepath will depend on starting race
	"file_path" = filepath,
	"team" = team,
	"player_id" = player_id,
	"position" = marker.global_position,
	"color" = color
	}
	spawn_unit_rpc.rpc(spawn_dict)
	pass;

#special case where the object needs to add the child to keep refernce
@rpc("authority", "call_local", "reliable")
func spawn_unit_rpc(spawn_dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return
	if (spawn_dict.is_empty()):
		return;
	var unit: Node2D = load(spawn_dict["file_path"]).instantiate();
	unit.team = spawn_dict["team"];
	unit.player_id = spawn_dict["player_id"];
	unit.global_position = spawn_dict["position"];
	#color is an int, the object will access the actual color via GlobalConstants
	unit.color = spawn_dict["color"];
	if("home_building" in unit):
		unit.home_building = self;
		#build command for object and give them that move command
	else:
		push_error("couldnt assign home building");
	game.entity_holder.add_child(unit);
	if(!multiplayer.is_server()):
		return;
	if(is_instance_valid(target)):
		var cmd : Dictionary = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
		cmd["target_node_path"] = target.get_path();
		unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	elif(target_location != Vector2.ZERO):
		var cmd : Dictionary = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();
		cmd["location"] = target_location;
		unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);


@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if(!is_constructed):
		print("cannot accept commands, we arent fully fleshed yet! :)");
		return;
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	if(cmd_data.has("cost")):
		#All building commands that have a cost require building, easy check to not spend resources that will get rejected in command switch statement
		if(build_queue.size() >= BUILD_LIMIT):
			print("Full queue, rejecting command");
			return;
		var cost_arr: Array = cmd_data["cost"];
		var success: bool = game.spend_resources(player_id,cost_arr);
		if (!success):
			return;
	var cmd: String = cmd_data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			if (!cmd_data.has("target_node_path")):
				return;
			target = get_tree().root.get_node(cmd_data["target_node_path"])
			if (target == null || !is_instance_valid(target)):
				push_error("target did not exist");
				target = null;
				return;
			if("ENTITY_TYPE" not in target):
				print("just an object in the scene, not an ally or neutral, ignore it");
				return;
			target_line.points[1] = target.global_position - global_position;
		#Cancel action
		"GC002":
			if(build_item != null):
				cancel_build.rpc();
			return;
		#Target location / Move to Location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			target_location = cmd_data["location"];
			target_line.points[1] = target_location - global_position;
		#Build Dwarf
		"CC001":
			if(build_queue.size() >= BUILD_LIMIT):
				#we cant do this command
				return;
			build_queue.append(GlobalConstants.BUILD_WORKER_DICTIONARY);


	#The command was accepted, if it has a cost, send it back to game to handle the cost update
