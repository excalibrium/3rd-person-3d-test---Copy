extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if Input.is_action_pressed("F"):
		var scene = load("res://Main/Enemies/Casual/casual_enemy.tscn")
		var casene = scene.instantiate()
		add_child(casene)

