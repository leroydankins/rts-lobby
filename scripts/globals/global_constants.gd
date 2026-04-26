class_name GlobalConstants

#Brother we should not have 1 2 3 4 be the team numbers but whatever
const TEAMS: Dictionary[int, String] = {0 : "1", 1: "2", 2: "3", 3: "4", 99: "neutral"}
const COLORS: Dictionary[int, Color] = {0 : Color.NAVY_BLUE, 1: Color.DARK_RED, 2: Color.DARK_GREEN, 3: Color.REBECCA_PURPLE}
const RACES: Dictionary[int, String] = {0 : "dwarves"}
#LOBBY DICTIONARY KEYS
const USERNAME_KEY: String = "username";
const READY_KEY: String = "ready";
const TEAM_KEY: String = "team";
const COLOR_KEY: String = "color";
const RACE_KEY: String = "race";

const KEY_ARRAY: Array[String] = [USERNAME_KEY,READY_KEY,TEAM_KEY,COLOR_KEY,RACE_KEY];
#GAME PATHS
const GAME: PackedScene = preload("uid://1vvyuea6fq3v") #game_scene/game.tscn
const _DEPRECATED_GAME_PATH: String = "uid://1vvyuea6fq3v"; #game_scene/game.tscn
const GAME_PATH: String = "uid://dcrsb32jubfy7"; #3D GAME SCENE PLACEHOLDER

#ENTITY FILEPATHS
const COMMAND_CENTER_FILEPATH: String = "uid://clusn5oxit4qc" #building_list/command_center/command_center.tscn
const WORKER_FILEPATH: String = "uid://dm6nkl2orudho" #unit_list/worker.tscn
const FORGE_FILEPATH: String = "uid://clyx8tbh0jeq3" #building_list/forge/forge.tscn
const DWARF_SETTLEMENT_FILEPATH: String = "uid://bif7vwlmrd4j0" #building_list/dwarf_settlement.tscn
const DWARF_WORKER_FILEPATH: String = "uid://bk5soe7dxxfcm" #unit_list/dwarf_worker/
const DWARF_BLUNDERBUSS_FILEPATH: String = "";
const DWARF_BARRACKS_FILEPATH: String = "uid://sa4f355jrmcj"; #building_list/dwarf_barracks
const DWARF_BRAWLER_FILEPATH: String = "uid://b5v73hrqfe7wf" #unit_list/dwarf_brawler

#IMAGE FILEPATHS
const BUILDING_PLACEHOLDER_TEXTURE: String = "uid://drsrhq5glvf4f" #building_placeholder.png
const UNIT_PLACEHOLDER_TEXTURE: String = "uid://xdy8auqusfq" #unit_placeholder.png
const MINERAL_PLACEHOLDER_TEXTURE: String = "uid://hkqpxnf6hhsj" #minerals.png
const ATTACK_PLACEHOLDER_TEXTURE: String = "uid://cq7inrylelcos"
const MOVE_TO_PLACEHOLDER_TEXTURE: String = "uid://cvuy57vyaik8l"
const UPGRADE_PLACEHOLDER_TEXTURE: String = "uid://cokfc1ue0hkgq"
const CANCEL_PLACEHOLDER_TEXTURE: String = "uid://cvmj363eynq28"



###ENUMS
#ENTIY_TYPE
enum EntityType {
	UNIT,
	BUILDING,
	RESOURCE
}
#BUILDING TYPE ENUM
enum BuildingType
{
	CENTER,
	RESOURCE_DEPOT,
}
#RESOURCE TYPE
enum ResourceType{
	MINERAL,
	GAS
}
#BUILDING STATE ENUM
enum BuildingState{
	IDLE,
	ACTIVE,
	UNCONSTRUCTED,
}
enum Commands
{
	CANCEL,
	MOVE,
	HOLD,
	TARGET,
	ATTACK,
	FOLLOW,
	GET_RESOURCE,
	BUILD,
	TRAIN, #Used by buildings to train units or research
	ATTACK_MOVE,
	RETURN_RESOURCE,
	GO_TO,
}
##TODO
enum Dwarf_Research
{

}
##TODO
enum Rancorian_Research
{

}
enum Upgrades
{
	ARMOR_1,
	ARMOR_2,
	WEAPON_1,
	WEAPON_2,
}
### END ENUMS

#command dictionaries in GlobalConstants otherwise it will be empty
###COMMAND DICTIONARIES
const TARGET_UNIT_DICTIONARY : Dictionary[String, Variant] = {
	#Required command data
	"mnemonic" : "GC001",
	"command" : Commands.TARGET,
	"hotkey" : "T",
	"is_group" : true,
	"can_queue" : true,

	#command specific data
	"argument" : "target_node_path",

	#command metadata
	"name" : "Target Unit",
	"description" : "Targets object",
	"sprite_path" : "",
}
const CANCEL_ACTION_DICTIONARY: Dictionary[String, Variant] = {
	#Required command data
	"mnemonic" : "GC002",
	"command" : Commands.CANCEL,
	"hotkey" : "X",
	"is_group" : true,
	"can_queue" : false,

	#command specific data

	#Command Metadata
	"name" : "Cancel",
	"description" : "Cancels the current action",
	"sprite_path" : CANCEL_PLACEHOLDER_TEXTURE, #cancel_placeholder.png
}

const MOVE_TO_DICTIONARY: Dictionary[String, Variant] = {
	#Required command data
	"mnemonic" : "GC003",
	"command" : Commands.MOVE,
	"hotkey" : "M",
	"is_group" : true,
	"can_queue" : true,

	#Command specific data
	"argument" : "location",

	#command metadata
	"name" : "Move To",
	"description" : "Targets location",
	"sprite_path" : MOVE_TO_PLACEHOLDER_TEXTURE,
}
const CANCEL_QUEUED_DICTIONARY: Dictionary [String, Variant] = {
	#Required command data
	"mnemonic" : "GC004",
	"command" : Commands.CANCEL,
	"hotkey" : "X",
	"is_group" : false,
	"can_queue" : false,

	#command specific data
	"int": 0,

	#Command Metadata
	"name" : "Cancel",
	"description" : "Cancels building specific unit", #only called from clicking on queue icon in UI
	"sprite_path" : CANCEL_PLACEHOLDER_TEXTURE, #cancel_placeholder.png
}
#I dont think we ever use this directly, but attack move can be converted to this if it targets a unit
const ATTACK_TARGET_DICTIONARY: Dictionary [String, Variant] = {
	#Required command data
	"mnemonic" : "GC005",
	"command" : Commands.ATTACK,
	"hotkey" : "X",
	"is_group" : true,
	"can_queue" : true,

	#command specific data
	"argument" : "target_node_path",

	#Command Metadata
	"name" : "Attack",
	"description" : "Direct selected units to attack a specific target",
	"sprite_path" : ATTACK_PLACEHOLDER_TEXTURE
}
const ATTACK_MOVE_DICTIONARY: Dictionary [String, Variant] = {
	#Required command data
	"mnemonic" : "GC006",
	"command" : Commands.ATTACK_MOVE,
	"hotkey" : "A",
	"is_group" : true,
	"can_queue" : true,

	#command specific data
	"argument" : "location",

	#Command Metadata
	"name" : "Attack Move",
	"description" : "Move to location, attacking anything it sees",
	"sprite_path" : ATTACK_PLACEHOLDER_TEXTURE
}
const TRAIN_DWARF_WORKER_DICTIONARY: Dictionary[String, Variant] = {
	#Required command data
	"mnemonic" : "DS001",
	"command" : Commands.TRAIN,
	"hotkey" : "E",
	"is_group" : false,
	"can_queue" : false,

	#command specific data
	"cost" : [50,0],
	"file_path" : DWARF_WORKER_FILEPATH,
	"build_time" : 5,

	#Command Metadata
	"name" : "Worker",
	"description" : "Builds a dwarf worker",
	"sprite_path" : "uid://xdy8auqusfq", #unit_placeholder.png
}
const TRAIN_DWARF_BRAWLER_DICTIONARY: Dictionary[String, Variant] = {
	#Required command data
	"mnemonic" : "DB001",
	"command" : Commands.TRAIN,
	"hotkey" : "K",
	"is_group" : false,
	"can_queue" : false,

	#command specific data
	"cost" : [75,0],
	"file_path" : DWARF_BRAWLER_FILEPATH,
	"build_time" : 12,

	#Command Metadata
	"name" : "Brawler",
	"description" : "Builds a dwarf brawler",
	"sprite_path" : "uid://xdy8auqusfq", #unit_placeholder.png
}

const BUILD_DWARF_SETTLEMENT_DICTIONARY  : Dictionary = {
	#required command data
	"mnemonic" : "DW001",
	"command" : Commands.BUILD,
	"hotkey" : "E",
	"is_group" : false,
	"can_queue" : true,

	#command specific data
	"cost" : [400,0],
	"building_array": [BuildingType.CENTER, BuildingType.RESOURCE_DEPOT],
	"argument" : "location",
	"file_path" : DWARF_SETTLEMENT_FILEPATH,


	#command metadata
	"name" : "Build Base",
	"description" : "Builds Dwarven Settlement",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}

const BUILD_DWARF_BARRACKS_DICTIONARY: Dictionary = {
	#required command data
	"mnemonic" : "DW003",
	"command" : Commands.BUILD,
	"hotkey" : "B",
	"is_group" : false,
	"can_queue" : true,

	#command specific data
	"cost" : [150,0],
	"building_array": [], #Check against buildingType enum for bool checks on buiilding-grid
	"argument" : "location",
	"file_path" : DWARF_BARRACKS_FILEPATH,

	#command metadata
	"name" : "Dwarf Barracks",
	"description" : "Build dwarven barracks, can create warriors",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}
const BUILD_DWARF_BARRACKS2_DICTIONARY: Dictionary = {
	#required command data
	"mnemonic" : "DW003",
	"command" : Commands.BUILD,
	"hotkey" : "B",
	"is_group" : false,
	"can_queue" : true,

	#command specific data
	"cost" : [150,0],
	"argument" : "grid_location",
	"file_path" : DWARF_BARRACKS_FILEPATH,
	"entity_preview" : "uid://bsqyhy830548j",

	#command metadata
	"name" : "Dwarf Barracks",
	"description" : "Build dwarven barracks, can create warriors",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}
##INCOMPLETE
const BUILD_FORGE_DICTIONARY : Dictionary = {
	#Required command data
	"mnemonic" : "DW002",
	"command" : Commands.BUILD,
	"hotkey" : "F",
	"is_group" : false,
	"can_queue" : true,

	#command specific data
	"cost" : [200,0],
	"argument" : "location",
	"file_path" : FORGE_FILEPATH,

	#command metadata
	"name" : "Forge",
	"description" : "Build dwarven forge for weapon research",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}
const RESEARCH_DWARF_BLUNDERBUSS_DICTIONARY : Dictionary = {
	#Required command data
	"mnemonic" : "F003",
	"command" : Commands.TRAIN,
	"hotkey" : "B",
	"is_group" : false,
	"can_queue" : false,

	#command specific data
	"cost" : [350,200],
	"file_path" : DWARF_BLUNDERBUSS_FILEPATH,

	#command metadata
	"name" : "Research Blunderbusses",
	"description" : "Researches Armor Upgrade Level 1",
	"sprite_path" : "uid://cokfc1ue0hkgq" #upgrade_placeholder.png
}
const UPGRADE_ARMOR_1_DICTIONARY : Dictionary = {
	#Required Command Data
	"mnemonic" : "F003",
	"command" : Commands.TRAIN,
	"hotkey" : "G",
	"is_group" : false,
	"can_queue" : false,

	#Command specific data
	"cost" : [350,200],
	"research" : Upgrades.ARMOR_1,

	#command metadata
	"name" : "Upgrade Armor Level 1",
	"description" : "Researches Armor Upgrade Level 1",
	"sprite_path" : "uid://cokfc1ue0hkgq" #upgrade_placeholder.png
}
const UPGRADE_ARMOR_2_DICTIONARY : Dictionary = {
	#Required Command Data
	"mnemonic" : "F004",
	"command" : Commands.TRAIN,
	"hotkey" : "G",
	"is_group" : false,
	"can_queue" : false,

	#Command specific data
	"cost" : [350,200],
	"upgrade" : Upgrades.ARMOR_2,
	#command metadata
	"name" : "Upgrade Armor Level 2",
	"description" : "Researches Armor Upgrade Level 2",
	"sprite_path" : "uid://cokfc1ue0hkgq" #upgrade_placeholder.png
}

###DEPRECATED
const BUILD_BASE_DICTIONARY  : Dictionary = {
	"name" : "Build Base",
	"mnemonic" : "WK001",
	"command" : Commands.BUILD,
	"cost" : [300,0],
	"description" : "Builds Dwarven Base",
	"file_path" : COMMAND_CENTER_FILEPATH,
	"argument" : "location",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}
##DEPRECATED
const BUILD_WORKER_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Worker",
	"mnemonic" : "CC001",
	"command" : Commands.BUILD,
	"cost" : [50,0],
	"description" : "Builds a dwarf worker",
	"file_path" : WORKER_FILEPATH,
	"build_time" : 5,
	"sprite_path" : "uid://xdy8auqusfq", #unit_placeholder.png
	"hotkey" : "E",
}
