class_name Unit
extends Entity
const UNIT_COLLISION_MASK: int = 3;

@export var ENTITY_NUMBER: EntityConstants.Units = EntityConstants.Units.DWARF_WORKER;
@export var ENTITY_HEIGHT_OFFSET: float = .5;
@export var MOVE_SPEED: float = 4.0;
@export var UNIT_TYPE: Array[GlobalConstants.UnitType];


@export_category("Required Components")
@export_group("Class Components")
## Every selectable entity will have a mesh that shows it is clicked, often a circle that [br]
## changes color locally based on if it is an enemy, friend, or neutral
@export var anim: AnimationPlayer
@export var command_component: CommandComponent
@export var nav_component: NavComponent
@export var health_component: HealthComponent;

@export_group("Instantiated Components")
## Must be instantiated scene due to the complex set-up of multiple nodes for displaying health

## Does not have a bool for being selected, waiting until it needs to
func set_selected() -> void:
	highlight_mesh.set_deferred("visible", true);
	health_component.show_health();

## Does not have a bool for being selected, waiting until it needs to
func unset_selected() -> void:
	highlight_mesh.set_deferred("visible", false);
	health_component.hide_health();
