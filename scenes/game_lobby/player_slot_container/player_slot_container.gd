class_name PlayerSlotContainer
extends PanelContainer

signal add_cpu_pressed(slot: int);
signal race_updated(slot:int, race_int : int)
signal color_updated(slot:int, color_int: int)
signal team_updated(slot:int, team_int: int)
signal ready_toggled(slot:int, toggled: bool)


## This is used in signals to tell GameLobbyGUI which player slot updated information
@export var slot_num: int
var is_cpu: bool = false;
## Controlled via [GameLobbyGUI] in XX Function Call [br]
## Determines if the options are allowed to be edited [br]
## Each player can edit their own information [br]
## The host will be able to edit all CPU players [br]
var editable: bool = false;

@onready var player_label: Label = $MarginContainer/PlayerSlot/PlayerLabel
@onready var option_container: HBoxContainer = $MarginContainer/PlayerSlot/OptionContainer
@onready var race_option: OptionButton = $MarginContainer/PlayerSlot/OptionContainer/RaceOption
@onready var color_option: OptionButton = $MarginContainer/PlayerSlot/OptionContainer/ColorOption
@onready var color_display: ColorRect = $MarginContainer/PlayerSlot/OptionContainer/ColorDisplay
@onready var team_option: OptionButton = $MarginContainer/PlayerSlot/OptionContainer/TeamOption
@onready var ready_box: CheckBox = $MarginContainer/PlayerSlot/OptionContainer/ReadyBox
@onready var cpu_label: Label = $MarginContainer/PlayerSlot/OptionContainer/CPULabel
@onready var remove_button: Button = $MarginContainer/PlayerSlot/OptionContainer/RemoveButton
@onready var add_cpu_button: Button = $MarginContainer/PlayerSlot/AddCPUButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## takes in player dictionary of the following information
## username: String
## race: int
## color: int
## ready: bool
## is_cpu: bool
func update_player_data(player_dict: Dictionary) -> void:
	if (!player_dict):
		reset_player_data();
	else:
		add_cpu_button.hide();
		add_cpu_button.disabled = true;
		# Update displayed username
		player_label.text = player_dict[GlobalConstants.USERNAME_KEY];
		# Update ready display
		ready_box.set_pressed_no_signal(player_dict[GlobalConstants.READY_KEY]);
		# Update displayed Race
		race_option.selected = player_dict[GlobalConstants.RACE_KEY];
		# Update displayed Color
		color_option.selected = player_dict[GlobalConstants.COLOR_KEY];
		color_display.color = GlobalConstants.COLORS[player_dict[GlobalConstants.COLOR_KEY]];
		# Update displayed Team
		team_option.selected = player_dict[GlobalConstants.TEAM_KEY];
		#Mark if it is a CPU
		if (player_dict[GlobalConstants.IS_CPU_KEY]):
			cpu_label.show();
			if(editable):
				remove_button.disabled = false;
			else:
				remove_button.disabled = true;
		else:
			cpu_label.hide();
		if(editable): # Enable drop down options
			# FOR YOUR PLAYER DISABLE AVAILABLE COLORS IF IT IS ALREADY BEING USED
			var colors_in_use_arr: Array[Variant] = GlobalFunctions.get_player_property_array(Lobby.lobby_player_dictionary, GlobalConstants.COLOR_KEY) 
			for i: int in GlobalConstants.COLORS.size():
				#if someone is currently using the color, disable the button
				if colors_in_use_arr.has(i):
					color_option.set_item_disabled(i, true)
				else:
					color_option.set_item_disabled(i, false);
			race_option.disabled = false;
			color_option.disabled = false;
			team_option.disabled = false;
			if(!player_dict[GlobalConstants.IS_CPU_KEY]):
				ready_box.disabled = true;
				remove_button.disabled = true;
			else:
				remove_button.disabled = false;
				ready_box.disabled = false;


func enable_edit() ->void:
	editable = true;

func disable_edit() ->void:
	editable = false;

func reset_player_data() ->void:
	player_label.text = "empty";
	# Hide intermediary Buttons/Displays via option_container
	option_container.hide();

	add_cpu_button.show();
	add_cpu_button.disabled = false;
