extends Node3D
class_name inv_item

@export var item_code : int
@export var type : String
@export var active := false
@onready var area_3d: Area3D = $Area3D


func interacted(by):
	by.recieve_item(item_code, type)
	queue_free()

func _ready() -> void:
	if active == false:
		visible = false
		area_3d.collision_layer = 0
		area_3d.collision_mask = 0
	$Label3D.text = str(item_code)

func activate():
	active = true
	visible = true
	area_3d.collision_layer = 8
	area_3d.collision_mask = 8
