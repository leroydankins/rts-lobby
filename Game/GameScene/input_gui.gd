extends Control

@onready var command_container: GridContainer = $Control/CommandMarginContainer/CommandContainer

@onready var unit_container: HFlowContainer = $Control/UnitHBox/MarginContainer/UnitContainer
@onready var object_being_built_control: HBoxContainer = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl
@onready var unit_label: Label = $Control/UnitHBox/SelectedUnitBox/HBoxContainer/UnitLabel
@onready var obb_label: Label = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBLabel
@onready var obb_preview_sprite: TextureRect = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBPreviewSprite
@onready var obb_progress_bar: ProgressBar = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBProgressBar


var cmd_box_arr: Array = [];
var input_controller: InputController;
var first_selected: Node2D;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#initialize variables
	var _null_var: int;
	cmd_box_arr = command_container.get_children();
	input_controller = get_tree().get_first_node_in_group("InputController");

	#Connect to signals
	_null_var = input_controller.selected_signal.connect(on_selected_signal);
	for gui: CmdGUI in cmd_box_arr:
		_null_var = gui.command_pressed.connect(on_cmd_gui_pressed);

	#hide UI
	unit_container.hide();
	object_being_built_control.hide();

#See on_selected_signal for how cmd_gui's have command dictionary data
#Command dictionary gets delivered to this function when cmd_gui is pressed
func on_cmd_gui_pressed(p_cmd: Dictionary)->void:
	#Universal function for handling commands before RPC to server in input_controller
	input_controller.handle_cmd(p_cmd)

func on_selected_signal(unit: Node2D) ->void:
	if(unit == null):
		unit_label.text = "";
		unit_container.hide();
		object_being_built_control.hide();
		#Update image and data for each cmd box here
		for i: int in cmd_box_arr.size():
			cmd_box_arr[i].clear_data();
		return;
	if(!"OBJECT_NAME" in unit):
		push_error("No object name, crash this game and fix it ethab")
		return;
	if(unit.team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
		unit_label.text = str(unit.OBJECT_NAME, "Enemy");
		unit_container.hide();
		object_being_built_control.hide();
		for cmd: CmdGUI in cmd_box_arr:
			cmd.clear_data();
		return;
	unit_label.text = unit.OBJECT_NAME;
	assert("cmd_dict" in unit);

	if ("current_state" in unit && unit.current_state == GlobalConstants.BuildingState.UNCONSTRUCTED):
		for i: int in cmd_box_arr.size():
			cmd_box_arr[i].clear_data();

	else:
		for i: int in cmd_box_arr.size():
			if (!unit.cmd_dict.has(i) || unit.cmd_dict[i].is_empty()):
				#if there is not a command in this box, dont do anything and hide the data in there currently
				cmd_box_arr[i].clear_data();
			else:
				print(i);
				cmd_box_arr[i].update_data(unit.cmd_dict[i])

	if (input_controller.selected.size() > 1):
		unit_container.show();

	else:
		unit_container.hide();

	#if the unit has a build item property, aka its building something
	if ("build_item" in unit && !unit.build_item.is_empty()):
		object_being_built_control.show();

		obb_progress_bar.max_value = unit.build_time;

		obb_progress_bar.value = unit.build_progress;

		obb_label.text = unit.build_item.name;

	else:
		object_being_built_control.hide();
		unit_container.show();
		var units: Array = unit_container.get_children()
		for i: int in units.size():
			if i < input_controller.selected.size():
				units[i].show();
			else:
				units[i].hide();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (input_controller.selected.is_empty()):
		return;
	first_selected = input_controller.selected[0]

	if (first_selected == null):
		push_error("selected array is not empty, but first slot in array is null?")
		unit_container.visible = false;
		object_being_built_control.visible = false;
		return;
	if(input_controller.selected.size() > 1):
		unit_container.show();
	else:
		unit_container.hide();
	if (first_selected.team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
		return;
	if ("build_item" in first_selected && !first_selected.build_item.is_empty()):
		object_being_built_control.show();
		obb_progress_bar.max_value = first_selected.build_time;
		obb_progress_bar.value = first_selected.build_progress;
		obb_label.text = first_selected.build_item.name;
	else:
		object_being_built_control.visible = false;
