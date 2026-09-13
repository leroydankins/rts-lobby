class_name CommandComponent
extends Node
## Update to Entity after we fix command component to move area3d
@export var parent: Entity;
@export var anim: AnimationPlayer
@export var nav_component: NavComponent
@export var interact_component: InteractComponent
@export var aggro_component: AggroComponent
@export_group("Configuration_Properties")
@export var is_worker: bool = false;

# extra game refernces, bad and get rid of this later
var game: GameScene;
var entity_holder: EntityHolder;
var player_data_manager: PlayerDataManager;
var map_grid: MapGrid

@export_group("Synced Properties (Do not pre-configure)")
# Export functions to allow for property syncing

@export var command_log: Array[Dictionary] = [];
@export var cmd_queue: Array[Dictionary] = [];
## I dont think this will sync on change and I dont want to sync every node state over RPC every frame if I dont have to
@export var sync_state: Array:
	get:
		var arr: Array = [target_pos, target.get_path()];
		if (is_worker):
			arr.append(resource_depot.get_path());
			arr.append(held_resource[0])
			arr.append(held_resource[1])
		return arr
	set(value):
		print("synced sync state")
		assert(typeof(value) == TYPE_ARRAY, "Invalid 'sync_state' array type")
		target_pos = value[0];
		target = get_node(value[1])
		if(is_worker):
			resource_depot = get_node(value[2])
			held_resource[0] = value[3];
			held_resource[1] = value[4];

var target_pos: Vector3;
var target: Node3D;
# if we are a worker functionality
var build_started: bool = false;
var held_resource: Array = [0, 0];
var build_target: Building; #synced?
var resource_depot: Building #synced?

func _ready() ->void:
	var _discard: int;
	player_data_manager = get_tree().get_first_node_in_group("player_data_manager")
	_discard = aggro_component.aggrod.connect(on_aggrod);
	_discard = interact_component.entity_enter.connect(on_entity_entered);
	_discard = interact_component.entity_exit.connect(on_entity_exited);

## RPC'd at the [Entity] node and not in the component [br][br]
## However, may need to RPC so that we can have unit specific animations play for all people?
## Safety check if requesting player is same team/color is done at the [CommandController] node prior to RPC
func request_cmd(cmd_data: Dictionary) -> void:
	if(!is_multiplayer_authority()):
		return
	## Array [ Mineral Cost , Gas Cost]
	var cost_arr: Array;
	## Determines if the command was accepted, initially false and must return be made true
	var success: bool;
	# Had an Array[int] here called resources not sure what it was for and deleted
	if(cmd_data.has("cost")): # Rework to use team id instead of cost
		cost_arr= cmd_data["cost"];
		# Hard reference here to get rid of, we need to somehow access the current resources to be able to gate this activity?
		success = player_data_manager.spend_resources(parent.color, cost_arr);
		if (!success):
			return;
	# If we do not queue command, clear the command queue and refund
	if(!cmd_data.has("queue")):
		flush_cmd_queue();
	cmd_queue.append(cmd_data);
	#only respond to specific commands that directly interrupt?
	#all unit specific commands like special abilities may be in here but for the most part we just queue the command
	#if(cmd_queue.size() == 1):
		#start_cmd();

func add_command(p_cmd: Dictionary) ->void:
	cmd_queue.append(p_cmd.duplicate())

func start_cmd() -> void:
	aggro_component.can_aggro = false;
	var cmd: Dictionary = cmd_queue[0];
	var tar: Node3D;
	match cmd["command"]:
		GlobalConstants.Commands.MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd["location"];
			if(t_pos != nav_component.target_position):
				nav_component.set_target_position(t_pos)
			if(nav_component.is_navigating == false):
				nav_component.is_navigating = true;
			target_pos = t_pos;
		GlobalConstants.Commands.HOLD:
			nav_component.is_navigating = false;
			# need a hold bool?
			pass;
		GlobalConstants.Commands.TARGET:
			# decide what to do based on entity type
			tar = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			nav_component.set_target_position(target.global_position);
			nav_component.is_navigating = true;
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
							# Check if it is not constructed, do not need to check for Building type as it is checked in strategy pattern
							if(!target.is_constructed):
								build_target = target as Building;
								build_started = true;
								cmd["command"] = GlobalConstants.Commands.BUILD;
							elif(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.DEPOT) && held_resource[0] > 0):
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
			tar = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			nav_component.set_target_position(target.global_position);
			nav_component.is_navigating = true;
		GlobalConstants.Commands.FOLLOW:
			#currently there is no way to send an follow command directly to this point - erh 2/28/26
			tar = get_tree().root.get_node(cmd["target_node_path"]);
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			nav_component.set_target_position(target.global_position);
			nav_component.is_navigating = true;
		GlobalConstants.Commands.BUILD:
			if(!is_worker):
				finish_cmd();
				return;
			# drop command since it doesnt work
			if (!cmd.has("file_path") || !cmd.has("location")):
				print("we did not have the right arguments")
				# move on to next cmd
				finish_cmd();
			var t_pos: Vector3 = cmd["location"];
			nav_component.set_target_position(t_pos)
			nav_component.is_navigating = true;
			target_pos = t_pos;
		GlobalConstants.Commands.ATTACK_MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			var t_pos: Vector3 = cmd["location"];
			if(t_pos != nav_component.target_position):
				nav_component.set_target_position(t_pos)
			if(nav_component.is_navigating == false):
				nav_component.is_navigating = true;
			target_pos = t_pos;
			if(!aggro_component.enemy_array.is_empty()):
				#we will have to iterate through the array to find the closest one later on
				target = aggro_component.enemy_array[0]
				cmd["command"] = GlobalConstants.Commands.ATTACK;
				nav_component.set_target_position(target.global_position);
				nav_component.is_navigating = true;
				aggro_component.can_aggro = true;
	#if we now have a valid target and we ar already able to interact with them, go to finish command
	if(is_instance_valid(target)):
		for i: int in interact_component.interactable_array.size(): #check if the target is already in range
			if(target == interact_component.interactable_array[i]):
				complete_cmd();

## Called by unit for clearing the current command out and pushing the next one to slot 0 [br]
## Logs the previous command in cmd_log
func end_cmd() ->void:
	var previous_cmd: Dictionary = cmd_queue.pop_front();
	# log the previous command
	log_command(previous_cmd);


func complete_cmd() ->void:
	if(!is_multiplayer_authority()):
		return;
	match cmd_queue[0]["command"]:
		GlobalConstants.Commands.MOVE:
			nav_component.is_navigating = false;
			finish_cmd();
		GlobalConstants.Commands.FOLLOW:
			if(target.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
				if(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.DEPOT)):
					resource_depot = target;
				finish_cmd();
			nav_component.is_navigating = false;
		#GlobalConstants.Commands.BUILD:
				#if(build_started != true):
					#build_started = true;
					#var building_file_path : String = cmd_queue[0]["file_path"];
					#spawn_building(building_file_path);
					##This needs to be determined from the size of the building, i dont know how to do that yet
					#var new_loc: Vector3 = Vector3(parent.global_position.x + 1.5, parent.global_position.y, parent.global_position.z + 1.5);
					###TODO
					##DO SOME VALIDITY CHECKING ON IF LOCATION IS OK
					#nav_component.set_target_position(new_loc);
				#else:
					#nav_component.is_navigating = false;
		#GlobalConstants.Commands.GET_RESOURCE:
			#nav_component.is_navigating = false;
			## held resource second slot in array is GlobalConstants.ResourceType
			#if(held_resource[0] > 0 && held_resource[1] == target.RESOURCE_TYPE):
				#var g_pos: Vector3 = resource_depot.global_position;
				#nav_component.set_target_position(g_pos);
				#cmd_queue[0]["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
				#nav_component.is_navigating = true;
				#return;
			#if (target.in_use):
				#return;
			#if (target.resource_amount <= 0):
				###TODO
				##switch to nearby resource or finish command
				#finish_cmd();
				#return;
			#target.in_use = true;
			#anim.play("extract_resource");
		#GlobalConstants.Commands.RETURN_RESOURCE:
			#nav_component.is_navigating = false;
			##Final game will use event system and signals to handle this instead of direct coupling I guess? FUTURE ETHAN PROBLEM LOL
			##Allow resource depots to handle messaging system for resource gain?
			#player_data_manager.gain_resources(parent.color, held_resource);
			#held_resource[0] = 0;
			#cmd_queue[0]["command"] = GlobalConstants.Commands.GET_RESOURCE;
			#if(target.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
				#nav_component.set_target_position(target.global_position);
				#nav_component.is_navigating = true;
			#else:
				#finish_cmd();
		GlobalConstants.Commands.ATTACK:
			nav_component.is_navigating = false;
			anim.play("attack_target");
		_:
			nav_component.is_navigating = false;
			finish_cmd();

#called only by multiplayer instance
func finish_cmd() -> void:
	if(!cmd_queue.is_empty()):
	#get next command in sequence by removing the current
		var _cmd: Dictionary = cmd_queue.pop_front();

	# reinit state data
	if(is_worker):
		#only workers change their collision mask/layer in game
		parent.set_collision_mask_value(parent.UNIT_COLLISION_MASK, true)
		parent.set_collision_layer_value(parent.UNIT_COLLISION_MASK,true);
		build_started = false;
		if(anim.current_animation == "extract_resource"):
			target.in_use = false;
	target = null;
	target_pos = Vector3.ZERO;
	nav_component.is_navigating = false;
	aggro_component.can_aggro = false;
	anim.stop();

	# IDLE STATE DATA
	if(cmd_queue.is_empty()):
		if(aggro_component.auto_aggro):
			aggro_component.can_aggro = true;
	else:
		start_cmd();

## Refunds each command if they have an associated cost and the spending has not started
func flush_cmd_queue()->void:
	# If we do not queue command, clear the command queue and refund
	for i: int in cmd_queue.size():
		if(cmd_queue[i].has("cost")):
			if (i == 0 && build_started):
				# backwards way of doing this if statement lol, fix later
				continue;
			# Switched to calling the group and so we should not need a reference anymore
			get_tree().call_group("player_data_manager","refund_resources",[parent.color,cmd_queue[i]["cost"]])
	#finish whatever you were doing, put that command into history dictionary
	# emit signal to finish command in the unit level, maybe we should keep current command as separate from the array so clearing command queue doesnt drop current command
	finish_cmd();
	# Clear the queued commands queued after refunding for them all, if you do not want to clear the queue, use queue_cmd()
	cmd_queue.clear();

func is_queue_empty() ->bool:
	return cmd_queue.is_empty();

func get_current_command() -> Dictionary:
	if(cmd_queue.is_empty()):
		return {};
	return cmd_queue[0];

func log_command(p_cmd: Dictionary) ->void:
	command_log.append(p_cmd);

func on_aggrod(enemy: Node3D) -> void:
	if(!is_multiplayer_authority()):
		return;
	# Clear the queued commands queued after refunding for them all since we have been aggro'd
	cmd_queue.clear();
	var cmd: Dictionary;
	if(!cmd_queue.is_empty()):
		match cmd_queue[0]["command"]:
			GlobalConstants.Commands.ATTACK_MOVE:
				finish_cmd();
				cmd = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
				cmd["target_node_path"] = enemy.get_path();
				cmd_queue.append(cmd);
				start_cmd();
			GlobalConstants.Commands.HOLD:
				target = enemy;
			_:
				return; # This is to say, other commands that we have you dont really care
	else:
			cmd = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
			cmd["target_node_path"] = enemy.get_path();
			cmd_queue.append(cmd);
			start_cmd();

func on_entity_entered(entity: Node3D) ->void:
	var command: int = cmd_queue[0]["command"];
	if(cmd_queue.is_empty()):
		return;
	if (entity != target):
		return;
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
	var command: int = cmd_queue[0]["command"];
	if(cmd_queue.is_empty()):
		return;
	if(!is_instance_valid(target)):
		return;
	if (entity != target):
		return;
	if (command == GlobalConstants.Commands.FOLLOW): #if the target has left our interact range
		nav_component.is_navigating = true;
	elif(command == GlobalConstants.Commands.ATTACK): #currentlyinteract range is the SAME as our attack range uwu
		if(anim.current_animation == "attack_target"):
			anim.stop();
		nav_component.is_navigating = true;
