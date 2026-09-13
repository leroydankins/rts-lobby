extends Unit
#ENTITY CONSTANTS
#const ENTITY_NUMBER: EntityConstants.Units = EntityConstants.Units.DWARF_WORKER;
#const ENTITY_HEIGHT_OFFSET: float = .5;
#const MOVE_SPEED: float = 4.0;
#const UNIT_COLLISION_MASK: int = 3;


@export var damage: int = 8;

## Shows commands that the unit can take
var cmd_dict: Dictionary[int, Dictionary] = {
	0: {},
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

func _ready() -> void:
	pass;

# This should already be called by the authority? Not sure if it is an RPC
@rpc("any_peer","call_local","reliable")
func request_cmd(cmd_data: Dictionary) -> void:
	if(!is_multiplayer_authority()):
		return
	command_component.request_cmd(cmd_data);
	#all unit specific commands like special abilities may be in here but for the most part we just queue the command
	if(command_component.cmd_queue.size() == 1):
		command_component.start_cmd();

# combat
# called by enemy unit or attack area?
func take_damage(damage_int: int, attacking_team: int) -> void:
	if(!is_multiplayer_authority()):
		return;
	if(attacking_team == team):
		# Do we care if the attack came from an enemy or teammate?
		return
	#later we will play death animations!!
	var died: bool = health_component.take_damage(damage_int);
	if(died):
		var entity_path: String = get_path();
		get_tree().call_group("entity_holder","remove_entity", entity_path)
		# play death animation
		anim.stop();
		# Set up dying state

func heal(heal_int: int, healing_node: Entity) -> void:
	if(!is_multiplayer_authority()):
		return;
	# Do we care if they are not the right team here?
	if(healing_node.team != team):
		return;
	health_component.heal(heal_int);
