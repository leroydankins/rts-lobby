extends Control

@onready var command_container: GridContainer = $Control/CommandMarginContainer/CommandContainer

@onready var unit_container: HFlowContainer = $Control/UnitHBox/MarginContainer/UnitContainer
@onready var object_being_built_control: HBoxContainer = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl
@onready var unit_label: Label = $Control/UnitHBox/SelectedUnitBox/HBoxContainer/UnitLabel
@onready var unit_preview: TextureRect = $Control/UnitHBox/SelectedUnitBox/HBoxContainer/UnitPreview


@onready var obb_label: Label = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBLabel
@onready var obb_preview_sprite: TextureRect = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBPreviewSprite
@onready var obb_progress_bar: ProgressBar = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBProgressBar
@onready var build_queue_container: HBoxContainer = $Control/UnitHBox/MarginContainer/BuildQueueContainer


var cmd_box_arr: Array = [];
var command_controller: CommandController;
var first_selected: Node3D;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#initialize variables
	var _null_var: int;
	cmd_box_arr = command_container.get_children();
	command_controller = get_tree().get_first_node_in_group("CommandController");

	#Connect to signals
	_null_var = command_controller.selected_signal.connect(on_selected_signal);
	_null_var = command_controller.deselected_signal.connect(on_deselected_signal);
	for gui: CmdGUI in cmd_box_arr:
		_null_var = gui.command_pressed.connect(on_cmd_gui_pressed);
	for queue_gui: Control in build_queue_container.get_children():
		queue_gui.queue_pressed.connect(on_queue_pressed);
	#hide UI
	unit_container.hide();
	object_being_built_control.hide();
	build_queue_container.hide();

#See on_selected_signal for how cmd_gui's have command dictionary data
#Command dictionary gets delivered to this function when cmd_gui is pressed
func on_cmd_gui_pressed(p_cmd: Dictionary)->void:
	#Universal function for handling commands before RPC to server in command_controller
	command_controller.handle_cmd(p_cmd)

func on_queue_pressed(queue_slot: int) -> void:
	first_selected = command_controller.selected[0];
	if("build_queue" in first_selected):
		first_selected.cancel_queued.rpc(queue_slot);
		#unqueue that object

func on_deselected_signal() ->void:
	unit_label.text = "";
	unit_container.hide();
	unit_preview.texture = null;
	build_queue_container.hide();
	object_being_built_control.hide();
	#Update image and data for each cmd box here
	for cmd: CmdGUI in cmd_box_arr:
		cmd.clear_data();

func on_selected_signal(unit: Node3D) ->void:
	if(unit == null):
		unit_label.text = "";
		unit_container.hide();
		unit_preview.texture = null;
		build_queue_container.hide();
		object_being_built_control.hide();
		#Update image and data for each cmd box here
		for i: int in cmd_box_arr.size():
			cmd_box_arr[i].clear_data();
		return;
	if(!"ENTITY_NAME" in unit):
		push_error("No object name, crash this game and fix it ethab")
		return;
	if(unit.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
		unit_label.text = unit.ENTITY_NAME;
		unit_preview.texture = unit.PREVIEW;
		unit_container.hide();
		object_being_built_control.hide();
		build_queue_container.hide();
		for cmd: CmdGUI in cmd_box_arr:
			cmd.clear_data();
		return;
	#change the UI if this is not an ally/team unit
	if(unit.team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
		unit_label.text = str(unit.ENTITY_NAME, "Enemy");
		unit_container.hide();
		object_being_built_control.hide();
		for cmd: CmdGUI in cmd_box_arr:
			cmd.clear_data();
		return;
	unit_label.text = unit.ENTITY_NAME;
	unit_preview.texture = unit.PREVIEW;
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
				cmd_box_arr[i].update_data(unit.cmd_dict[i])

	if (command_controller.selected.size() > 1):
		unit_container.show();

	else:
		unit_container.hide();

	#if the unit has a build item property, aka its building something
	if ("build_item" in unit && !unit.build_item.is_empty()):
		object_being_built_control.show();
		obb_progress_bar.max_value = unit.build_time;
		obb_progress_bar.value = unit.build_progress;
		obb_label.text = unit.build_item.name;
		var slots: Array = build_queue_container.get_children();
		build_queue_container.show();
		for i: int in slots.size():
			if(i < unit.build_queue.size()):
				slots[i].show();
				var text: Texture2D = load(unit.build_queue[i]["sprite_path"])
				slots[i].update_data(text);
				#set button
			else:
				slots[i].hide();
			pass;

	else:
		object_being_built_control.hide();
		unit_container.show();
		build_queue_container.hide();
		var units: Array = unit_container.get_children()
		for i: int in units.size():
			if i < command_controller.selected.size():
				units[i].show();
			else:
				units[i].hide();



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (command_controller.selected.is_empty()):
		return;
	first_selected = command_controller.selected[0]

	if (first_selected == null):
		push_error("selected array is not empty, but first slot in array is null?")
		unit_container.visible = false;
		object_being_built_control.visible = false;
		return;
	if("team" not in first_selected):
		#this is just an object in the map
		return;
	if(command_controller.selected.size() > 1):
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
		if(first_selected.build_queue.size() > 0):
			build_queue_container.show();
			var slots: Array = build_queue_container.get_children();
			for i: int in slots.size():
				if(i < first_selected.build_queue.size()):
					slots[i].show();
					var text: Texture2D = load(first_selected.build_queue[i]["sprite_path"])
					slots[i].update_data(text);
					#set button
				else:
					slots[i].hide();
			pass;
		else:
			build_queue_container.hide();
	else:
		object_being_built_control.visible = false;
