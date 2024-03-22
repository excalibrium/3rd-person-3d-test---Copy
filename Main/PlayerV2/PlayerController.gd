extends Character

class_name PlayerController
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
var state_machine
var current_state
@onready var staminabar = $HUD/StaminaBar
var speed_multiplier = 1.0
var target_rotation: float = 0.0
var global_dir = 0
var attack_meter: float = 0.0
var movement_lock = false
var leftclick = false
var attack_state = 0.0
func _ready():
	staminabar.init_stamina(stamina)
func _input(event):
	if event.is_action_pressed("Escape"):
		get_tree().quit()
		return
func _process(delta):
	state_machine = animationTree.get("parameters/playback")
	current_state = state_machine.get_current_node()
	print(attacking)
	print(attack_state)
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
	var animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
	animationTree.set("parameters/conditions/idle", is_moving == false and is_on_floor() and attacking == false)
	animationTree.set("parameters/conditions/is_moving", is_moving == true and is_on_floor() and attacking == false)
	# Do anims.
	pass 




func _handle_combat(delta):
	if attack_state == 2.0 and attacking == true:
		state_machine.travel("Attack_2")
	if current_state == "Attack_2":
		attack_state = 0.0
	if current_state == "Attack_1" or current_state == "Attack_2":
		movement_lock = true
	else:
		movement_lock = false
	if Input.is_action_just_pressed("LeftClick"):
		attacking = true
		leftclick = true
	if Input.is_action_pressed("LeftClick") and attacking == true:
		attack_meter += delta
		if attack_meter >= 0.5: #play charge attack
			print("charge_attack_placeholder")
			leftclick = false
			attacking = false #making sure holding LC does nothing afterwards. couldve made a hold CA mechanic that switches between 2 or loops animations example: claymore users in genshin
	if Input.is_action_just_released("LeftClick"):
		if attacking == true and attack_meter < 0.5:
			if current_state != "Attack_2" and current_state == "Attack_1" or current_state == "Attack_1_to_idle":
				if attack_state == 1.0:
					attack_state = 1.5
					print("attack2 must buffer")
				attacking = true
				if attack_state == 0.0:
					state_machine.travel("Attack_2")
			if current_state != "Attack_1" and current_state == "Idle" or current_state == "move" or current_state == "Attack_2_to_idle":
				attack_state = 1.0
				state_machine.travel("Attack_1")
		attack_meter = 0
		leftclick = false


func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "Attack_1":
		if attack_state == 1.5:
			attack_state = 2.0
			attacking = true
		else:
			state_machine.travel("Attack_1_to_idle")
			attack_state = 0.0
			attacking = false
	if anim_name == "Attack_2":
		state_machine.travel("Attack_2_to_idle")
		attack_state = 0.0
		attacking = false
