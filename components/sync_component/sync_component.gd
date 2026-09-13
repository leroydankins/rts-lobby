class_name SyncComponent
extends MultiplayerSynchronizer

## SyncComponent is called by group to start/stop syncing [br][br]
## Automatically stops syncing when the player has lost or died (Called in game_scene) [br][br]
## Do not stop syncing if they are going to stay to spectate a multiplayer game?

func _ready() ->void:
	# In case this was not done in the scene during unit creation
	add_to_group("sync_component", true);


func stop_sync()->void:
	var config: SceneReplicationConfig = get_replication_config();
	for property: NodePath in config.get_properties():
		config.remove_property(property);
