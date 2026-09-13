class_name Entity
extends Area3D
## Base entity class used by all entities in game. [br]
## Inherits Area3D to be clickable and accessible by [CommandComponent] [br] [br]
## Holds common properties and references required nodes that each entity needs to function [br]
## Optional nodes are included but require configurating to use functionality [br]

@export_category("Entity Properties")
@export var ENTITY_NAME: String = ""
@export var ENTITY_TYPE: GlobalConstants.EntityType;
@export var PREVIEW: Texture2D;
@export_group("Synced Properties")
## Export values so that we can sync
@export var team: int = 0;
## Export values so that we can sync
@export var color: int = 0;

@export_group("Entity Configuration")

@export_category("Required Components")
@export_group("Class Components")
## Every selectable entity will have a mesh that shows it is clicked, often a circle that [br]
## changes color locally based on if it is an enemy, friend, or neutral
@export var highlight_mesh: MeshInstance3D
@export var entity_mesh: MeshInstance3D
@export_group("Instantiated Components")
@export var sync_component: SyncComponent

# LOCAL VARIABLE, DO NOT SYNC ACROSS PLAYERS
## Bool to track if this unit is currently selected [br]
## This boolean is local because it is specific to the player selecting the unit
var is_selected: bool = false;

## Does not have a bool for being selected, waiting until it needs to
func set_selected() -> void:
	highlight_mesh.set_deferred("visible", true);


## Does not have a bool for being selected, waiting until it needs to
func unset_selected() -> void:
	highlight_mesh.set_deferred("visible", false);
