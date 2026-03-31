class_name SyncComponent
extends MultiplayerSynchronizer

func stop_sync()->void:
	var config: SceneReplicationConfig = get_replication_config();
	for property: NodePath in config.get_properties():
		config.remove_property(property);
