extends Node

var local_player: Dictionary[String, Variant];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#initialize the dictionary with what we know will be in it
	local_player = {
		"username" = "",
		"ready" = false,
	};
	pass # Replace with function body.


func update_dictionary_data(key: String, data: Variant) -> void:
	var success: bool = local_player.set(key, data)
	if !success:
		push_error("couldnt update dictionary data")
		return;
	#if we are online, update lobby info
	if (Lobby.is_connected):
		print("we are online, sending updated information in rpc to server");
		Lobby.local_update_peer_information.rpc_id(1,str(Lobby.multiplayer.get_unique_id()), local_player);

func update_dictionary_batch(new_dict: Dictionary) -> void:
	if (new_dict.is_empty()):
		push_error("why are you adding an empty dictionary? Denied function call of update_dictionary_batch");
		return;
	local_player = new_dict;
	if (Lobby.is_connected):
		print("we are online");
		Lobby.local_update_peer_information.rpc_id(1,str(Lobby.multiplayer.get_unique_id()), local_player);

#called by the Lobby instance when we have received updated dictionary from server, called as separate function to prevent a loop of updates
func lobby_update_dictionary(new_dict: Dictionary) -> void:
	if (new_dict.is_empty()):
		push_error("why are you adding an empty dictionary? Denied function call of lobby_update_dictionary");
		return;
	local_player = new_dict;
