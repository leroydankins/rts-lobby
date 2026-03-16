extends Area3D
const ENTITY_NAME: String = "Dwarf Settlement"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.BUILDING;
const BUILDING_TYPE: Array[int] = [GlobalConstants.BuildingType.CENTER, GlobalConstants.BuildingType.RESOURCE_DEPOT]
const PREVIEW: Texture2D = preload(GlobalConstants.BUILDING_PLACEHOLDER_TEXTURE) #building_placeholder.png
@onready var highlight_mesh: MeshInstance3D = $HighlightMesh
@onready var marker: Marker3D = $Marker3D
@onready var health_component: HealthComponent = $HealthComponent
@export var unit_maker: UnitMakerComponent;
var game: GameScene;
var entity_holder: EntityHolder;

#export so that in test environment everything is ok
@export var player_id: String = "";
@export var team: int = 0;
@export var color: int = 0;

#combat things
@export var health: int = 400;
@export var max_health: int = 400;
@export var is_alive: bool = true;

const CONSTRUCTION_COMPLETE: int = 10;
var construction_value: float = 0;
@export var is_constructed: bool = false;

#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: GlobalConstants.BUILD_DWARF_WORKER_DICTIONARY,
	2: {},
	3: {},
	4: {},
	5: {},
	6: {},
	7: {},
	8: {},
	9: {},
	10:{},
	11: GlobalConstants.CANCEL_ACTION_DICTIONARY,
}





##NOW IS IN UNIT MAKER COMPONENT
#constant used for spawning
const SPAWN_DISTANCE: int = 1;
const BUILD_LIMIT: int = 8;
@export var target_location: Vector3;
@export var target: Node3D;

@export var build_time: int;
@export var build_item: Dictionary;
@export var build_queue: Array[Dictionary];
@export var build_progress: float;
@export var build_speed_mult: float = 1;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	pass # Replace with function body.

#Only process if you are the server, properties will get synced to other players across RPC calls
func _process(delta: float) -> void:
	if(!is_constructed):
		if(construction_value >= CONSTRUCTION_COMPLETE):
			is_constructed = true;
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

func set_selected() -> void:
	highlight_mesh.set_deferred("visible", true);
	health_component.show_health();

func unset_selected() -> void:
	highlight_mesh.set_deferred("visible", false);
	health_component.hide_health();

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
#i did
func cancel_queued(p_int: int) -> void:
	#refund the cost if you are clearing out the queue
	if(!multiplayer.is_server()):
		return;
	print("canceled!")
	var queued: Dictionary = build_queue.pop_at(p_int);
	if(!queued.has("cost")):
		return;
	var _success: int = game.refund_resources(player_id,queued["cost"]);

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


#called by multipalyer authority only
func spawn_unit(filepath: String) -> void:
	if (!multiplayer.is_server()):
		return;
	var start_vector: Vector2 = Vector2(global_position.x, global_position.z);
	var end_vector: Vector2 = start_vector + Vector2.ONE;
	if(is_instance_valid(target)):
		print("target");
		end_vector = Vector2(target.global_position.x, target.global_position.z);
	elif(target_location != Vector3.ZERO):
		print("location");
		end_vector = Vector2(target_location.x, target_location.z);
	var final_vector: Vector2 = (end_vector - start_vector).normalized() * SPAWN_DISTANCE;
	var spawn_position: Vector3 = Vector3(global_position.x + final_vector.x, global_position.y, global_position.z + final_vector.y)    ;
	print(spawn_position);
	var spawn_dict: Dictionary ={
	#temp use of a direct constant, the filepath will depend on starting race
	"file_path" = filepath,
	"team" = team,
	"player_id" = player_id,
	"position" = spawn_position,
	"color" = color
	}
	spawn_unit_rpc.rpc(spawn_dict)
	print("called spawn unit from %s" % player_id)
	pass;

#special case where the object needs to add the child to keep refernce
@rpc("authority", "call_local", "reliable")
func spawn_unit_rpc(spawn_dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != Lobby.multiplayer_server_id):
		return
	if (spawn_dict.is_empty()):
		return;
	var unit: Node3D = load(spawn_dict["file_path"]).instantiate();
	unit.team = spawn_dict["team"];
	unit.player_id = spawn_dict["player_id"];

	#color is an int, the object will access the actual color via GlobalConstants
	unit.color = spawn_dict["color"];
	if("resource_depot" in unit):
		unit.resource_depot = self;
	entity_holder.register_entity(unit);
	var pos: Vector3 = spawn_dict["position"];
	print(pos);
	unit.global_position = spawn_dict["position"];
	if(!multiplayer.is_server()):
		return;
	if(is_instance_valid(target)):
		var cmd : Dictionary = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
		cmd["target_node_path"] = target.get_path();
		unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);
	elif(target_location != Vector3.ZERO):
		var cmd : Dictionary = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();
		cmd["location"] = target_location;
		unit.request_cmd.rpc_id(Lobby.multiplayer_server_id, cmd);

#This is the only real logic in the script
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
		#Cancel action
		"GC002":
			if(build_item != null):
				cancel_build();
			return;
		#Target location / Move to Location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			target_location = cmd_data["location"];
			target = null;
		#cancel specific queued
		"GC004":
			if(!cmd_data.has("int")):
				return;
			cancel_queued(cmd_data["int"]);
		#Build Dwarf Worker
		"DS001":
			if(build_queue.size() >= BUILD_LIMIT):
				#we cant do this command
				return;
			build_queue.append(cmd_data);

#combat will eventually be handled outside of main script?
func take_damage(damage_int: int, attacking_team: int) -> void:
	if(!multiplayer.is_server() || attacking_team == team):
		return;
	var died: bool = health_component.take_damage(damage_int);
	if(died):
		var entity_path: String = get_path();
		entity_holder.rpc("derigister unit", entity_path);


func heal(heal_int: int, healing_team: int) -> void:
	if(!multiplayer.is_server() || healing_team != team):
		return;
	health_component.heal(heal_int);
