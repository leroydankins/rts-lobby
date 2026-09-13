extends Control

@onready var rtl: RichTextLabel = $PanelContainer/RichTextLabel

var feed_resource: FeedResource = preload("uid://wgm62a18h2ce")

# Enable threading if we are getting performance hits!

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _discard: int = feed_resource.feed_added.connect(on_feed_added)
	append_action("We are starting the damn feed here!");
	pass # Replace with function body.

func on_feed_added(p_text: String) ->void:
	append_action(p_text);



# Appends the user's message as-is, without escaping. This is dangerous!
func append_action(message: String) ->void:
	rtl.append_text("%s \n" % message)
	visible = true;
	modulate = Color(1,1,1,1);
	var tween: Tween = create_tween();
	tween.tween_property(self,"modulate", Color(1,1,1,.25),4)
	tween.tween_property(self,"visible",false,.1)

# Appends the user's message as-is, without escaping. This is dangerous!
func append_chat_line(username: String, message: String) ->void:
	rtl.append_text("%s: [color=green]%s[/color]\n" % [username, message])

	# Appends the user's message with escaping.
# Remember to escape both the player name and message contents.
func append_chat_line_escaped(username: String, message: String) ->void:
	rtl.append_text("%s: [color=green]%s[/color]\n" % [escape_bbcode(username), escape_bbcode(message)])

# Returns escaped BBCode that won't be parsed by RichTextLabel as tags.
func escape_bbcode(bbcode_text: String) ->String:
	# We only need to replace opening brackets to prevent tags from being parsed.
	return bbcode_text.replace("[", "[lb]")
