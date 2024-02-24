extends CharacterBody3D

class_name Character 

const SPEED = 3.0
const JUMP_VELOCITY = 4.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var stamina = 100
var max_stamina = 100
var stamina_drain_rate = 20
var stamina_regeneration_rate = 32
var stamina_grace_period = 1

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta * 1.125
	move_and_slide()