extends Node3D

@export var doors: Array[Door]

var is_player_nearby: bool

func _ready():
	if doors.size() > 1:
		return
	## Prevent crashing by checking if any doors are in the list.
	## This would cause crashes if we were to toggle nothing (i.e list is there, but nothing is in it.)
	assert("No door was set in the doors array, quitting.")


func _input(event):
	if event.is_action_pressed("interact") && is_player_nearby:
		toggle_doors()

## For each door in the list of doors, toggle them.
func toggle_doors():
	for door in doors:
		door.toggle()

## Set player is near to true when player has entered the area
func _on_area_3d_body_entered(body):
	if body is _Player:
		is_player_nearby = true

## Set player is near to false when player has exited the area
func _on_area_3d_body_exited(body):
	if body is _Player:
		is_player_nearby = false

