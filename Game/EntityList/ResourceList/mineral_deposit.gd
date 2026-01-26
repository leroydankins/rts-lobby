extends Node2D
const ENTITY_NAME: String = "Mineral"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.RESOURCE;
const RESOURCE_TYPE: GlobalConstants.ResourceType = GlobalConstants.ResourceType.MINERAL
#Do an object type to fix the process field of input gui for cleaner ui
const PREVIEW: Texture2D = preload("res://Resources/minerals.png");

@onready var label: Label = $Label
@export var resource_amount: int = 1200;
var return_amt: int = 25;
var in_use: bool = false;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func extract_resource() -> Array:
	if (resource_amount <= 0):
		return [0, RESOURCE_TYPE];
	if (resource_amount < return_amt):
		return_amt = resource_amount;
	resource_amount -= return_amt;
	return [return_amt, RESOURCE_TYPE];

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = str(resource_amount);
