extends StaticBody3D
const ENTITY_NAME: String = "Dwarf Barracks"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.BUILDING;
const BUILDING_TYPE: Array[int] = [];
const PREVIEW: Texture2D = preload(GlobalConstants.BUILDING_PLACEHOLDER_TEXTURE) #building_placeholder.png
@export var highlight_mesh: MeshInstance3D
@export var health_component: HealthComponent
@export var unit_maker_component: UnitMakerComponent
var game: GameScene;
var entity_holder: EntityHolder;
var player_data_manager: PlayerDataManager;

#export so that in test environment everything is ok
@export_category("Test Environment Variables")
@export var team: int = 0;
@export var color: int = 0;

#combat things
@export var is_alive: bool = true;


const CONSTRUCTION_COMPLETE: int = 10;
var construction_value: float = 0;
@export var is_constructed: bool = false;

#export for syncing
@export_category("Synced Properties")
@export var target_location: Vector3;
@export var target: Node3D;

#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
	1: {},
	2: {},
	3: {},
	4: {},
	5: {},
	6: {},
	7: {},
	8: {},
	9: {},
	10:{},
	11: GlobalConstants.CANCEL_ACTION_DICTIONARY,
}




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game");
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	player_data_manager = game.player_data_manager;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!multiplayer.is_server()):
		return;
	if(!is_constructed):
		if(construction_value >= CONSTRUCTION_COMPLETE):
			is_constructed = true;
		else:
			return;
	unit_maker_component.build(delta)


#This is the only real logic in the script
@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!multiplayer.is_server()):
		return
	if(!is_constructed):
		print("cannot accept commands, we arent fully fleshed yet! :)");
		return;
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	if(cmd_data.has("cost")):
		#All building commands that have a cost require building, easy check to not spend resources that will get rejected in command switch statement
		if(unit_maker_component.build_queue.size() >= unit_maker_component.BUILD_LIMIT):
			print("Full queue, rejecting command");
			return;
		var cost_arr: Array = cmd_data["cost"];
		var success: bool = player_data_manager.spend_resources(color,cost_arr);
		if (!success):
			return;
	var cmd: String = cmd_data["mnemonic"]
	match cmd:
		#Target unit
		"GC001":
			if (!cmd_data.has("target_node_path")):
				return;
			target = get_tree().root.get_node(cmd_data["target_node_path"])
			if (target == null || !is_instance_valid(target)):
				push_error("target did not exist");
				target = null;
				return;
			if("ENTITY_TYPE" not in target):
				print("just an object in the scene, not an ally or neutral, ignore it");
				return;
		#Cancel action
		"GC002":
			if(unit_maker_component.build_item != null):
				unit_maker_component.cancel_build();
			return;
		#Target location / Move to Location
		"GC003":
			if (!cmd_data.has("location")):
				return;
			target_location = cmd_data["location"];
			target = null;
		#cancel specific queued
		"GC004":
			if(!cmd_data.has("int")):
				return;
			unit_maker_component.cancel_queued(cmd_data["int"]);


#highlight
func set_selected() -> void:
	highlight_mesh.set_deferred("visible", true);
	health_component.show_health();

func unset_selected() -> void:
	highlight_mesh.set_deferred("visible", false);
	health_component.hide_health();



#combat will eventually be handled outside of main script?
func take_damage(damage_int: int, attacking_team: int) -> void:
	if(!multiplayer.is_server() || attacking_team == team):
		return;
	print(damage_int)
	#later we will play death animations!!
	var died: bool = health_component.take_damage(damage_int);
	if(died):
		is_alive = false;
		var entity_path: String = get_path();
		entity_holder.rpc("remove_entity", entity_path);
		#play death animation
		#anim.stop();


func heal(heal_int: int, healing_team: int) -> void:
	if(!multiplayer.is_server() || healing_team != team):
		return;
	health_component.heal(heal_int);
