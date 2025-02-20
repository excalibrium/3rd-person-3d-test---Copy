extends Node3D

var switch_1 := false
var switch_2 := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#go_to_tip()
	if switch_1 == true:
		global_rotation_degrees += owner.owner.global_rotation_degrees
		switch_1 = false
		pass
#		global_rotation_degrees = Vector3(90,0,0)
	if switch_2 == true:
		global_rotation_degrees += owner.owner.global_rotation_degrees
		switch_2 = false
		pass
#		global_rotation_degrees = Vector3(0,0,90)

func gtt():
	global_position = owner.owner.ps.global_position
	visible = true
	print("gtt")
