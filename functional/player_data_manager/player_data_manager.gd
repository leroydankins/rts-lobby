class_name PlayerDataManager
extends Node

signal team_won(winning_team: int);

#################################################################
##var player_dictionary: Dictionary[String, Variant] = { ##Data is collected from the lobby node and then we do not communicate with lobby after

#dictionary of all players and their in game data (like resources)

var player_dict: Dictionary[int, Dictionary] = {};
var local_id: int #this is the player color id number that is tied to this player

const USERNAME_KEY: String = "player_username";
const GAS_KEY: String = "player_gas";
const RACE_KEY: String = "player_race";
const COLOR_KEY: String = "player_color"; #the color will be the same as the player id!
const TEAM_KEY: String = "player_team";
const PEER_ID_KEY: String = "player_peer_id";
const SUPPLY_KEY: String = "player_supply";
const MINERAL_KEY: String = "player_mineral";
const PLAYING_KEY: String = "player_playing";




#Array of team's units


@rpc("any_peer", "call_local", "reliable")
func request_player_data_update(player_id: int, key: String, data: Variant) -> void:
	if (!is_multiplayer_authority()):
		return;
	if (!player_dict.has(player_id)):
		return;
	if(key == MINERAL_KEY || key == GAS_KEY):
		var val: int = player_dict[player_id][key];
		var new_val: int = val + data;
		if (val <= 0):
			val = 0;
		data = new_val;

	player_dict[player_id][key] = data;

	push_player_data_update.rpc(player_id,key,data);

##TODO
@rpc("any_peer", "call_local", "reliable")
func request_player_data_update_batch(_player_id: int, _new_dict: Dictionary[String,Variant]) ->void:
	#send a full local player dictionary to that player
	pass;

##TODO
@rpc("authority", "call_local", "reliable")
func push_player_data_update(updated_player: int, key: String, data: Variant) ->void:
	#if this was not called by the authority return;
	if (multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		push_error("this wasnt sent by the authority? wtf");
		return;
	#if this is not a valid player return;
	if (!player_dict.has(updated_player)):
		push_error("not a valid player in dictionary");
		return;
	#update our player_dictionary

	player_dict[updated_player][key] = data;
	pass;

@rpc("authority", "call_local", "reliable")
func push_player_data_update_batch(updated_player:int, dict: Dictionary[int, Variant]) ->void:
	#if this was not called by the authority return;
	if (multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		push_error("this wasnt sent by the authority? wtf");
		return;
	#if this is not a valid player return;
	if (!player_dict.has(updated_player)):
		push_error("not a valid player in dictionary");
		return;
		#if we are updating the local player's information
	#update our player_dictionary
	player_dict[updated_player] = dict;



#Called during the game initialization startup
@rpc("authority","call_local","reliable")
func push_game_data_batch(dict: Dictionary[int, Dictionary]) ->void:
	#if this was not called by the authority return;
	if (multiplayer.get_remote_sender_id() != get_multiplayer_authority()):
		push_error("this wasnt sent by the authority? wtf");
		return;
	player_dict = dict;

func spend_resources(player_id: int, cost_arr: Array) -> bool:
	var mineral_cost: int = cost_arr[0];
	var gas_cost: int = cost_arr[1];
	#final check on resources

	if (mineral_cost > player_dict[player_id][MINERAL_KEY]):
		return false;
	if (gas_cost> player_dict[player_id][GAS_KEY]):
		return false;
	#cost array is converted to absolute values
	request_player_data_update.rpc(player_id, MINERAL_KEY, -1 * abs(mineral_cost));
	request_player_data_update.rpc(player_id, GAS_KEY, -1 * abs(gas_cost));
	return true;

#cost array is converted to absolute values
func refund_resources(player_id: int, cost_arr: Array) ->bool:
	var mineral_cost: int = cost_arr[0];
	var gas_cost: int = cost_arr[1];
	#final check on resources

	#max allowable minerals?
	if (mineral_cost > 99999):
		return false;
	#max allowable gas?
	if (gas_cost> 99999):
		return false;

	request_player_data_update.rpc(player_id, MINERAL_KEY, abs(mineral_cost));
	request_player_data_update.rpc(player_id, GAS_KEY, abs(gas_cost));
	return true;

#check which resource to supply in this scenario, different than spend s
func gain_resources(player_id: int, resource_arr: Array) -> bool:
	#slot 0 is amount, slot 1 is resource type
	match(resource_arr[1]):
		GlobalConstants.ResourceType.MINERAL:
			var mineral_cost: int = resource_arr[0];
			request_player_data_update.rpc(player_id, MINERAL_KEY, mineral_cost);
			return true;
		GlobalConstants.ResourceType.GAS:
			var gas_cost: int = resource_arr[0];
			request_player_data_update.rpc(player_id, GAS_KEY, gas_cost);
			return true;
		_:
			print("not valid resource type, returning  false")
			return false;

@rpc("any_peer","call_local","reliable")
func defeat_player(player_id:int) -> void:
	if(!is_multiplayer_authority()):
		return;
	request_player_data_update(player_id,PLAYING_KEY,false); #sends player update to all players
	var team: int = player_dict[player_id][TEAM_KEY];
	var team_lost: bool = true;
	for player: int in player_dict.keys():
		if player == player_id:
			print('this happens once')
			continue;
		if(player_dict[player][TEAM_KEY] == team): #if we have teammates that are still in the game and havent lost
			if(player_dict[player][PLAYING_KEY] == true):
				team_lost = false;
	if (team_lost):#if this team lost, check other teams to see who won or if game continues
		#we should definitely get here in 1v1
		print('team lost')
		var teams_left: Array[int] = [];
		print(team, "is the team that lost")
		for player: int in player_dict.keys():
			print(player_dict[player])
			if (player_dict[player][TEAM_KEY] == team):
				continue;
			if (teams_left.has(player_dict[player][TEAM_KEY])):
				continue;
			if(player_dict[player][PLAYING_KEY] == true): #this is the issue
				teams_left.append(player_dict[player][TEAM_KEY]);
		if(teams_left.size() == 1):
			#We say which team won! goes to multiplayer authority and then rpc out
			team_won.emit(teams_left[0]);
		print(teams_left.size())
