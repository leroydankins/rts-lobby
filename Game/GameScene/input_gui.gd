extends Control
@onready var unit_label: Label = $Control/SelectedUnitBox/HBoxContainer/UnitLabel
@onready var command_container: GridContainer = $Control/CommandMarginContainer/CommandContainer
@onready var unit_container: HFlowContainer = $Control/MarginContainer/UnitContainer
@onready var object_being_built_control: HBoxContainer = $Control/MarginContainer/ObjectBeingBuiltControl

@onready var obb_label: Label = $Control/MarginContainer/ObjectBeingBuiltControl/OBBLabel
@onready var obb_preview_sprite: TextureRect = $Control/MarginContainer/ObjectBeingBuiltControl/OBBPreviewSprite
@onready var obb_progress_bar: ProgressBar = $Control/MarginContainer/ObjectBeingBuiltControl/OBBProgressBar


var cmd_box_arr: Array = [];
var input_controller: InputController;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_controller = get_tree().get_first_node_in_group("InputController");
	input_controller.selected_signal.connect(on_selected_signal);
	cmd_box_arr = command_container.get_children();
	unit_container.hide();
	object_being_built_control.hide();
	#for i: int in command_container.get_children().size():
		#cmd_box_arr[i] = command_container.get_children()[i];
	pass # Replace with function body.


func on_selected_signal(unit: Node2D) ->void:
	if(unit == null):
		unit_label.text = "";
		unit_container.hide();
		object_being_built_control.hide();
		for i: int in cmd_box_arr.size():
			cmd_box_arr[i].text = ""
		return;
	unit_label.text = unit.name;
	assert("cmd_dict" in unit);
	for key: int in unit.cmd_dict:
		cmd_box_arr[key].text = str(key);
		print(key);
	if (input_controller.selected.size() > 1):
		unit_container.show();
	else:
		unit_container.hide();
	#if the unit has a build item property, aka its building something
	if ("build_item" in unit):
		object_being_built_control.show()
		if (!unit.build_item.is_empty()):
			object_being_built_control.show();
			obb_progress_bar.max_value = unit.build_time;
			obb_progress_bar.value = unit.build_progress;
			obb_label.text = unit.build_item.name;
			unit_container.hide();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
