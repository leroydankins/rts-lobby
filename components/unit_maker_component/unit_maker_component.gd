class_name UnitMakerComponent
extends Node3D
@onready var parent: Node3D = get_parent();
#constant used for spawning
const SPAWN_DISTANCE: int = 3;
const CONSTRUCTION_COMPLETE: int = 10;
const BUILD_LIMIT: int = 8;

@export var build_time: int;
@export var build_item: Dictionary;
@export var build_queue: Array[Dictionary];
@export var build_progress: float;
@export var build_speed_mult: float = 1;

var game: GameScene;
var entity_holder: EntityHolder;

func _ready() ->void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");

#called in process of the building
func build(delta: float) -> void:
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
#i did
func cancel_queued(p_int: int) -> void:
	#refund the cost if you are clearing out the queue
	if(!is_multiplayer_authority()):
		return;
	print("canceled!")
	var queued: Dictionary = build_queue.pop_at(p_int);
	if(!queued.has("cost")):
		return;
	var _success: int = parent.player_data_manager.refund_resources(parent.color,queued["cost"]);

func cancel_build() ->void:
	if(!is_multiplayer_authority()):
		return;
	if(build_item.is_empty()):
		return;
	var cost_arr : Array = build_item["cost"]
	#call refund resources on cost  to player id
	var _success: bool = parent.player_data_manager.refund_resources(parent.color,cost_arr);
	build_item = {};
	build_time = 0;
	build_progress = 0;
	if (!build_queue.is_empty()):
		start_build();


#called by multipalyer authority only
func spawn_unit(filepath: String) -> void:
	if (!is_multiplayer_authority()): # Will call RPC to sync with all players
		return;
	var start_vector: Vector2 = Vector2(global_position.x, global_position.z); #
	var end_vector: Vector2 = start_vector + Vector2.ONE;
	if(is_instance_valid(parent.target)):
		end_vector = Vector2(parent.target.global_position.x, parent.target.global_position.z);
	elif(parent.target_location != Vector3.ZERO):
		end_vector = Vector2(parent.target_location.x, parent.target_location.z);
	var final_vector: Vector2 = (end_vector - start_vector).normalized() * SPAWN_DISTANCE;
	var spawn_position: Vector3 = Vector3(global_position.x + final_vector.x, global_position.y, global_position.z + final_vector.y)    ;

	var spawn_dict: Dictionary ={
	"file_path" = filepath,
	"team" = parent.team,
	"position" = spawn_position,
	"color" = parent.color
	}
	if(parent.BUILDING_TYPE.has(GlobalConstants.BuildingType.RESOURCE_DEPOT)):
		spawn_dict["resource_depot"] = parent.get_path(); #set path of this unit in the tree for RPC call

	var cmd: Dictionary = {}; # Set up any command you want the unit to have at start
	if(is_instance_valid(parent.target)): # if we are targeting something from building
		cmd = GlobalConstants.TARGET_UNIT_DICTIONARY.duplicate();
		cmd["target_node_path"] = parent.target.get_path();
	elif(parent.target_location != Vector3.ZERO): #if we are targeting a spawn location
		cmd = GlobalConstants.MOVE_TO_DICTIONARY.duplicate();
		cmd["location"] = parent.target_location;

	entity_holder.instantiate_entity.rpc(spawn_dict, cmd); # call this on every player
