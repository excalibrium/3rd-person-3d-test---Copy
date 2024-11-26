@tool
extends Node3D

@export var upper_body_skewer: Node3D
@export var sword_bone_skewer: Node3D


func _process(delta):
	global_transform = sword_bone_skewer.global_transform
