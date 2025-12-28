extends Camera2D
const CAMERA_SPEED: int = 400

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("camera_left","camera_right","camera_up","camera_down");
	if (direction):
		position += direction * CAMERA_SPEED * delta;
	pass
