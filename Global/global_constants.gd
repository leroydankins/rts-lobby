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
const GAME: PackedScene = preload("uid://1vvyuea6fq3v")
const GAME_PATH: String = "res://Game/GameScene/game.tscn";

#ENTITY FILEPATHS
const COMMAND_CENTER_FILEPATH: String = "res://Game/EntityList/BuildingList/command_center.tscn"
const WORKER_FILEPATH: String = "res://Game/EntityList/UnitList/worker.tscn"

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
	GARRISON
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
	HALTED,
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

#COMMAND DICTIONARIES
const TARGET_DICTIONARY : Dictionary[String, Variant] = {
	"name" : "Target",
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
	"description" : "Cancels the current action, any queued actions are canceled as well",
	"file_path" : "",
	"build_time" : 0,
	"sprite_path" : "res://Resources/CommandSprites/cancel_placeholder.png"
}
const MOVE_TO_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Target Location",
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
	"sprite_path" : "res://Resources/CommandSprites/placeholder_unit.png"
}
const BUILD_BASE_DICTIONARY  : Dictionary = {
	"name" : "Build Base",
	"mnemonic" : "WK003",
	"command" : Commands.BUILD,
	"cost" : [300,0],
	"description" : "Builds Dwarven Base",
	"file_path" : COMMAND_CENTER_FILEPATH,
	"argument" : "location",
	"sprite_path" : "res://Resources/CommandSprites/building_placeholder.png"
}
const SPAWN_DICTIONARY: Dictionary = {
	"filepath" = "",
	"team" = 0,
	"position" = Vector2.ZERO,
	"color" = 0
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
	"sprite_path" : "res://Resources/CommandSprites/building_placeholder.png"
}
const BUILD_BARRACKS : Dictionary = {
	"name" : "Build Barracks",
	"command" : Commands.BUILD,
	"cost" : [200,0],
	"description" : "Builds Dwarven Base",
	"file_path" : null,
	"argument" : "location",
	"sprite_path" : "res://Resources/CommandSprites/building_placeholder.png"
}
