class_name CommandComponent
extends Node

@export var parent: CharacterBody3D;
@export var anim: AnimationPlayer
@export var nav_component: NavComponent
@export var interact_component: InteractComponent
@export var aggro_component: AggroComponent

@export var is_worker: bool = false;

#extra game refernces,  bad and get rid of this later
var game: GameScene;
var entity_holder: EntityHolder;
var player_data_manager: PlayerDataManager;


#Export functions to allow for property syncing
@export var target_pos: Vector3;
@export var target: Node3D;
@export var cmd_queue: Array[Dictionary] = [];


#if we are a worker functionality
var build_started: bool = false;
@export var held_resource: Array = [];
@export var building: Node3D; #synced?
@export var resource_depot: Node3D #synced?

func _ready() ->void:
	player_data_manager = get_tree().get_first_node_in_group("PlayerDataManager")
	aggro_component.aggrod.connect(on_aggrod);
	interact_component.entity_enter.connect(on_entity_entered);
	interact_component.entity_exit.connect(on_entity_exited);

func request_cmd(cmd_data: Dictionary) -> void:
	if(cmd_data.has("cost")): #Rework to use team id instead of cost
		var cost_arr: Array = cmd_data["cost"];
		var success: bool = player_data_manager.spend_resources(parent.color, cost_arr);
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
				var resources: Array[int] = [cmd_queue[i]["cost"]];
				#for those reading this, I know this is probably bad code smell or whatever to be calling a parent method but whatever dude
				player_data_manager.refund_resources(parent.color, resources);
			pass;
		#finish whatever you were doing, put that command into history dictionary
		finish_cmd();
		#Clear the queued commands queued after refunding for them all, if you do not want to clear the queue, use queue_cmd()
		cmd_queue.clear();
	cmd_queue.append(cmd_data);

	#only respond to specific commands that directly interrupt?
	#all unit specific commands like special abilities may be in here but for the most part we just queue the command
	if(cmd_queue.size() == 1):
		start_cmd();

func start_cmd() -> void:
	aggro_component.can_aggro = false;
	var cmd: Dictionary = cmd_queue[0];
	match cmd["command"]:
		GlobalConstants.Commands.MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd["location"];
			if(t_pos != nav_component.target_position):
				nav_component.set_target_position(t_pos)
			if(nav_component.navigating == false):
				nav_component.navigating = true;
			target_pos = t_pos;
		GlobalConstants.Commands.HOLD:
			nav_component.navigating = false;
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
			nav_component.set_target_position(target.global_position);
			nav_component.navigating = true;
			#Reassign command type based on entity
			match target.ENTITY_TYPE:
				GlobalConstants.EntityType.UNIT:
					#Is this unit an enemy? Attack, else, follow
					if (target.team != parent.team):
						cmd["command"] = GlobalConstants.Commands.ATTACK;
					else:
						cmd["command"] = GlobalConstants.Commands.FOLLOW;
				GlobalConstants.EntityType.BUILDING:
					if (target.team != parent.team):
						cmd["command"] = GlobalConstants.Commands.ATTACK;
					else:
						if(is_worker): #if we are a worker we can have more than 1 thing to do for buildings
							if(!target.is_constructed):
								building = target;
								build_started = true;
								cmd["command"] = GlobalConstants.Commands.BUILD;
							elif(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.RESOURCE_DEPOT) && !held_resource.is_empty()):
								resource_depot = target;
								cmd["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
								parent.set_collision_mask_value(parent.UNIT_COLLISION_MASK,false)
								parent.set_collision_layer_value(parent.UNIT_COLLISION_MASK,false)
						else:
							cmd["command"] = GlobalConstants.Commands.GO_TO;
				GlobalConstants.EntityType.RESOURCE:
					if(is_worker):
						cmd["command"] = GlobalConstants.Commands.GET_RESOURCE;
						parent.set_collision_mask_value(parent.UNIT_COLLISION_MASK,false)
						parent.set_collision_layer_value(parent.UNIT_COLLISION_MASK,false)
					else:
						cmd["command"] = GlobalConstants.Commands.GO_TO;
		GlobalConstants.Commands.ATTACK:
			#currently there is no way to send an attack command directly to this point, but will probably implement an attack command via hotkey - erh 2/28/26
			var tar: Node3D = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			nav_component.set_target_position(target.global_position);
			nav_component.navigating = true;
		GlobalConstants.Commands.FOLLOW:
			#currently there is no way to send an follow command directly to this point - erh 2/28/26
			var tar: Node3D = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			nav_component.set_target_position(target.global_position);
			nav_component.navigating = true;
		GlobalConstants.Commands.BUILD:
			if(!is_worker):
				finish_cmd();
				return;
			#drop command since it doesnt work
			if (!cmd.has("file_path") || !cmd.has("location")):
				"we did not have the right arguments"
				#move on to next cmd
				finish_cmd();
			var t_pos: Vector3 = cmd["location"];
			nav_component.set_target_position(t_pos)
			nav_component.navigating = true;
			target_pos = t_pos;
		GlobalConstants.Commands.ATTACK_MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd["location"];
			if(t_pos != nav_component.target_position):
				nav_component.set_target_position(t_pos)
			if(nav_component.navigating == false):
				nav_component.navigating = true;
			target_pos = t_pos;
			if(!aggro_component.enemy_array.is_empty()):
				#we will have to iterate through the array to find the closest one later on
				target = aggro_component.enemy_array[0]
				cmd["command"] = GlobalConstants.Commands.ATTACK;
				nav_component.set_target_position(target.global_position);
				nav_component.navigating = true;
				aggro_component.can_aggro = true;
	#if we now have a valid target and we ar already able to interact with them, go to finish command
	if(is_instance_valid(target)):
		for i: int in interact_component.interactable_array.size(): #check if the target is already in range
			if(target == interact_component.interactable_array[i]):
				complete_cmd();

func complete_cmd() ->void:
	if(!is_multiplayer_authority()):
		return;
	match cmd_queue[0]["command"]:
		GlobalConstants.Commands.MOVE:
			nav_component.navigating = false;
			finish_cmd();
		GlobalConstants.Commands.FOLLOW:
			if(target.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
				if(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.RESOURCE_DEPOT)):
					resource_depot = target;
				finish_cmd();
			nav_component.navigating = false;
		GlobalConstants.Commands.BUILD:
				if(build_started != true):
					build_started = true;
					var building_file_path : String = cmd_queue[0]["file_path"];
					spawn_building(building_file_path);
					#This needs to be determined from the size of the building, i dont know how to do that yet
					var new_loc: Vector3 = Vector3(parent.global_position.x + 1.5, parent.global_position.y, parent.global_position.z + 1.5);
					##TODO
					#DO SOME VALIDITY CHECKING ON IF LOCATION IS OK
					nav_component.set_target_position(new_loc);
				else:
					nav_component.navigating = false;
		GlobalConstants.Commands.GET_RESOURCE:
			nav_component.navigating = false;
			#held resource second slot in array is GlobalConstants.ResourceType
			if(!held_resource.is_empty() && held_resource[1] == target.RESOURCE_TYPE):
				var g_pos: Vector3 = resource_depot.global_position;
				nav_component.set_target_position(g_pos);
				cmd_queue[0]["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
				nav_component.navigating = true;
				return;
			if (target.in_use):
				return;
			if (target.resource_amount <= 0):
				##TODO
				#switch to nearby resource or finish command
				finish_cmd();
				return;
			target.in_use = true;
			anim.play("extract_resource");
		GlobalConstants.Commands.RETURN_RESOURCE:
			nav_component.navigating = false;
			#Final game will use event system and signals to handle this instead of direct coupling I guess? FUTURE ETHAN PROBLEM LOL
			#Allow resource depots to handle messaging system for resource gain?
			player_data_manager.gain_resources(parent.color, held_resource);
			held_resource.clear();
			cmd_queue[0]["command"] = GlobalConstants.Commands.GET_RESOURCE;
			if(target.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
				nav_component.set_target_position(target.global_position);
				nav_component.navigating = true;
			else:
				finish_cmd();
		GlobalConstants.Commands.ATTACK:
			nav_component.navigating = false;
			anim.play("attack_target");
		_:
			nav_component.navigating = false;
			finish_cmd();

#called only by multiplayer instance
func finish_cmd() -> void:
	if(!cmd_queue.is_empty()):
	#get next command in sequence by removing the current
		var _cmd: Dictionary = cmd_queue.pop_front();

	#reinit state data
	if(is_worker):
		#only workers change their collision mask/layer in game
		parent.set_collision_mask_value(parent.UNIT_COLLISION_MASK, true)
		parent.set_collision_layer_value(parent.UNIT_COLLISION_MASK,true);
		build_started = false;
		if(anim.current_animation == "extract_resource"):
			target.in_use = false;
	target = null;
	target_pos = Vector3.ZERO;
	nav_component.navigating = false;
	aggro_component.can_aggro = false;
	anim.stop();

	#IDLE STATE DATA
	if(cmd_queue.is_empty()):
		if(aggro_component.auto_aggro):
			aggro_component.can_aggro = true;

	else:
		start_cmd();
		#start command sets wait_bool to false at the end

#this only gets called by the multiplayer host because it is called from the host in complete_cmd
func spawn_building(filepath: String) -> void:
	if (!is_multiplayer_authority()):
		return;
	var spawn_dict: Dictionary ={
	"file_path" = filepath,
	"team" = parent.team,
	"position" = cmd_queue[0]["location"],
	"color" = parent.color,
	}
	spawn_building_rpc.rpc(spawn_dict);

#special case where the object needs to add the child to keep refernce
@rpc("authority", "call_local", "reliable")
func spawn_building_rpc(dict: Dictionary) -> void:
	if (multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		return
	if (dict.is_empty()):
		return;
	var obj: Node3D = load(dict["file_path"]).instantiate();
	obj.team = dict["team"];
	#color is an int, the object will access the actual color via GlobalConstants
	obj.color = dict["color"];
	building = obj;
	building.is_constructed = false;
	entity_holder.register_entity(obj);
	obj.global_position = dict["position"];
	target_pos = Vector3.ZERO;

func on_aggrod(enemy: Node3D) -> void:
	if(!is_multiplayer_authority()):
		return;
	#Clear the queued commands queued after refunding for them all since we have been aggro'd
	cmd_queue.clear();
	if(!cmd_queue.is_empty()):
		match cmd_queue[0]["command"]:
			GlobalConstants.Commands.ATTACK_MOVE:
				finish_cmd();
				var cmd: Dictionary = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
				cmd["target_node_path"] = enemy.get_path();
				cmd_queue.append(cmd);
				start_cmd();
			GlobalConstants.Commands.HOLD:
				target = enemy;
				pass;
			_:
				return; #This is to say, other commands that we have you dont really care
	else:
			var cmd: Dictionary = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
			cmd["target_node_path"] = enemy.get_path();
			cmd_queue.append(cmd);
			start_cmd();

func on_entity_entered(entity: Node3D) ->void:
	if(cmd_queue.is_empty()):
		return;
	if (entity != target):
		return;
	var command: int = cmd_queue[0]["command"];
	#special case that we are not navigating to target but returning resource to resource depot
	if(is_worker):
		if(command == GlobalConstants.Commands.RETURN_RESOURCE):
			if(entity == resource_depot):
				complete_cmd();
				return;
		if(command == GlobalConstants.Commands.GET_RESOURCE):
			if(entity.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
				complete_cmd();
				return;
	if(!is_instance_valid(target)):
		return;
	complete_cmd();

func on_entity_exited(entity: Node3D) ->void:
	if(cmd_queue.is_empty()):
		return;
	if(!is_instance_valid(target)):
		return;
	if (entity != target):
		return;
	var command: int = cmd_queue[0]["command"];
	if (command == GlobalConstants.Commands.FOLLOW): #if the target has left our interact range
		nav_component.navigating = true;
	elif(command == GlobalConstants.Commands.ATTACK): #currentlyinteract range is the SAME as our attack range uwu
		if(anim.current_animation == "attack_target"):
			anim.stop();
		nav_component.navigating = true;
