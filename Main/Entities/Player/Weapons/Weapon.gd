extends Node3D
class_name Weapon

@export var Hurt = false
@onready var hitboxes: Array = []
@export var attack_damage := 10.0
@export var attack_multiplier := 1.0
@export var length := 3.0
var guard_break = false
var neotgtwjs
var in_area := false
var incheck
var prevhit
var my_owner : CharacterBody3D
var hitCD := 0.0
var hitCD_cap := 0.125
var thrown := false
@export var trails := false
@export var trail : GPUTrail3D
func _physics_process(delta):
	#print(player)
	hitboxes = get_tree().get_nodes_in_group("hitbox")
	#print(hitboxes)
func hit(no):
	if self is CometSpear:
		if no == 1:
			$AnimationPlayer.play("hit1")
		if no == 2:
			$AnimationPlayer.play("hit2")
		if no == 3:
			$AnimationPlayer.play("hit3")
		if no == 4:
			$AnimationPlayer.play("hit4")

func attack_init() -> void:
	if self.trails == true:
		trail._set_length(150)

func attack_end() -> void:
	if self.trails == true:
		trail._set_length(15)
