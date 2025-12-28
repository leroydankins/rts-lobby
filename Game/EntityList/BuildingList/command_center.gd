extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var temp_team_label: Label = $TempTeamLabel

var team: int = 0;
var color: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_2d.input_event.connect(on_input);
	var text : String = GlobalConstants.TEAMS[team];
	temp_team_label.text = "Team: %s" % text;

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_input(_viewport: Node, event: InputEvent, _shape_idx :int) -> void:
	if event.is_action_pressed("select"):
		print(name + "was clicked");
		if (team == LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
			print("valid click!");
