extends Resource
#entity holder will update this information when registering or removing units?
#units dictionary[int,int] = unit#, amount
var units: Dictionary[String,int] = {};
#buildings dictionary[int, int] = [building#, amount]
var buildings: Dictionary[String,int] = {};
#supply array[int,int] = [current supply, total supply]
var supply: Array[int] = [0,0];

func get_used_supply() -> void:
	#calculate supply by iterating through units
	for i: String in units.keys():
		var supply_num:int = EntityConstants.SUPPLY[i] ###This is a look up key for how much supply this unit takes
		var unit_amount:int = units[i];
		var used_supply: int = unit_amount * supply_num;
		supply[0] = used_supply

func get_supply() ->void:
	#calcualte max supply by iterating through buildings
	for i: String in buildings.keys():
		var supply_num: int = EntityConstants.SUPPLY[i] ###This is a look up key for how much supply this building gives
		if supply_num > 0:
			var building_amount: int = buildings[i];
			var supply: int = building_amount * supply_num;
