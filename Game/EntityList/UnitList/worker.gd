extends Area2D

var team: int = 0;
var color: int = 0;

var health: float = 0;
var cmd_dict_array: Array[Dictionary] = []
#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: {},
	2: {},
	3: {},
	4: {},
	5: {},
	6 : GlobalConstants.CANCEL_ACTION_DICTIONARY,
	7 : GlobalConstants.TARGET_DICTIONARY,
	8 : GlobalConstants.MOVE_TO_DICTIONARY
	}
var cmd_dict_1: Dictionary = {
	"WK001" : {
		"name" : "Build Brewery",
		"description" : "Breweries are needed to expand your supply, more beer more dwarves",
		"file_path" : GlobalConstants.WORKER_FILEPATH,
		"build_time" : 10,
		"sprite_path" : "res://Resources/CommandSprites/placeholder_unit.png"
		},
	"WK002" : {
		"name" : "Build Barracks",
		"description" : "Barracks build ground soldiers",
		"file_path" : GlobalConstants.WORKER_FILEPATH,
		"build_time" : 10,
		"sprite_path" : "res://Resources/CommandSprites/placeholder_unit.png"
		}

}
var cmd_queue: Array = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@rpc("any_peer","call_local","reliable")
func request_cmd(data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if !data.has("mnemonic"):
		push_error("command invalid");
		return;
	var cmd: String = data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			if (!data.has("target_node_path")):
				return;
			var target: Node = get_tree().root.get_node(data["target_node_path"])
			if target == null:
				push_error("target did not exist");
			return;
		#Cancel action
		"GC002":
			pass;
		#Target location
		"GC003":
			if (!data.has("location")):
				return;
			var location: Vector2 = data["location"];

@rpc("any_peer","call_local","reliable")
func request_command(command: int) ->void:
	if(!multiplayer.is_server()):
		return
	print("requesting command %s" % command);
	#if command is something that has to request game, like spawn a unit, request here and dont process command
	match command:
		0:
			return;
	process_command.rpc(command);
	pass;

@rpc("authority","call_local","reliable")
func process_command(command: int) ->void:
	print("processing command %s" % command)
	match command:
		0:
			pass; #build a dictionary for the unit to create and ask the game scene to add it
