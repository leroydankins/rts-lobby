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
const WORKER_FILEPATH: String = "res://Game/EntityList/UnitList/worker.scn"

const RESUME_ACTION_DICTIONARY: Dictionary[String, Variant] = {
	"name": "Resume",
	"description" : "Resumes queued actions",
	"file_path" : "",
	"build_time" : 0,
	"sprite" : ""
}

const HALT_ACTION_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Halt",
	"description" : "Halts the current action, does not remove actions from queue",
	"file_path" : "",
	"build_time" : 0,
	"sprite" : ""
}
const CANCEL_ACTION_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Cancel",
	"description" : "Cancels the current action, any queued actions are canceled as well",
	"file_path" : "",
	"build_time" : 0,
	"sprite" : ""
}

const BUILD_WORKER_DICTIONARY: Dictionary[String, Variant] = {
	"name" : "Worker",
	"is_unit" : true,
	"description" : "Builds a dwarf worker",
	"file_path" : WORKER_FILEPATH,
	"build_time" : 10,
}



const SPAWN_DICTIONARY: Dictionary = {
	"filepath" = "",
	"team" = 0,
	"position" = Vector2.ZERO,
	"color" = 0
}
