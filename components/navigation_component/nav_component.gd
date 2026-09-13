class_name NavComponent
extends NavigationAgent3D

@export var parent: Entity
var is_navigating: bool;
@export var sync_state: PackedByteArray:
	get:
		var sync: PackedByteArray;
		sync.resize(4)
		sync.encode_u8(0,is_navigating)
		return sync;
	set(value):
		assert(typeof(value) == TYPE_PACKED_BYTE_ARRAY and value.size() == 4, "Invalid 'sync_state' array type or size (must be TYPE_PACKED_BYTE_ARRAY of size 4).")
		is_navigating = value.decode_u8(0);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var agent: RID = get_rid()
	## Enable avoidance
	#NavigationServer3D.agent_set_avoidance_enabled(agent, true)
	## Create avoidance callback
	#NavigationServer3D.agent_set_avoidance_callback(agent, Callable(self, "_avoidance_done"))
	## Switch to 3D avoidance
	#NavigationServer3D.agent_set_use_3d_avoidance(agent, true)
	pass;

func _physics_process(delta: float) -> void:
	#only do stuff if we are
	#1. the multipalyer authority
	#2. we are currently navigating around or moving
	var new_velocity: Vector3;
	var next_path_position: Vector3;
	var current_agent_position: Vector3;
	if(!is_multiplayer_authority()):
		return;
	if NavigationServer3D.map_get_iteration_id(get_navigation_map()) == 0:
		return
	if(is_navigation_finished()):
		return;
	if(is_navigating):
		current_agent_position= parent.global_position
		next_path_position= get_next_path_position()
		new_velocity = current_agent_position.direction_to(next_path_position) * parent.MOVE_SPEED
	else:
		new_velocity = Vector3.ZERO
	_on_velocity_computed(new_velocity, delta)

func _on_velocity_computed(safe_velocity: Vector3, delta: float) -> void:
	parent.global_position = parent.global_position.move_toward(parent.global_position + safe_velocity, delta * parent.MOVE_SPEED)

func actor_setup() -> void:
	#wait for the first physics frame so the navigation server can sync
	await get_tree().physics_frame;
	#dont do anything in this because we arent moving right away
