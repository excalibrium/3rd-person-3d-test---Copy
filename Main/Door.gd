extends Node3D

class_name Door

var State = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.

func toggle():
	if State == 0:
		self.rotation_degrees.y = 90
		State = 1
	elif State == 1:
		self.rotation_degrees.y = 0
		State = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
