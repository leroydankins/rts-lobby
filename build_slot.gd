extends Control
signal queue_pressed(slot: int);

@onready var texture_rect: TextureRect = $TextureRect
@onready var button: Button = $Button
@export var slot_num: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_press);
	pass # Replace with function body.

func on_press() -> void:
	queue_pressed.emit(slot_num);

func update_data(texture: Texture2D) -> void:
	texture_rect.texture = texture;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
