class_name GlobalConstants
extends Node

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
#IMAGE FILEPATHS
const BUILDING_PLACEHOLDER_TEXTURE: String = "uid://drsrhq5glvf4f" #building_placeholder.png
const UNIT_PLACEHOLDER_TEXTURE: String = "uid://xdy8auqusfq" #unit_placeholder.png
const MINERAL_PLACEHOLDER_TEXTURE: String = "uid://hkqpxnf6hhsj" #ninerals.png


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
	MINE,
	BUILD,
}
enum Dwarf_Research
{

}
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

#Each playe

###COMMAND DICTIONARIES
const TARGET_UNIT_DICTIONARY : Dictionary[String, Variant] = {
	"name" : "Target Unit",
	"mnemonic" : "GC001",
	"command" : Commands.TARGET,
	"argument" : "target_node_path",
	"description" : "Targets object",
	"file_path" : "",
	"build_time" : 0,
	"sprite_path" : ""
}
const CANCEL_ACTION_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Cancel",
	"mnemonic" : "GC002",
	"command" : Commands.CANCEL,
	"is_unit" : false,
	"description" : "Cancels the current action, buildings stop building current unit",
	"file_path" : "",
	"build_time" : 0,
	"sprite_path" : "uid://cvmj363eynq28", #cancel_placeholder.png
	"hotkey" : Key.KEY_BACKSPACE,
}
const MOVE_TO_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Move To Location",
	"mnemonic" : "GC003",
	"command" : Commands.MOVE,
	"argument" : "location",
	"description" : "Targets location",
	"sprite_path" : ""
}
const BUILD_WORKER_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Worker",
	"mnemonic" : "CC001",
	"command" : Commands.BUILD,
	"cost" : [50,0],
	"description" : "Builds a dwarf worker",
	"file_path" : WORKER_FILEPATH,
	"build_time" : 5,
	"sprite_path" : "uid://xdy8auqusfq", #unit_placeholder.png
	"hotkey" : Key.KEY_E,
}
const BUILD_DWARF_WORKER_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Worker",
	"mnemonic" : "CC001",
	"command" : Commands.BUILD,
	"cost" : [50,0],
	"description" : "Builds a dwarf worker",
	"file_path" : DWARF_WORKER_FILEPATH,
	"build_time" : 5,
	"sprite_path" : "uid://xdy8auqusfq", #unit_placeholder.png
	"hotkey" : Key.KEY_E,
}
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
const BUILD_DWARF_SETTLEMENT_DICTIONARY  : Dictionary = {
	"name" : "Build Base",
	"mnemonic" : "WK001",
	"command" : Commands.BUILD,
	"cost" : [300,0],
	"description" : "Builds Dwarven Settlement",
	"file_path" : DWARF_SETTLEMENT_FILEPATH,
	"argument" : "location",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}

#command dictionaries need to be initialized before cmd_dict or in GlobalConstants otherwise it will be empty
const BUILD_BREWERY: Dictionary = {
	"name" : "Build Brewery",
	"mnemonic" : "WK003",
	"command" : Commands.BUILD,
	"cost" : [150,100],
	"description" : "Builds Dwarven Base",
	"file_path" : null,
	"argument" : "location",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}
const BUILD_FORGE_DICTIONARY : Dictionary = {
	"name" : "Build Forge",
	"mnemonic" : "WK002",
	"command" : Commands.BUILD,
	"cost" : [200,0],
	"description" : "Forges can create Hammer Dwarves and can upgrade infantry armor and weapons",
	"file_path" : FORGE_FILEPATH,
	"argument" : "location",
	"sprite_path" : "uid://drsrhq5glvf4f" #building_placeholder.png
}
#3D
const RESEARCH_DWARF_BLUNDERBUSS_DICTIONARY : Dictionary = {
	"name" : "Upgrade Armor Level 1",
	"mnemonic" : "F003",
	"command" : Commands.BUILD,
	"cost" : [350,200],
	"description" : "Researches Armor Upgrade Level 1",
	#research params in race specific RESEARCH ENUM
	"file_path" : DWARF_BLUNDERBUSS_FILEPATH,
	"argument" : "location",
	"sprite_path" : "uid://cokfc1ue0hkgq" #upgrade_placeholder.png
}

const UPGRADE_ARMOR_1_DICTIONARY : Dictionary = {
	"name" : "Upgrade Armor Level 1",
	"mnemonic" : "F003",
	"command" : Commands.BUILD,
	"cost" : [350,200],
	"description" : "Researches Armor Upgrade Level 1",
	#research params in race specific RESEARCH ENUM
	"research" : Upgrades.ARMOR_1,
	"argument" : "location",
	"sprite_path" : "uid://cokfc1ue0hkgq" #upgrade_placeholder.png
}
const UPGRADE_ARMOR_2_DICTIONARY : Dictionary = {
	"name" : "Build Forge",
	"mnemonic" : "F004",
	"command" : Commands.BUILD,
	"cost" : [350,200],
	"description" : "Researches Armor Upgrade Level 2",
	#research params in race specific RESEARCH ENUM
	"upgrade" : Upgrades.ARMOR_2,
	"argument" : "location",
	"sprite_path" : "uid://cokfc1ue0hkgq" #upgrade_placeholder.png
}
