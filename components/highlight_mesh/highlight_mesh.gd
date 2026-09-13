@tool
class_name HighlightMesh
extends MeshInstance3D
const GREEN_COLOR: Vector3 = Vector3(0,0.8,0.15);
const RED_COLOR: Vector3 = Vector3(.5,0.05,0.05);
const YELLOW_COLOR: Vector3 = Vector3(.5, .5, .1);
const HIGHLIGHTS: Array[Vector3] = [GREEN_COLOR, RED_COLOR, YELLOW_COLOR]
const MESH_RESOURCE_FILEPATH: String = "uid://bbxbndclj12rc"
enum HighlightColors
{
	GREEN,
	RED,
	YELLOW,
}
@export var preset_size: Vector2 = Vector2(2,2):
	set(value):
		if(Engine.is_editor_hint()):
			if (value.x < 0):
				value.x = 0.5;
			if (value.y < 0):
				value.y = 0.5;
			set_size(value);
		preset_size = value;
@export_group("Pre-view colors")
## Only edit this value in the menu!
@export var default_color: HighlightColors = 0 as HighlightColors:
	set(value):
		if (Engine.is_editor_hint()):
			set_highlight_color(value);
		default_color = value;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		mesh = ResourceLoader.load(MESH_RESOURCE_FILEPATH,"Resource",ResourceLoader.CacheMode.CACHE_MODE_IGNORE) as PlaneMesh;
		mesh.size = preset_size;
	else:
		set_highlight_color(default_color)
		set_size(preset_size);

func highlight() -> void:
	set_deferred("visible", true);

func unhighlight() -> void:
	set_deferred("visible", false);

func set_highlight_color(highlight_int: int) ->void:
	var shader_mat: ShaderMaterial = mesh.material;
	print("wtf")
	shader_mat.set_shader_parameter("line_color", HIGHLIGHTS[highlight_int])

func set_size(new_size: Vector2) ->void:
	var p_mesh: PlaneMesh = mesh;
	p_mesh.size = new_size;
	print(new_size)
