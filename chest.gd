extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_pos: Node3D = $player_pos
@export var item : Node3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
var opened := false
func interacted(by):
	#print("nah")
	if opened == false:
		by.global_position = player_pos.global_position + Vector3(0.0,1.0,0.0)
	
		by.chest_open()
		open()
	#by.staggered = true
		by.view.global_rotation.y = player_pos.global_rotation.y
func open():
	if item is inv_item:
		item.activate()
		
	animation_player.play("open")
	opened = true
func opening():
	audio_stream_player_3d.play()
