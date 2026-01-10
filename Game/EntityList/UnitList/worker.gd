extends Area2D

var team: int = 0;
var color: int = 0;

var health: float = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
