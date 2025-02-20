extends Node3D
@onready var camera_3d: Camera3D = $"../../../.."
var prev_stone : Node3D
var stone : Node3D
@export var cursor : Node3D
@export var area : Area3D
var timer: Timer
var full := false
#func _ready() -> void:
	#area.look_at(area.global_position - cursor.global_position)


func _ready() -> void:
	area.look_at(camera_3d.global_position, Vector3.UP, true)
	prev_stone = null
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5  # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeout)
	
	timer.start()

func _on_timer_timeout():
	if prev_stone and stone:
		print("prevstone: ", prev_stone.ability_name, " stone: ", stone.ability_name, " full: ", full)
	else:
		if stone:
			print("prevstone: ", prev_stone, " stone: ", stone.ability_name, " full: ", full)
		elif prev_stone:
			print("prevstone: ", prev_stone.ability_name, " stone: ", stone, " full: ", full)
func unslot(perm_nonperm):
	match perm_nonperm:
		"nonperm":
			stone.reset(self, true)

func reslot():
	prev_stone.slot(self)
	prev_stone.fillback = false

func get_ability() -> String:
	if full == true:
		return stone.ability_name
	else:
		return ""
