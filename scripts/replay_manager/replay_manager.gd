extends Node
var replay_array: Array[Dictionary]
#

var command_array: Array[Dictionary] = [
#
]
var cmd_info : Dictionary = {
	#date_time of command
	#filepath of unit commanded
	#command dictionary
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	#Load in all replays on the file system

	pass # Replace with function body.

func log_cmd(cmd_dict: Dictionary) ->void:
	#command time
	command_array.append(cmd_dict);
	#unit commanded : node_path string

	#command dictionary
	pass

func initialize_replay() ->void:
	pass;

func finalize_replay() -> void:
	#add replay to array, save the replay to the filesystem in a new save location

	#date and time
	var date_time: String = Time.get_datetime_string_from_system();
	pass;
