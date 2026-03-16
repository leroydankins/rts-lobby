class_name HealthComponent
extends Node3D

@onready var healthbar: ProgressBar = $SubViewport/Healthbar
@onready var hp_sprite: Sprite3D = $HPSprite

@export var health: int;
@export var max_health: int;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if(global bool to have healthbars show always):
		#visible = true;
	healthbar.max_value = max_health;
	healthbar.value = health;
	hide_health();
	pass # Replace with function body.

func set_color(team_int: int) ->void:
	#0 is player (green)
	#1 is enemy(red)
	#2 is ally(yellow)
	pass;

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
	healthbar.value = health;
	if (health <= 0):
		health = 0;
		died = true;
	return died;

func heal(heal_int: int) -> void:
	if(health >= max_health):
		return;
	health += heal_int;
	if (health >= max_health):
		health = max_health;
	return;
