extends Node3D

@export var type : String
@export var ingame_ui : Node3D

func _ready() -> void:
	update_vis()

func update_vis():
	if ingame_ui.menu_type == type:
		visible = true
	else:
		visible = false
