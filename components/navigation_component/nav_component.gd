class_name NavComponent
extends NavigationAgent3D

@export var parent: CharacterBody3D
@export var navigating: bool;

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
	if(!is_multiplayer_authority()):
		return;
	if NavigationServer3D.map_get_iteration_id(get_navigation_map()) == 0:
		return
	if(navigating):
		var current_agent_position: Vector3 = parent.global_position
		var next_path_position: Vector3 = get_next_path_position()
		var new_velocity : Vector3 = current_agent_position.direction_to(next_path_position) * parent.MOVE_SPEED
		parent._on_velocity_computed(new_velocity)
	else:
		var vel_: Vector3 = Vector3.ZERO;
		if(!parent.is_on_floor()):
			vel_ += parent.get_gravity();
		parent._on_velocity_computed(vel_)

func actor_setup() -> void:
	#wait for the first physics frame so the navigation server can sync
	await get_tree().physics_frame;

	#dont do anything in this because we arent moving right away
