extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func highlight() -> void:
	set_deferred("visible", true);

func unhighlight() -> void:
	set_deferred("visible", false);
