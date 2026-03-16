extends Node3D
const ENTITY_NAME: String = "Mineral"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.RESOURCE;
const PREVIEW: Texture2D = preload(GlobalConstants.MINERAL_PLACEHOLDER_TEXTURE);
const RESOURCE_TYPE: GlobalConstants.ResourceType = GlobalConstants.ResourceType.MINERAL

@onready var highlight_mesh: MeshInstance3D = $HighlightMesh

var is_selected : bool = false;

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
	pass;

func set_selected() -> void:
	is_selected = true;
	highlight_mesh.set_deferred("visible", true);

func unset_selected() -> void:
	is_selected = false;
	highlight_mesh.set_deferred("visible", false);
