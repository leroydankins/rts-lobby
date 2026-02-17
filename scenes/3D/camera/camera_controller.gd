extends Node3D

@onready var camera: Camera3D = $Camera3D;
@export var START_POS: Vector3 = Vector3(0,7,7);
@export_category("Camera movement")
@export var camera_speed: float = 6.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera.position = START_POS
	print(camera.position);
	camera.look_at(position);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var movement : Vector3 = Vector3.ZERO

	# Keyboard movement (uses default ui_* actions)
	if Input.is_action_pressed("camera_right"):
		movement.x += 1
	if Input.is_action_pressed("camera_left"):
		movement.x -= 1
	if Input.is_action_pressed("camera_up"):
		movement.z -= 1
	if Input.is_action_pressed("camera_down"):
		movement.z += 1

	# Shift boost (make sure you added 'ui_shift' in Input Map)
	var speed_multiplier : float = 2.0 if Input.is_action_pressed("shift") else 1.0

	# Move root in camera's yaw frame
	if movement.length() > 0.0:
		movement = movement.normalized();
		position += movement * camera_speed * speed_multiplier * delta
