extends Node3D
@onready var skills_menu: Node3D = $Skills_menu
@export var slots : Array[Node3D]
@export var backdrop : Node3D
var open := false
var menu_type := "Equipment"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_vis()

func update_vis():
	if open == true:
		backdrop.visible = true
		visible = true
	else:
		backdrop.visible = false
		visible = false


func change_type(type: String, button) -> void :
	update_vis()
	menu_type = type
	match type:
		"Equipment":
			skills_menu.update_vis()
			if button:
				button.update_vis()
		"Skills":
			skills_menu.update_vis()
			if button:
				button.update_vis()
