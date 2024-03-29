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
var time_since_stamina_used = 0
var attacking = false
var attack_buffer = 0
var is_dodging = false
var is_attacking = 0
var is_running = false
var is_moving = false
var movement_lock = false
var time_since_attack = 0
var attack_grace = 0.7
var action_bar = 0
func _process(delta):
	return

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta * 1.125
	move_and_slide()
