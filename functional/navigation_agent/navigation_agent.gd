extends NavigationAgent3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var agent: RID = get_rid()
	# Enable avoidance
	NavigationServer3D.agent_set_avoidance_enabled(agent, true)
	# Create avoidance callback
	NavigationServer3D.agent_set_avoidance_callback(agent, Callable(self, "_avoidance_done"))
	# Switch to 3D avoidance
	NavigationServer3D.agent_set_use_3d_avoidance(agent, true)


func actor_setup() -> void:
	#wait for the first physics frame so the navigation server can sync
	await get_tree().physics_frame;

	#dont do anything in this because we arent moving right away
