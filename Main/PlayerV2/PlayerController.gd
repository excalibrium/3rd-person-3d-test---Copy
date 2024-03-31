extends Character

class_name PlayerController

enum AttackState {
	IDLE,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	ATTACK_1_TO_IDLE,
	ATTACK_2_TO_IDLE,
	ATTACK_3_TO_IDLE
}

@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
var state_machine
var current_state
@onready var staminabar = $HUD/StaminaBar
var speed_multiplier = 1.0
var target_rotation: float = 0.0
var global_dir = 0
var attack_meter: float = 0.0
var leftclick = false
var attack_state = AttackState.IDLE
var lockOn = false
func _ready():
	staminabar.init_stamina(stamina)
func _input(event):
	if event.is_action_pressed("Q"):
		lockOn = true
	if event.is_action_pressed("Escape"):
		get_tree().quit()
		return
func _process(delta):
	state_machine = animationTree.get("parameters/playback")
	current_state = state_machine.get_current_node()
	print(attacking)
	print(attack_state)
	print(attack_meter)
	_handle_variables(delta)
func _physics_process(delta):
	_handle_movement()
	_handle_combat(delta)
	_handle_animations()
	super(delta) # Call the parent class's _physics_process

func _handle_movement():
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	global_dir = input_dir
	var camera_direction: Vector3 = ($Camera/view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var character_direction = $view.transform.basis.z.normalized()
	if input_dir.length() > 0 and !movement_lock:
		is_moving = true
		target_rotation = atan2(camera_direction.x, camera_direction.z)
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.2)
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.2)
		velocity.x = lerpf(velocity.x, character_direction.x * speed_multiplier * 3, 0.2)
		velocity.z = lerpf(velocity.z, character_direction.z * speed_multiplier * 3, 0.2)
	else:
		is_moving = false
		velocity.x = lerpf(velocity.x, 0, 0.2)
		velocity.z = lerpf(velocity.z, 0, 0.2)
	if Input.is_action_pressed("SpaceBar") and is_on_floor():
		action_bar += 1
	if Input.is_action_just_released("SpaceBar") and is_on_floor():
		action_bar = 0

func _handle_variables(delta):
	if time_since_stamina_used < stamina_grace_period:
		time_since_stamina_used += delta
	#print(time_since_stamina_used)
	#print(is_dodging)
	#print(time_since_attack)
	if stamina < 0:
		stamina = 0
	staminabar.stamina = stamina
#action_bar actions
	#RUNNING
	if action_bar > 20 and stamina > 1 and is_moving:
		is_running = true
		stamina -= delta * stamina_drain_rate  # Drain stamina
		time_since_stamina_used = 0 #stamina used
	else:
		is_running = false

	if is_running == true:
		speed_multiplier = 1.5
	else:
		speed_multiplier = 1.0

	# regen stamina.
	if time_since_stamina_used >= stamina_grace_period and stamina < max_stamina:
		stamina += delta * stamina_regeneration_rate
		
func _handle_animations():
	var camattachment = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment
	$Camera.global_transform.origin.x = camattachment.global_transform.origin.x
	$Camera.global_transform.origin.z = camattachment.global_transform.origin.z
	var _animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
	animationTree.set("parameters/conditions/idle", is_moving == false and is_on_floor() and attacking == false)
	animationTree.set("parameters/conditions/is_moving", is_moving == true and is_on_floor() and attacking == false)
	# Do anims.
	pass 



func _handle_combat(delta):
	if current_state == "move":
		print("MOVING")
	if attacking:
		if attack_state == AttackState.ATTACK_3:
			state_machine.travel("Attack_3")
		elif attack_state == AttackState.ATTACK_2:
			state_machine.travel("Attack_2")
		elif attack_state == AttackState.ATTACK_1:
			state_machine.travel("Attack_1")
	elif current_state == "move" or current_state == "idle":
		attack_state = AttackState.IDLE

	if attack_state == AttackState.ATTACK_1 or attack_state == AttackState.ATTACK_2 or attack_state == AttackState.ATTACK_3:
		movement_lock = true
	else:
		movement_lock = false

	if Input.is_action_just_pressed("LeftClick"):
		attacking = true
		leftclick = true

	if Input.is_action_pressed("LeftClick") and attacking:
		attack_meter += delta
		if attack_meter >= 0.5:
			print("charge_attack_placeholder")
			attack_meter = 0.0
			leftclick = false
			attacking = false
			attack_state = AttackState.IDLE

	if Input.is_action_just_released("LeftClick") and leftclick == true:
		handle_attack_release()

func handle_attack_release():

	if attack_meter < 0.5:
		if attack_state == AttackState.IDLE or attack_state == AttackState.ATTACK_3_TO_IDLE:
			attack_state = AttackState.ATTACK_1
		elif attack_state == AttackState.ATTACK_1 or attack_state == AttackState.ATTACK_1_TO_IDLE:
			if attack_state == AttackState.ATTACK_1:
				attack_buffer = 2
			if attack_state == AttackState.ATTACK_1_TO_IDLE:
				attack_state = AttackState.ATTACK_2
		elif attack_state == AttackState.ATTACK_2 or attack_state == AttackState.ATTACK_2_TO_IDLE:
			if attack_state == AttackState.ATTACK_2:
				attack_buffer = 3
			if attack_state == AttackState.ATTACK_2_TO_IDLE:
				attack_state = AttackState.ATTACK_3
		attack_meter = 0
		leftclick = false

func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			if attack_buffer == 2:
				attack_state = AttackState.ATTACK_2
				attack_buffer = 0
			else:
				attack_state = AttackState.ATTACK_1_TO_IDLE
				state_machine.travel("Attack_1_to_idle")
				attacking = false
		"Attack_2":
			if attack_buffer == 3:
				attack_state = AttackState.ATTACK_3
				attack_buffer = 0
			else:
				attack_state = AttackState.ATTACK_2_TO_IDLE
				state_machine.travel("Attack_2_to_idle")
				attacking = false
		"Attack_3":
			attack_state = AttackState.ATTACK_3_TO_IDLE
			state_machine.travel("Attack_3_to_idle")
			attacking = false
		"Attack_3_to_idle":
			attacking = false
