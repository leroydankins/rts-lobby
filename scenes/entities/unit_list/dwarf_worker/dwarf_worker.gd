extends CharacterBody3D
const ENTITY_NAME: String = "DwarfWorker"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.UNIT;
const PREVIEW: Texture2D = preload(GlobalConstants.UNIT_PLACEHOLDER_TEXTURE);
@onready var highlight_mesh: MeshInstance3D = $HighlightMesh
@onready var resource_mesh: MeshInstance3D = $ResourceMesh
@onready var anim: AnimationPlayer = $Anim
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var health_component: HealthComponent = $HealthComponent
@onready var interact_area: Area3D = $InteractArea
@export var aggro_area: AggroComponent

const MOVE_SPEED: float = 4.0;
const GET_RESOURCE_COLLISION_MASK: int = 0b1001 # This is set with direct method call atm
const REGULAR_COLLISION_MASK: int = 0b1011; #OBE: Method Call set_collision_mask_value(3, true)
const UNIT_COLLISION_MASK: int = 3;

@export var team: int = 0;
var color: int = 0;
@export var player_id: String = "";

#combat things
@export var health: int = 25;
@export var max_health: int = 25;
@export var is_alive: bool = true;
@export var damage: int = 8;

#extra game refernces,  bad and get rid of this later
var game: GameScene;
var entity_holder: EntityHolder;
@export var resource_depot: Node3D
#navigation bool
var navigating: bool = false;

#LOCAL VARIABLE, DO NOT SYNC ACROSS PLAYERS
var is_selected: bool = false;

#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: GlobalConstants.MOVE_TO_DICTIONARY,
	2: GlobalConstants.ATTACK_MOVE_DICTIONARY,
	3: {},
	4: {},
	5: {},
	6: {},
	7: GlobalConstants.BUILD_DWARF_SETTLEMENT_DICTIONARY,
	8: GlobalConstants.BUILD_DWARF_BARRACKS_DICTIONARY,
	9: {},
	10: {},
	11: GlobalConstants.CANCEL_ACTION_DICTIONARY,
	}

#Export functions to allow for property syncing
@export var target_pos: Vector3;
@export var target: Node3D;
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
	navigation_agent.navigation_finished.connect(on_nav_finished);
	interact_area.body_entered.connect(on_interact_area_entered);
	interact_area.area_entered.connect(on_interact_area_entered);
	interact_area.body_exited.connect(on_interact_area_exited);
	interact_area.area_exited.connect(on_interact_area_exited);
	aggro_area.aggrod.connect(on_aggrod)
	#navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	#check if we don't have a correct building type for resource depot? why the fuck would it be wrong
	if(resource_depot != null):
		if(resource_depot.team != team):
			resource_depot = null;
			return;
		assert(resource_depot.BUILDING_TYPE.has(GlobalConstants.BuildingType.RESOURCE_DEPOT));

func _physics_process(delta: float) ->void:
	if(!is_alive):
		return;
	#only do stuff if we are
	#1. the multipalyer authority
	#2. we are currently navigating around or moving
	if(!multiplayer.is_server()):
		return;
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if(navigating):
		var current_agent_position: Vector3 = global_position
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		var new_velocity : Vector3 = current_agent_position.direction_to(next_path_position) * MOVE_SPEED
		if navigation_agent.avoidance_enabled:
			navigation_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)
	else:
		velocity = Vector3.ZERO;
		if(!is_on_floor()):
			velocity += get_gravity();
		move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!is_alive):
		return;
	if(!held_resource.is_empty()):
		resource_mesh.visible = true;
		look_at(Vector3.BACK)
	else:
		resource_mesh.visible = false;
	#TEMPRORARU

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
			cmd_queue.clear();
			return;
		#MOVE TO LOCATION
		GlobalConstants.Commands.MOVE:
			pass;
		GlobalConstants.Commands.BUILD:
		#BUILD BUILDING
		#######WILL HAVE TO REWORK THIS
		##but when tho? erh 2/28/26
			if (!build_started):
				navigating = true;
			#if build started
			else:
				if(!navigating):
					if(!building.is_constructed):
						building.construction_value += 1 * delta;
						#add to the value of the building
					else:
						finish_cmd()
		#END BUILD BUILDING
		##CURRENTLY NEVER IN HERE
		GlobalConstants.Commands.TARGET:
			#This will only branch out to other types of commands, we do not stay in the target command
			#assign location to local var so that we dont have to keep going through dictionary every frame
			#if the target is not valid, dump the command?
			if(!is_instance_valid(target)):
				finish_cmd();
				return;
		#END OF TARGET
		GlobalConstants.Commands.FOLLOW:
			#Find refernced target in the tree, RPC passes this data as a string nodepath
			if(!is_instance_valid(target)):
				var tar: Node3D = get_tree().root.get_node(cmd_queue[0]["target_node_path"]);
				if (tar == null || !is_instance_valid(tar)):
					push_error("target did not exist")
					navigating = false;
					finish_cmd();
					return;
				else:
					target = tar;
			##check if we can visibly see the target when we implement fog of war
			var t_pos:Vector3 = target.global_position;
			if (navigation_agent.target_position != t_pos):
				navigation_agent.set_target_position(t_pos);
			##no area3d right now, just use 2d vector distance to
			#var tar_2d: Vector2 = Vector2(t_pos.x, t_pos.z);
			#var pos_2d: Vector2 = Vector2(global_position.x, global_position.z)
			##need a way to set navigation for when you hit a target man
			#if(pos_2d.distance_to(tar_2d) > 1):
				#navigating = true;
			#else:
				#navigating = false;
		#End of follow
		GlobalConstants.Commands.ATTACK:
			#Find refernced target in the tree, RPC passes this data as a string nodepath
			if(!is_instance_valid(target) || !target.is_alive):
				finish_cmd();
				return;
			##check if we can visibly see the target when we implement fog of war
			var t_pos:Vector3 = target.global_position;
			if (navigation_agent.target_position != t_pos):
				navigation_agent.set_target_position(t_pos);
		GlobalConstants.Commands.GET_RESOURCE:
			pass;
			##Eventually we dont want to get the target every frame, but whatever we need a more fleshed out game to change this and its just an optimization
			##Find refernced target in the tree, RPC passes this data as a string nodepath
			#if(!is_instance_valid(target)):
				#var tar: Node3D = get_tree().root.get_node(cmd_queue[0]["target_node_path"]);
				#if (tar == null || !is_instance_valid(tar)):
					#push_error("target did not exist")
					#navigating = false;
					#finish_cmd();
					#return;
				#else:
					#target = tar;
			#if (target.ENTITY_TYPE != GlobalConstants.EntityType.RESOURCE):
				#finish_cmd();
				#navigating = false;
				#return;
			####MOVE TO RESOURCE
			###check if we can visibly see the target when we implement fog of war
			#var t_pos:Vector3 = target.global_position;
			#if(t_pos != navigation_agent.target_position):
				#navigation_agent.set_target_position(t_pos)
			##no area3d right now, just use 2d vector distance to
			##var tar_2d: Vector2 = Vector2(t_pos.x, t_pos.z);
			##var pos_2d: Vector2 = Vector2(global_position.x, global_position.z)
			##if close enough and it wasn't our turn yet on navigation finished
			if(navigating == false && anim.current_animation != "extract_resource"):
				if (target.resource_amount <= 0):
					##TODO
					#switch to nearby resource or finish command
					finish_cmd();
					return;
				if (target.in_use):
					return;
				wait_bool = true;
				target.in_use = true;
				anim.play("extract_resource");
		GlobalConstants.Commands.RETURN_RESOURCE:
			###RETURN RESOURCE
			#CURRENTLY HARD CODED HOME BUILDING UWU
			if(resource_depot == null || !is_instance_valid(resource_depot)):
				#find home building?
				##TODO
				resource_depot = null;
				finish_cmd();
				return;
			if(resource_depot.team != team):
				resource_depot = null;
				finish_cmd();
			var g_pos: Vector3 = resource_depot.global_position;
			if (g_pos != navigation_agent.target_position):
				navigation_agent.set_target_position(g_pos);
		#DEFAULT CASE
		_:
			pass;

func set_selected() -> void:
	is_selected = true;
	highlight_mesh.set_deferred("visible", true);
	health_component.show_health();

func unset_selected() -> void:
	is_selected = false;
	highlight_mesh.set_deferred("visible", false);
	health_component.hide_health();

func start_cmd() -> void:
	aggro_area.can_aggro = false;
	var cmd: Dictionary = cmd_queue[0];
	match cmd["command"]:
		GlobalConstants.Commands.MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd["location"];
			if(t_pos != navigation_agent.target_position):
				navigation_agent.set_target_position(t_pos)
			if(navigating == false):
				navigating = true;
			target_pos = t_pos;

		GlobalConstants.Commands.HOLD:
			navigating = false;

			#need a hold bool?
			pass;
		GlobalConstants.Commands.TARGET:
			#decide what to do based on entity type
			var tar: Node3D = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			navigation_agent.set_target_position(target.global_position);
			navigating = true;
			#Reassign command type based on entity
			match target.ENTITY_TYPE:
				GlobalConstants.EntityType.UNIT:
					#Is this unit an enemy? Attack, else, follow
					if (target.team != team):
						cmd["command"] = GlobalConstants.Commands.ATTACK;
					else:
						cmd["command"] = GlobalConstants.Commands.FOLLOW;
				GlobalConstants.EntityType.BUILDING:
					if (target.team != team):
						cmd["command"] = GlobalConstants.Commands.ATTACK;
					else:
						if(!target.is_constructed):
							building = target;
							build_started = true;
						elif(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.RESOURCE_DEPOT) && !held_resource.is_empty()):
							resource_depot = target;
							cmd["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
							set_collision_mask_value(UNIT_COLLISION_MASK,false)
						else:
							cmd["command"] = GlobalConstants.Commands.FOLLOW;
				GlobalConstants.EntityType.RESOURCE:
					cmd["command"] = GlobalConstants.Commands.GET_RESOURCE;
					set_collision_mask_value(UNIT_COLLISION_MASK,false)

		GlobalConstants.Commands.ATTACK:
			#currently there is no way to send an attack command directly to this point, but will probably implement an attack command via hotkey - erh 2/28/26
			var tar: Node3D = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			navigation_agent.set_target_position(target.global_position);
			navigating = true;
		GlobalConstants.Commands.FOLLOW:
			#currently there is no way to send an follow command directly to this point - erh 2/28/26
			var tar: Node3D = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			navigation_agent.set_target_position(target.global_position);
			navigating = true;
		GlobalConstants.Commands.BUILD:
			#drop command since it doesnt work
			if (!cmd.has("file_path") || !cmd.has("location")):
				"we did not have the right arguments"
				#move on to next cmd
				finish_cmd();
			var t_pos: Vector3 = cmd["location"];
			navigation_agent.set_target_position(t_pos)
			navigating = true;
			target_pos = t_pos;
		GlobalConstants.Commands.ATTACK_MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd["location"];
			if(t_pos != navigation_agent.target_position):
				navigation_agent.set_target_position(t_pos)
			if(navigating == false):
				navigating = true;
			target_pos = t_pos;
			aggro_area.can_aggro = true;
			pass;

	#END OF START COMMAND
	wait_bool = false;

#called only by multipalyer instance
func finish_cmd() -> void:
	#pause to reset state and set up for next command
	wait_bool = true;
	#finish any animation you are on
	#sync this with network state
	anim.stop();
	if(!cmd_queue.is_empty()):
	#get next command in sequence
		var cmd: Dictionary = cmd_queue.pop_front();
		#log the previous command
		cmd_history.append(cmd);

	#reinit state data
	set_collision_mask_value(UNIT_COLLISION_MASK, true)
	build_started = false;
	target = null;
	target_pos = Vector3.ZERO;
	navigating = false;
	aggro_area.can_aggro = false;

	#IDLE STATE DATA
	if(cmd_queue.is_empty()):
		if(aggro_area.auto_aggro):
			aggro_area.can_aggro = true;

	else:
		start_cmd();
		#start command sets wait_bool to false at the end
	wait_bool = false;


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
			return;

	#If we do not queue command, clear the command queue and refund
	if(!cmd_data.has("queue")):
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

	#else we do not clear
	#We generally dont directly set our target or target position direclty in our cmd mnemonic match because it can be a queued command
	var cmd_mnemonic: String = cmd_data["mnemonic"]
	match cmd_mnemonic:
		##Default case will just append the cmd data, we only do
		##Target unit
		#"GC001":
			#if (!cmd_data.has("target_node_path")):
				#return;
			##Find refernced target in the tree just to check validity, RPC passes this data as a string nodepath
			#var tar: Node = get_tree().root.get_node(cmd_data["target_node_path"])
			#if (tar == null || !is_instance_valid(tar)):
				#push_error("target did not exist");
				#return;
			#if("ENTITY_TYPE" not in tar):
				#return;
			#cmd_queue.append(cmd_data)
		##Cancel action
		#"GC002":
			##do we pass here because request command already does this??
			#pass;
		##Move to location
		#"GC003":
			#if (!cmd_data.has("location")):
				#return;
			#if(cmd_data["command"] != GlobalConstants.Commands.MOVE):
				#return;
			#cmd_queue.append(cmd_data)
		##Move to location
		#"GC004":
			#if (!cmd_data.has("location")):
				#return;
			#if(cmd_data["command"] != GlobalConstants.Commands.MOVE):
				#return;
			#cmd_queue.append(cmd_data)


		_: #not a specific command! Queue it  up baby
			cmd_queue.append(cmd_data);

	#only respond to specific commands that directly interrupt?
	#all unit specific commands like special abilities may be in here but for the most part we just queue the command
	if(cmd_queue.size() == 1):
		start_cmd();

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

	#color is an int, the object will access the actual color via GlobalConstants
	obj.color = dict["color"];
	building = obj;
	building.is_constructed = false;
	entity_holder.register_entity(obj);
	obj.global_position = dict["position"];
	wait_bool = false;
	target_pos = Vector3.ZERO;
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


#animation track calls
func extract_resources() -> void:
	var cmd: Dictionary = cmd_queue[0];
	if cmd["command"] != GlobalConstants.Commands.GET_RESOURCE:
		finish_cmd();
		return;
	var tar: Node3D = get_tree().root.get_node(cmd_queue[0]["target_node_path"]);
	if (tar == null || !is_instance_valid(tar)):
		push_error("target did not exist")
		finish_cmd();
		return;
	if(!tar.has_method("extract_resource")):
		finish_cmd();
		return;
	if (tar.resource_amount <= 0):
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
	if(is_instance_valid(resource_depot)):
		navigation_agent.set_target_position(resource_depot.global_position);
		navigating = true;
		cmd["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
	else:
		finish_cmd();

#later this may be done via collision shapes?
func attack_enemy() ->void:
	if(!is_alive):
		return;
	if(!multiplayer.is_server()):
		return;
	if(!is_instance_valid(target)):
		return;
	if (target.team == team):
		return;
	var dmg: int = damage;
	target.take_damage(dmg, self);
	print(dmg);

#combat
#called by enemy unit or attack area?
func take_damage(damage_int: int, attacking_node: Node3D) -> void:
	if(!multiplayer.is_server() || attacking_node.team == team):
		return;
	print(damage_int)
	#later we will play death animations!!
	var died: bool = health_component.take_damage(damage_int);
	if(died):
		is_alive = false;
		var entity_path: String = get_path();
		entity_holder.rpc("remove_entity", entity_path);
		#play death animation
		anim.stop();

func heal(heal_int: int, healing_node: Node3D) -> void:
	if(!multiplayer.is_server() || healing_node.team != team):
		return;
	health_component.heal(heal_int);

func on_nav_finished() ->void:
	match cmd_queue[0]["command"]:
		GlobalConstants.Commands.MOVE:
			navigating = false;
			finish_cmd();
		GlobalConstants.Commands.FOLLOW:
			navigating = false;
		GlobalConstants.Commands.BUILD:
				if(build_started != true):
					build_started = true;
					wait_bool = true;
					var building_file_path : String = cmd_queue[0]["file_path"];
					spawn_building(building_file_path);
					#This needs to be determined from the size of the building, i dont know how to do that yet
					var new_loc: Vector3 = Vector3(global_position.x + 1.5, global_position.y, global_position.z + 1.5);
					##TODO
					#DO SOME VALIDITY CHECKING ON IF LOCATION IS OK
					navigation_agent.set_target_position(new_loc);
				else:
					navigating = false;
		GlobalConstants.Commands.GET_RESOURCE:
			navigating = false;
			#held resource second slot in array is GlobalConstants.ResourceType
			if(!held_resource.is_empty() && held_resource[1] == target.RESOURCE_TYPE):
				var g_pos: Vector3 = resource_depot.global_position;
				navigation_agent.set_target_position(g_pos);
				cmd_queue[0]["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
				navigating = true;
				return;
			if (target.in_use):
				return;
			if (target.resource_amount <= 0):
				##TODO
				#switch to nearby resource or finish command
				finish_cmd();
				return;
			wait_bool = true;
			target.in_use = true;
			anim.play("extract_resource");
		GlobalConstants.Commands.RETURN_RESOURCE:
			wait_bool = true;
			navigating = false;
			#Final game will use event system and signals to handle this instead of direct coupling I guess? FUTURE ETHAN PROBLEM LOL
			#Allow resource depots to handle messaging system for resource gain?
			game.gain_resources(player_id, held_resource);
			held_resource.clear();
			cmd_queue[0]["command"] = GlobalConstants.Commands.GET_RESOURCE;
			if(target.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
				navigation_agent.set_target_position(target.global_position);
				wait_bool = false;
				navigating = true;
			else:
				finish_cmd();

func on_interact_area_entered(body: Node3D) ->void:
	if(!multiplayer.is_server()):
		return
	if(cmd_queue.is_empty()):
		return;
	var command: int = cmd_queue[0]["command"];
	#special case that we are not navigating to target but returning resource to resource depot
	if(command == GlobalConstants.Commands.RETURN_RESOURCE):
		if(body == resource_depot):
			on_nav_finished();
			return;
	if(!is_instance_valid(target)):
		return;
	if (body != target):
		return;
	on_nav_finished();
	if (command == GlobalConstants.Commands.ATTACK):
		print("got here")
		navigating = false;
		anim.play("attack_target");

func on_interact_area_exited(body: Node3D) ->void:
	if(!multiplayer.is_server()):
		return
	if(cmd_queue.is_empty()):
		return;
	if(!is_instance_valid(target)):
		return;
	if (body != target):
		return;
	var command: int = cmd_queue[0]["command"];
	if (command == GlobalConstants.Commands.FOLLOW):
		navigating = true;
	elif(command == GlobalConstants.Commands.ATTACK):
		if(anim.current_animation == "attack_target"):
			anim.stop();
		navigating = true;

func on_aggrod(enemy: Node3D) -> void:
	#refund any costed commands
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
	#finish whatever you were doing, put that command into history dictionary
	finish_cmd();
	#Clear the queued commands queued after refunding for them all, if you do not want to clear the queue, use queue_cmd()
	cmd_queue.clear();

	var cmd: Dictionary = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
	cmd["target_node_path"] = enemy.get_path();
	cmd_queue.append(cmd);
	start_cmd();
