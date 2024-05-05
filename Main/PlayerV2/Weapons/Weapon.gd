extends Node3D
class_name Weapon

@export var Hurt = false
@onready var hitboxes: Array = []
@export var attack_damage := 10.0
@export var attack_multiplier := 1.0
