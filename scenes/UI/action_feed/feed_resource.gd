class_name FeedResource
extends Resource

signal feed_added(p_text: String);

var feed_arr: PackedStringArray = [];

func add_message(p_message: String) ->void:
	feed_arr.append(p_message);
	feed_added.emit(p_message);
