extends Node3D

@export var door : Door
@export var door2 : Door
#@onready var Ray = $RayCast3D
@onready var Area = $Area3D

# Replace "Player" with the actual class name of your player objec
func _input(event):
	if event.is_action_pressed("interact"):
		var overlapping_bodies = Area.get_overlapping_bodies()
	
		for A in overlapping_bodies:
			if A is _Player:  # Replace "Player" with the actual class name of your player object
				door.toggle()
				door2.toggle()
				break  # Exit the loop if you've found the player
#		if Ray.is_colliding():
#			var collider = Ray.get_collider()
#			if collider is _Player:
#				print("RAY colliding too")

	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
