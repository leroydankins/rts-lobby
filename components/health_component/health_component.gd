@tool
class_name HealthComponent
extends Node3D



const HEALTHBAR_RESOURCE_FILL: String = "uid://bskkp8d15ek8w";
const HEALTHBAR_RESOURCE_BG: String = "uid://13cokopx1lfh"
const GREEN_COLOR: Color = Color("58ff78cb");
const RED_COLOR: Color = Color("f01800cb")
const YELLOW_COLOR: Color = Color("#f1c232cb");
const HEALTH_COLORS: Array[Color] = [GREEN_COLOR, RED_COLOR, YELLOW_COLOR]
enum HealthColors
{
	GREEN,
	RED,
	YELLOW,
}
@onready var health_bar: ProgressBar = $SubViewport/Healthbar
@onready var hp_sprite: Sprite3D = $HPSprite
@onready var subview: SubViewport = $SubViewport
@export_category("Stat Parameters")
## Edit this in the instanced scene, not in the base scene of the health component
@export var health: int;
## Edit this in the instanced scene, not in the base scene of the health component
@export var max_health: int;
@export var is_alive: bool = true;
@export_category("Config Paramters")
## Only edit this in the engine! Directly edit subview.size in game, this is only for visualizing edits without making editable children!
@export var subview_size: Vector2i = Vector2i(96, 8):
	set(value):
		if(Engine.is_editor_hint()):
			if (value.x < 32):
				value.x = 32;
			if (value.y < 4):
				value.y = 4;
			set_health_size(value)
		subview_size = value;
@export_group("Pre-view color")
## Only edit this in the engine!
@export var default_color: HealthColors = 0 as HealthColors:
	set(value):
		if (Engine.is_editor_hint()):
			set_health_color(value);
		default_color = value;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		var view_texture: ViewportTexture = hp_sprite.texture;
		view_texture.viewport_path = "SubViewport";
		health_bar.add_theme_stylebox_override("background", ResourceLoader.load(HEALTHBAR_RESOURCE_BG,"Resource",ResourceLoader.CacheMode.CACHE_MODE_IGNORE))
		health_bar.add_theme_stylebox_override("fill", ResourceLoader.load(HEALTHBAR_RESOURCE_FILL,"Resource",ResourceLoader.CacheMode.CACHE_MODE_IGNORE))
	else:
		health_bar.max_value = max_health;
		health_bar.value = health;
		#TODO
		#if(global bool to have healthbars show always):
			#visible = true;
		#else:
		hide_health();
	set_health_color(default_color)
	set_health_size(subview_size);


func set_health_color(color_int: int) ->void:
	var color_res: StyleBoxFlat = health_bar.get_theme_stylebox("fill",)
	color_res.bg_color = HEALTH_COLORS[color_int]

func set_health_size(size: Vector2i) ->void:
	var p_subview: SubViewport = $SubViewport
	p_subview.size = size;

func show_health() ->void:
	#if(global bool to have healthbars show always):
		#visible = true;
	hp_sprite.set_deferred("visible", true);

func hide_health() ->void:
	#if(global bool to have healthbars show always):
		#visible = true;
	hp_sprite.set_deferred("visible", false);

func take_damage(damage_int: int) -> bool:
	var died: bool = false;
	#placeholder for when armor is in the game
	var dmg_reduction: int = 0;
	var dmg_taken: int = damage_int - dmg_reduction;
	health -= dmg_taken;
	health_bar.value = health;
	if (health <= 0):
		health = 0;
		is_alive = false;
		died = true;
	return died;

func heal(heal_int: int) -> void:
	if(health >= max_health):
		return;
	health += heal_int;
	if (health >= max_health):
		health = max_health;
	return;
