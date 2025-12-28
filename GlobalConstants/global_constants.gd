class_name GlobalConstants
extends Node

const TEAMS: Dictionary[int, String] = {0 : "blue", 1: "red", 2: "green", 3: "purple", 99: "neutral"}
const COLORS: Dictionary[int, Color] = {0 : Color.NAVY_BLUE, 1: Color.DARK_RED, 2: Color.DARK_GREEN, 3: Color.REBECCA_PURPLE}
const RACES: Dictionary[int, String] = {0 : "dwarves"}
#LOBBY DICTIONARY KEYS
const USERNAME_KEY: String = "username";
const READY_KEY: String = "ready";
const TEAM_KEY: String = "team";
const COLOR_KEY: String = "color";
const RACE_KEY: String = "race";

#GAME PATHS
const GAME: PackedScene = preload("uid://1vvyuea6fq3v")
const GAME_PATH: String = "res://Game/GameScene/game.tscn";

#ENTITY FILEPATHS
const COMMAND_CENTER: String = "res://Game/EntityList/BuildingList/command_center.tscn"
