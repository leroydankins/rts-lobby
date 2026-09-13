class_name DwarfWorker
extends Unit
#ENTITY CONSTANTS
#const ENTITY_NAME: String = "Dwarf Worker"
#const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.UNIT;
#const ENTITY_NUMBER: EntityConstants.Units = EntityConstants.Units.DWARF_WORKER;
#const UNIT_TYPE: Array[int] = [GlobalConstants.UnitType.LAND, GlobalConstants.UnitType.BUILDER,]
#const PREVIEW: Texture2D = preload(GlobalConstants.UNIT_PLACEHOLDER_TEXTURE);
#const ENTITY_HEIGHT_OFFSET: float = .5;
#const MOVE_SPEED: float = 4.0;
#const UNIT_COLLISION_MASK: int = 3;
var feed_resource : FeedResource = preload(GlobalConstants.ACTION_FEED_PATH)
@export var resource_mesh: MeshInstance3D
#@export var anim: AnimationPlayer
#@export var navigation_agent: NavigationAgent3D

#@export var health_component: HealthComponent
@export var interact_component: Area3D
@export var aggro_component: AggroComponent


@export var damage: int = 8;

#extra game refernces,  bad and get rid of this later
var player_data_manager: PlayerDataManager;
var map_grid: MapGrid;
## Keep a reference to the last known depot for the unit
var resource_depot: Node3D


#LOCAL VARIABLE, DO NOT SYNC ACROSS PLAYERS

var interactable_array: Array = [];
#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: GlobalConstants.MOVE_TO_DICTIONARY,
	2: GlobalConstants.ATTACK_MOVE_DICTIONARY,
	3: {},
	4: GlobalConstants.BUILD_DWARF_BARRACKS_DICTIONARY,
	5: {},
	6: {},
	7: GlobalConstants.BUILD_DWARF_SETTLEMENT_DICTIONARY,
	8: {},
	9: {},
	10: {},
	11: GlobalConstants.CANCEL_ACTION_DICTIONARY,
	}

# Export functions to allow for property syncing
@export var target_pos: Vector3;
@export var target: Node3D;
#@export var cmd_queue: Array[Dictionary] = [];
#@export var cmd_history: Array[Dictionary] = [];
## Slot 0 is amount, slot 1 is Resource Type (GlobalConstants.ResourceType)
@export var held_resource: Array = [0,0];

var build_started: bool = false;

var wait_bool: bool = false;
var building: Node3D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _discard_return: int;
	map_grid = get_tree().get_first_node_in_group("map_grid")
	player_data_manager = get_tree().get_first_node_in_group("player_data_manager");
	_discard_return = nav_component.navigation_finished.connect(on_nav_finished);
	_discard_return = interact_component.body_entered.connect(on_interact_component_entered);
	_discard_return = interact_component.area_entered.connect(on_interact_component_entered);
	_discard_return = interact_component.body_exited.connect(on_interact_component_exited);
	_discard_return = interact_component.area_exited.connect(on_interact_component_exited);
	_discard_return = aggro_component.aggrod.connect(on_aggrod)
	#navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	#check if we don't have a correct building type for resource depot? why the fuck would it be wrong
	if(resource_depot != null):
		if(resource_depot.team != team):
			resource_depot = null;
			return;
		assert(resource_depot.BUILDING_TYPE.has(GlobalConstants.BuildingType.DEPOT));

#func _physics_process(delta: float) ->void:
	##only do stuff if we are
	##1. the multipalyer authority
	##2. we are currently navigating around or moving
	#if(!is_multiplayer_authority()):
		#return;
	#if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		#return
	#if(navigating):
		#var current_agent_position: Vector3 = global_position
		#var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		#var new_velocity : Vector3 = current_agent_position.direction_to(next_path_position) * MOVE_SPEED
		#if navigation_agent.avoidance_enabled:
			#navigation_agent.set_velocity(new_velocity)
		#else:
			#_on_velocity_computed(new_velocity)
	#else:
		#velocity = Vector3.ZERO;
		#if(!is_on_floor()):
			#velocity += get_gravity();
		#move_and_slide()
#
#func _on_velocity_computed(safe_velocity: Vector3) -> void:
	#if (!is_multiplayer_authority()):
		#return;
	#velocity = safe_velocity
	#move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var tar: Node3D;
	if(!health_component.is_alive):
		return;
	if(held_resource[0] != 0):
		resource_mesh.visible = true;
	else:
		resource_mesh.visible = false;
	## Find where to look eventually
	if(!is_multiplayer_authority()):
		return;
	if(command_component.is_queue_empty()):
		# current_state = UnitState.IDLE;
		return;
	# Wait bool is to allow time for RPC calls to server before continuing
	if(wait_bool):
		return;
	# have to go in separate function to not interrupt returns on multiplayer sync
	match command_component.cmd_queue[0]["command"]:
		# CANCEL QUEUE
		GlobalConstants.Commands.CANCEL:
			command_component.flush_cmd_queue();
			return;
		# MOVE TO LOCATION
		GlobalConstants.Commands.MOVE:
			pass;
		GlobalConstants.Commands.BUILD:
		# BUILD BUILDING
		#######WILL HAVE TO REWORK THIS
		# but when tho? erh 2/28/26
		# now erh 7/22/26
			if (!build_started):
				nav_component.is_navigating = true;
			# if build started
			else:
				if(!nav_component.is_navigating):
					if(!building.is_constructed):
						building.construction_value += 1 * delta;
						# add to the value of the building
					else:
						finish_cmd()
		# END BUILD BUILDING
		# CURRENTLY NEVER IN HERE
		GlobalConstants.Commands.TARGET:
			# This will only branch out to other types of commands, we do not stay in the target command
			# assign location to local var so that we dont have to keep going through dictionary every frame
			# if the target is not valid, dump the command?
			if(!is_instance_valid(target)):
				finish_cmd();
				return;
		# END OF TARGET
		GlobalConstants.Commands.FOLLOW:
			# Find refernced target in the tree, RPC passes this data as a string nodepath
			##TODO Drop them if they leave in game sight? cant target something that is not visible?
			if(!is_instance_valid(target)):
				# drop the command because we no longer have a valid target but we did not finish the command
				tar = get_tree().root.get_node(command_component.cmd_queue[0]["target_node_path"]);
				if (tar == null || !is_instance_valid(tar)):
					push_error("target did not exist")
					nav_component.is_navigating = false;
					finish_cmd();
					return;
				else:
					target = tar;
			# check if we can visibly see the target when we implement fog of war
			var t_pos:Vector3 = target.global_position;
			if (nav_component.target_position != t_pos):
				nav_component.set_target_position(t_pos);
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
			if (nav_component.target_position != t_pos):
				nav_component.set_target_position(t_pos);
		GlobalConstants.Commands.GET_RESOURCE:
			if(nav_component.is_navigating == false && anim.current_animation != "extract_resource"):
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
			if(resource_depot.is_alive != true):
				resource_depot = null;
				finish_cmd();
				return;
			var g_pos: Vector3 = resource_depot.global_position;
			if (g_pos != nav_component.target_position):
				nav_component.set_target_position(g_pos);
		#DEFAULT CASE
		_:
			pass;

func start_cmd() -> void:
	var cmd: Dictionary = command_component.cmd_queue[0];
	var t_pos: Vector3;
	var tar: Node3D
	aggro_component.can_aggro = false;
	feed_resource.add_message("Dwarf Worker started  %s  command!" % cmd["name"])
	match cmd["command"]:
		GlobalConstants.Commands.MOVE:
			#assign location to local var so that we dont have to keep going through dictionary every frame
			t_pos = cmd["location"];
			if(t_pos !=nav_component.target_position):
				nav_component.set_target_position(t_pos)
			if(nav_component.is_navigating == false):
				nav_component.is_navigating = true;
			target_pos = t_pos;
		GlobalConstants.Commands.HOLD:
			nav_component.is_navigating = false;
			#need a hold bool?
			return
		GlobalConstants.Commands.TARGET:
			#decide what to do based on entity type
			tar = get_tree().root.get_node(cmd["target_node_path"]);
			# Check validity of target AND check if visible to player
			if (!is_instance_valid(tar)):
				push_error("target did not exist")
				finish_cmd();
				return;
			else:
				target = tar;
			nav_component.set_target_position(target.global_position);
			nav_component.is_navigating = true;
			# Reassign command type based on entity
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
							cmd["command"] = GlobalConstants.Commands.BUILD;
						elif(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.DEPOT) && held_resource[0] > 0):
							resource_depot = target;
							cmd["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
							set_collision_mask_value(UNIT_COLLISION_MASK,false)
							set_collision_layer_value(UNIT_COLLISION_MASK,false)
						else:
							cmd["command"] = GlobalConstants.Commands.FOLLOW;
				GlobalConstants.EntityType.RESOURCE:
					cmd["command"] = GlobalConstants.Commands.GET_RESOURCE;
					set_collision_mask_value(UNIT_COLLISION_MASK,false)
					set_collision_layer_value(UNIT_COLLISION_MASK,false)
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
			# If this is a building grid command
			if(cmd.has("grid_location")):
				t_pos = cmd["building_position"];
				nav_component.set_target_position(t_pos)
				nav_component.is_navigating = true;
				target_pos = cmd["building_position"];
			elif (cmd.has("location")):
				t_pos = cmd["location"];
				nav_component.set_target_position(t_pos)
				nav_component.is_navigating = true;
				target_pos = t_pos;
			else:
				#Refund
				player_data_manager.refund_resources(color, cmd["cost"]);
				#move on to next cmd
				finish_cmd();
				return;
		GlobalConstants.Commands.ATTACK_MOVE:
			# assign location to local var so that we dont have to keep going through dictionary every frame
			t_pos = cmd["location"];
			if(t_pos != nav_component.target_position):
				nav_component.set_target_position(t_pos)
			if(nav_component.is_navigating == false):
				nav_component.is_navigating = true;
			target_pos = t_pos;
			aggro_component.can_aggro = true;
	if(is_instance_valid(target)):
		for i: int in interactable_array.size(): #check if the target is already in range
			if(target == interactable_array[i]):
				on_nav_finished();

## Resets all state data and clears out the current command in the command queue
## called only by multipalyer instance
func finish_cmd() -> void:
	#pause to reset state and set up for next command
	wait_bool = true;
	# finish any animation you are on
	# sync this with network state
	if(!command_component.is_queue_empty()):
		feed_resource.add_message("Dwarf Worker finished  %s  command!" % command_component.cmd_queue[0]["name"])
		command_component.end_cmd();
	# reinit state data
	set_collision_mask_value(UNIT_COLLISION_MASK, true)
	set_collision_layer_value(UNIT_COLLISION_MASK,true);
	build_started = false;
	if(anim.current_animation == "extract_resource" && is_instance_valid(target)):
		target.in_use = false;
	target = null;
	target_pos = Vector3.ZERO;
	nav_component.is_navigating = false;
	aggro_component.can_aggro = false;
	anim.stop();

	#IDLE STATE DATA
	if(command_component.is_queue_empty()):
		if(aggro_component.auto_aggro):
			aggro_component.can_aggro = true;
	else:
		start_cmd();
		# start command sets wait_bool to false at the end



# This should already be called by the authority?
@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!is_multiplayer_authority()):
		return
	command_component.request_cmd(cmd_data);
	#all unit specific commands like special abilities may be in here but for the most part we just queue the command
	if(command_component.cmd_queue.size() == 1):
		start_cmd();
	feed_resource.add_message("Dwarf Worker requested  %s  command!" % cmd_data["name"])

### command data comes in but can be shared among units if we do not duplicate the command
#@rpc("any_peer","call_local","reliable")
#func request_cmd(cmd_data: Dictionary) -> void:
	#if(!is_multiplayer_authority()):
		#return
	#if !cmd_data.has("mnemonic"):
		#push_error("command invalid");
		#return;
	#if(cmd_data.has("cost")): #Rework to use team id instead of cost
		#var cost_arr: Array = cmd_data["cost"];
		#var success: bool = player_data_manager.spend_resources(color,cost_arr);
		#if (!success):
			#return;
	## If we do not queue command, clear the command queue and refund
	#if(!cmd_data.has("queue")):
		#flush_cmd_queue();
#
	## We generally dont directly set our target or target position direclty in our cmd mnemonic match because it can be a queued command
	#var cmd_mnemonic: String = cmd_data["mnemonic"]
	#match cmd_mnemonic:
		#_: # not a specific command! Queue it up baby
			#cmd_queue.append(cmd_data);
	## only respond to specific commands that directly interrupt?
	## all unit specific commands like special abilities may be in here but for the most part we just queue the command
	#if(cmd_queue.size() == 1):
		#start_cmd();

## Called when we reach a state in action where we proceed to a future step in a command or complete command
func update_command() ->void:
	var current_command: Dictionary = command_component.get_current_command();
	var spawn_dict: Dictionary;
	var grid_tiles: Array;
	var x_start: int;
	var z_start: int;
	var x_size: int;
	var z_size: int;
	var new_target_location: Vector3
	if(!is_multiplayer_authority()):
		return
	if !current_command:
		return;
	match current_command["command"]:
		GlobalConstants.Commands.MOVE:
			nav_component.is_navigating = false;
			finish_cmd();
		GlobalConstants.Commands.FOLLOW:
			if(target.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
				if(target.BUILDING_TYPE.has(GlobalConstants.BuildingType.DEPOT)):
					resource_depot = target;
				finish_cmd();
			nav_component.is_navigating = false;
		GlobalConstants.Commands.BUILD:
				# I dont actually get this anymore
				if(build_started == true):
					nav_component.is_navigating = false;
					return;
				# Map Grid Version
				# Validate these are still available locations
				if current_command.has("grid_location"):
					# Move var to start later
					spawn_dict = current_command.duplicate();
					grid_tiles = spawn_dict["grid_tiles"];
					x_start = grid_tiles[0]
					z_start = grid_tiles[1]
					x_size = grid_tiles[2]
					z_size= grid_tiles[3]
					# placeholder shi rn since we arent in a full scene
					spawn_dict["color"] = color;
					spawn_dict["team"] = team;
					# Check that it is still valid
					if(map_grid.is_tiles_valid(Vector3i(x_start,0,z_start),Vector3i(x_size,0,z_size),spawn_dict["building_properties"])):
						#use tiles needs to move to RPC
						map_grid.use_tiles(x_start, z_start, x_size, z_size)
						spawn_building_rpc.rpc(spawn_dict)
					else:
						finish_cmd();
						return;
					# This will be removed when we properly have the builder spawn it from outside the object, but maintain option for if spawned inside somehow
					new_target_location = Vector3(global_position.x + 1.5, global_position.y, global_position.z + 1.5);
					## TODO
					# DO SOME VALIDITY CHECKING ON IF LOCATION IS OK
					nav_component.set_target_position(new_target_location);
					build_started = true;
					return

		GlobalConstants.Commands.GET_RESOURCE:
			nav_component.is_navigating = false;
			# held resource second slot in array is GlobalConstants.ResourceType
			if(held_resource[0] > 0 && held_resource[1] == target.RESOURCE_TYPE):
				var g_pos: Vector3 = resource_depot.global_position;
				nav_component.set_target_position(g_pos);
				current_command["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
				nav_component.is_navigating = true;
				return;
			if (target.in_use):
				return;
			if (target.resource_amount <= 0):
				##TODO
				# switch to nearby resource or finish command
				finish_cmd();
				return;
			wait_bool = true;
			target.in_use = true;
			anim.play("extract_resource");
		GlobalConstants.Commands.RETURN_RESOURCE:
			wait_bool = true;
			nav_component.is_navigating = false;
			#Final game will use event system and signals to handle this instead of direct coupling I guess? FUTURE ETHAN PROBLEM LOL
			# Allow resource depots to handle messaging system for resource gain?
			get_tree().call_group("player_data_manager","refund_resources",color,held_resource)
			#player_data_manager.gain_resources(color, held_resource);
			# Reset the resource to base
			held_resource[0] = 0;
			current_command["command"] = GlobalConstants.Commands.GET_RESOURCE;
			if(target.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
				nav_component.set_target_position(target.global_position);
				wait_bool = false;
				nav_component.is_navigating = true;
			else:
				finish_cmd();
		GlobalConstants.Commands.ATTACK:
			nav_component.is_navigating = false;
		_:
			nav_component.is_navigating = false;
			finish_cmd();


# special case where the object needs to add the child to keep refernce
@rpc("authority", "call_local", "reliable")
func spawn_building_rpc(spawn_dict: Dictionary) -> void:
	var grid_tiles: Array = spawn_dict["grid_tiles"];
	var file_path : String = spawn_dict["file_path"]
	var entity: Node3D = load(file_path).instantiate();
	entity.team = spawn_dict["team"];
	#color is an int, the object will access the actual color via GlobalConstants
	entity.color = spawn_dict["color"];
	# We add child in entity_holder, call the group to not have to get a reference to the node
	get_tree().call_group("entity_holder","register_building",entity,grid_tiles)
	entity.global_position = spawn_dict["building_position"];
	building = entity;


## Called via animation track to gain resources and hold them as the playeranimation track calls
func extract_resource() -> void:
	var cmd: Dictionary = command_component.cmd_queue[0];
	var tar: Node3D = get_tree().root.get_node(cmd["target_node_path"]);
	## Resource array[int] that follows the form of [Resource Amount, Resource Type]
	var arr: Array
	if cmd["command"] != GlobalConstants.Commands.GET_RESOURCE:
		finish_cmd();
		return;
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
	arr = tar.extract_resource()
	#held resource = [resource_amount, resource_type]
	assert(arr.size() == 2)
	held_resource = arr;
	wait_bool = false;
	tar.in_use = false;
	if(is_instance_valid(resource_depot)):
		nav_component.set_target_position(resource_depot.global_position);
		nav_component.is_navigating = true;
		cmd["command"] = GlobalConstants.Commands.RETURN_RESOURCE;
	else:
		finish_cmd();

#later this may be done via collision shapes?
func attack_enemy() ->void:
	if(!is_multiplayer_authority()):
		return;
	if(!is_instance_valid(target)):
		return;
	if (target.team == team):
		return;
	var dmg: int = damage;
	target.take_damage(dmg, team);


# combat
# called by enemy unit or attack area?
func take_damage(damage_int: int, attacking_team: int) -> void:
	if(!is_multiplayer_authority() || attacking_team == team):
		return;
	#later we will play death animations!!
	var died: bool = health_component.take_damage(damage_int);
	if(died):
		var entity_path: String = get_path();
		get_tree().call_group("entity_holder","remove_entity", entity_path)
		#entity_holder.rpc("remove_entity", entity_path);
		#play death animation
		anim.stop();

func heal(heal_int: int, healing_node: Node3D) -> void:
	if(!is_multiplayer_authority() || healing_node.team != team):
		return;
	health_component.heal(heal_int);

## Called when nav_component emits signal that we have reached the location desired
func on_nav_finished() ->void:
	update_command();


func on_interact_component_entered(body: Node3D) ->void:
	if(!is_multiplayer_authority()):
		return
	#should always be something interactable because its my god damn setting!
	interactable_array.append(body);
	if(command_component.is_queue_empty()):
		return;
	var current_command: Dictionary = command_component.get_current_command()
	var command_int: int = current_command["command"];
	#special case that we are not navigating to target but returning resource to resource depot
	if(command_int == GlobalConstants.Commands.RETURN_RESOURCE):
		if(body == resource_depot):
			on_nav_finished();
			return;
	if(command_int == GlobalConstants.Commands.GET_RESOURCE):
		if(body.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
			on_nav_finished();
			return;
	if(!is_instance_valid(target)):
		return;
	if (body != target):
		return;
	on_nav_finished();
	match command_int:
		GlobalConstants.Commands.ATTACK:
			anim.play("attack_target");

func on_interact_component_exited(body: Node3D) ->void:
	var current_command: Dictionary
	var command_int: int
	if(!is_multiplayer_authority()):
		return
	for i: int in interactable_array.size():
		if interactable_array[i] == body:
			interactable_array.pop_at(i);
			break;
	if(command_component.is_queue_empty()):
		return;
	if(!is_instance_valid(target)):
		return;
	if (body != target):
		return;
	current_command = command_component.get_current_command()
	command_int = current_command["command"];
	if (command_int == GlobalConstants.Commands.FOLLOW):
		nav_component.is_navigating = true;
	elif(command_int == GlobalConstants.Commands.ATTACK):
		if(anim.current_animation == "attack_target"):
			anim.stop();
		nav_component.is_navigating = true;

func on_aggrod(enemy: Node3D) -> void:
	var cmd: Dictionary
	#if aggro-able
	if(!aggro_component.can_aggro):
		return;
	# flush the command queue
	command_component.flush_cmd_queue();
	#finish whatever you were doing, put that command into history dictionary
	finish_cmd();


	cmd = GlobalConstants.ATTACK_TARGET_DICTIONARY.duplicate();
	cmd["target_node_path"] = enemy.get_path();
	command_component.add_command(cmd);
	#will start the command via a signal from command component
	#start_cmd();
