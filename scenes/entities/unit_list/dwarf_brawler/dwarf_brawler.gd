extends CharacterBody3D
#ENTITY CONSTANTS
const ENTITY_NAME: String = "DwarfWorker"
const ENTITY_TYPE: GlobalConstants.EntityType = GlobalConstants.EntityType.UNIT;
const ENTITY_NUMBER: EntityConstants.Units = EntityConstants.Units.DWARF_WORKER;
const PREVIEW: Texture2D = preload(GlobalConstants.UNIT_PLACEHOLDER_TEXTURE);
const ENTITY_HEIGHT_OFFSET: float = .5;

#COMPONENTS
@export var highlight_mesh: MeshInstance3D
@export var unit_mesh: MeshInstance3D
@export var anim: AnimationPlayer
@export var navigation_agent: NavigationAgent3D
@export var health_component: HealthComponent
@export var interact_area: Area3D
@export var aggro_component: AggroComponent
@export var command_component: CommandComponent

const MOVE_SPEED: float = 4.0;
const GET_RESOURCE_COLLISION_MASK: int = 0b1001 # This is set with direct method call atm
const REGULAR_COLLISION_MASK: int = 0b1011; #OBE: Method Call set_collision_mask_value(3, true)
const UNIT_COLLISION_MASK: int = 3;

@export var team: int = 0;
@export var color: int = 0;

@export var is_alive: bool = true;
@export var damage: int = 8;

#LOCAL VARIABLE, DO NOT SYNC ACROSS PLAYERS
var is_selected: bool = false;
var interactable_array: Array = [];
#Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {	0: {},
	1: GlobalConstants.MOVE_TO_DICTIONARY,
	2: GlobalConstants.ATTACK_MOVE_DICTIONARY,
	3: {},
	4: {},
	5: {},
	6: {},
	7: {},
	8: {},
	9: {},
	10: {},
	11: GlobalConstants.CANCEL_ACTION_DICTIONARY,
	}

#extra game refernces,  bad and get rid of this later
var game: GameScene;
var entity_holder: EntityHolder;
var player_data_manager: PlayerDataManager;

func _ready() -> void:
	entity_holder = get_tree().get_first_node_in_group("EntityHolder");
	pass;

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

func set_selected() -> void:
	is_selected = true;
	highlight_mesh.set_deferred("visible", true);
	health_component.show_health();

func unset_selected() -> void:
	is_selected = false;
	highlight_mesh.set_deferred("visible", false);
	health_component.hide_health();


@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!is_multiplayer_authority()):
		return
	if !cmd_data.has("mnemonic"):
		push_error("command invalid");
		return;
	command_component.request_cmd(cmd_data);


#combat
#called by enemy unit or attack area?
func take_damage(damage_int: int, attacking_team: int) -> void:
	if(!is_multiplayer_authority() || attacking_team == team):
		return;
	#later we will play death animations!!
	var died: bool = health_component.take_damage(damage_int);
	if(died):
		is_alive = false;
		var entity_path: String = get_path();
		entity_holder.rpc("remove_entity", entity_path);
		#play death animation
		anim.stop();

func heal(heal_int: int, healing_node: Node3D) -> void:
	if(!is_multiplayer_authority() || healing_node.team != team):
		return;
	health_component.heal(heal_int);
