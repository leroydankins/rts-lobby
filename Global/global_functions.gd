class_name GlobalFunctions
extends Node

#Return array of lobby player data. maybe have this outside of the lobby implementation
static func get_player_property_array(dict: Dictionary[String,Dictionary], key: String) -> Array[Variant]:
	var return_arr: Array[Variant];
	if (!GlobalConstants.KEY_ARRAY.has(key)):
		push_error("couldnt get valid array");
		return return_arr;
	for player: String in dict:
		return_arr.append(dict[player][key])
	return return_arr;

#returns an array of only the player username and the requested value
static func get_player_property_dict(dict: Dictionary[String,Dictionary], key: String) -> Dictionary[String,Variant]:
	var return_dict: Dictionary[String,Variant];
	if (!GlobalConstants.KEY_ARRAY.has(key)):
		push_error("couldnt get valid array");
		return return_dict;
	for player: String in dict:
		return_dict[player] = dict[player][key];
	return return_dict;
