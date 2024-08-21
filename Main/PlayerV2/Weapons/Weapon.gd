extends Node3D
class_name Weapon

@export var Hurt = false
@onready var hitboxes: Array = []
@export var attack_damage := 10.0
@export var attack_multiplier := 1.0
var guard_break = false
var neotgtwjs
var in_area := false
var incheck
var prevhit
var hitCD := 0.0
var hitCD_cap := 0.125
func _physics_process(delta):
	#print(player)
	hitboxes = get_tree().get_nodes_in_group("hitbox")
	#print(hitboxes)
