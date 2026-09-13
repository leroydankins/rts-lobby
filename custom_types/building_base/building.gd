class_name Building
extends Entity

@export var building_type: Array[GlobalConstants.BuildingType];

@export_category("Required Components")
@export_group("Class Components")
## Every selectable entity will have a mesh that shows it is clicked, often a circle that [br]
## changes color locally based on if it is an enemy, friend, or neutral
@export var anim: AnimationPlayer
@export var health_component: HealthComponent;

@export_group("Instantiated Components")

## Does not have a bool for being selected, waiting until it needs to
func set_selected() -> void:
	highlight_mesh.set_deferred("visible", true);
	health_component.show_health();

## Does not have a bool for being selected, waiting until it needs to
func unset_selected() -> void:
	highlight_mesh.set_deferred("visible", false);
	health_component.hide_health();
