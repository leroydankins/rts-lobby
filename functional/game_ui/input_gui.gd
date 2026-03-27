extends Control

@onready var command_container: GridContainer = $Control/CommandMarginContainer/CommandContainer

@onready var unit_container: HFlowContainer = $Control/UnitHBox/MarginContainer/UnitContainer
@onready var object_being_built_control: HBoxContainer = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl
@onready var unit_label: Label = $Control/UnitHBox/SelectedUnitBox/HBoxContainer/UnitLabel
@onready var unit_preview: TextureRect = $Control/UnitHBox/SelectedUnitBox/HBoxContainer/UnitPreview


@onready var obb_label: Label = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/OBBLabel
@onready var build_slot: BuildSlot = $Control/UnitHBox/MarginContainer/ObjectBeingBuiltControl/BuildSlot
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
	build_slot.queue_pressed.connect(on_first_queue_pressed);

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

func on_first_queue_pressed(_slot: int) -> void:
	var cancel_cmd: Dictionary = GlobalConstants.CANCEL_ACTION_DICTIONARY.duplicate();
	command_controller.handle_cmd(cancel_cmd);

func on_queue_pressed(queue_slot: int) -> void:
	var cancel_cmd: Dictionary = GlobalConstants.CANCEL_QUEUED_DICTIONARY.duplicate();
	cancel_cmd["int"] = queue_slot;
	command_controller.handle_cmd(cancel_cmd);
	#unqueue that object

func on_deselected_signal() ->void:
	build_slot.remove_data();
	unit_label.text = "";
	unit_container.hide();
	unit_preview.texture = null;
	build_queue_container.hide();
	object_being_built_control.hide();
	#Update image and data for each cmd box here
	for cmd: CmdGUI in cmd_box_arr:
		cmd.clear_data();
	for slot: BuildSlot in build_queue_container.get_children():
		slot.remove_data();

func on_selected_signal(entity: Node3D) ->void:
	if(entity == null):
		unit_label.text = "";
		unit_container.hide();
		unit_preview.texture = null;
		build_queue_container.hide();
		object_being_built_control.hide();
		#Update image and data for each cmd box here
		for i: int in cmd_box_arr.size():
			cmd_box_arr[i].clear_data();
		return;
	if(!"ENTITY_NAME" in entity):
		push_error("No object name, crash this game and fix it ethab")
		return;
	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.RESOURCE):
		unit_label.text = entity.ENTITY_NAME;
		unit_preview.texture = entity.PREVIEW;
		unit_container.hide();
		object_being_built_control.hide();
		build_queue_container.hide();
		for cmd: CmdGUI in cmd_box_arr:
			cmd.clear_data();
		return;
	#change the UI if this is not an ally/team unit
	if(entity.team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
		unit_label.text = str(entity.ENTITY_NAME, "Enemy");
		unit_container.hide();
		object_being_built_control.hide();
		for cmd: CmdGUI in cmd_box_arr:
			cmd.clear_data();
		return;
	unit_label.text = entity.ENTITY_NAME;
	unit_preview.texture = entity.PREVIEW;
	assert("cmd_dict" in entity);

	if ("current_state" in entity && entity.current_state == GlobalConstants.BuildingState.UNCONSTRUCTED):
		for i: int in cmd_box_arr.size():
			cmd_box_arr[i].clear_data();

	else:
		for i: int in cmd_box_arr.size():
			if (!entity.cmd_dict.has(i) || entity.cmd_dict[i].is_empty()):
				#if there is not a command in this box, dont do anything and hide the data in there currently
				cmd_box_arr[i].clear_data();
			else:
				cmd_box_arr[i].update_data(entity.cmd_dict[i])

	if (command_controller.selected.size() > 1):
		unit_container.show();
	else:
		unit_container.hide();

	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
		if(!entity.is_constructed):
			object_being_built_control.show();
			obb_progress_bar.max_value = 100; #to base it on 100% complete stats
			obb_progress_bar.value = entity.construction_value / entity.CONSTRUCTION_COMPLETE;
			obb_label.text = entity.ENTITY_NAME;
			build_queue_container.hide();
		elif(!entity.unit_maker_component.build_item.is_empty()):
			object_being_built_control.show();
			if(!build_slot.has_texture()):
				var text: Texture2D = load(entity.unit_maker_component.build_item["sprite_path"]);
				build_slot.update_data(text)
			obb_progress_bar.max_value = entity.unit_maker_component.build_time;
			obb_progress_bar.value = entity.unit_maker_component.build_progress;
			obb_label.text = entity.unit_maker_component.build_item.name;
			var slots: Array = build_queue_container.get_children();
			build_queue_container.show();
			var slot: BuildSlot;
			for i: int in slots.size():
				slot = slots[i];
				if(i < entity.unit_maker_component.build_queue.size()):
					slot.show();
					var text: Texture2D = load(entity.unit_maker_component.build_queue[i]["sprite_path"])
					slot.update_data(text);
					#set button
				else:
					slot.hide();
		else:
			build_slot.remove_data();
			object_being_built_control.hide();
			unit_container.show();
			build_queue_container.hide();
			var units: Array = unit_container.get_children()
			for i: int in units.size():
				if i < command_controller.selected.size():
					units[i].show();
				else:
					units[i].hide();
	elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
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
	var entity: Node3D = command_controller.selected[0]

	if (entity == null):
		push_error("selected array is not empty, but first slot in array is null?")
		unit_container.visible = false;
		object_being_built_control.visible = false;
		return;
	if("team" not in entity):
		#this is just an object in the map
		return;
	if(command_controller.selected.size() > 1):
		unit_container.show();
	else:
		unit_container.hide();
	if (entity.team != LocalPlayerData.local_player[GlobalConstants.TEAM_KEY]):
		return;

	if(entity.ENTITY_TYPE == GlobalConstants.EntityType.BUILDING):
		if(!entity.is_constructed):
			object_being_built_control.show();
			obb_progress_bar.max_value = 100; #to base it on 100% complete stats
			obb_progress_bar.value = (entity.construction_value / entity.CONSTRUCTION_COMPLETE) * 100;
			obb_label.text = entity.ENTITY_NAME;
			build_queue_container.hide();
		elif(!entity.unit_maker_component.build_item.is_empty()):
			object_being_built_control.show();
			if(!build_slot.has_texture()):
				var text: Texture2D = load(entity.unit_maker_component.build_item["sprite_path"]);
				build_slot.update_data(text)
			obb_progress_bar.max_value = entity.unit_maker_component.build_time;
			obb_progress_bar.value = entity.unit_maker_component.build_progress;
			obb_label.text = entity.unit_maker_component.build_item.name;
			var slots: Array = build_queue_container.get_children();
			build_queue_container.show();
			for i: int in slots.size():
				if(i < entity.unit_maker_component.build_queue.size()):
					slots[i].show();
					if(!slots[i].has_texture()):
						var text: Texture2D = load(entity.unit_maker_component.build_queue[i]["sprite_path"])
						slots[i].update_data(text);
					#set button
				else:
					slots[i].remove_data();
					slots[i].hide();
		else:
			build_slot.remove_data();
			object_being_built_control.hide();
			unit_container.show();
			build_queue_container.hide();
			var units: Array = unit_container.get_children()
			for i: int in units.size():
				if i < command_controller.selected.size():
					units[i].show();
				else:
					units[i].hide();
	elif(entity.ENTITY_TYPE == GlobalConstants.EntityType.UNIT):
		object_being_built_control.hide();
		unit_container.show();
		build_queue_container.hide();
		var units: Array = unit_container.get_children()
		for i: int in units.size():
			if i < command_controller.selected.size():
				units[i].show();
			else:
				units[i].hide();
