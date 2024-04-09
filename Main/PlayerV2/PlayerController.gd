extends Character

class_name PlayerController

enum AttackState {
	IDLE,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	ATTACK_1_TO_IDLE,
	ATTACK_2_TO_IDLE,
	ATTACK_3_TO_IDLE,
	STUNNED
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
var weaponCollidingWall = false
var enemies = []
var closest_enemy = null
var current_path
func _ready():
	state_machine = animationTree.get("parameters/StateMachine/playback")
	enemies = get_tree().get_nodes_in_group("enemies")
	staminabar.init_stamina(stamina)
func _input(event):
	if event.is_action_pressed("Q"):
		if lockOn == false:
			lockOn = true
		elif lockOn == true:
			lockOn = false
	if event.is_action_pressed("Escape"):
		get_tree().quit()
		return
func _process(delta):
	current_state = state_machine.get_current_node()
	current_path = state_machine.get_travel_path()
	print(current_path)
	print(current_state)
	print(movement_lock)
	print(attacking)
	print(attack_state)
	print(attack_meter)
	print(weaponCollidingWall)
	_handle_variables(delta)
	_handle_detection()
func _physics_process(delta):
	_handle_movement()
	_handle_combat(delta)
	_handle_animations(delta)
	super(delta) # Call the parent class's _physics_process

func _handle_detection():
	closest_enemy = null
	var closest_distance = INF
	
	print(closest_distance)
	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
			
	if closest_enemy != null:
		print("Closest enemy: ", closest_enemy.name)
		$enemy_radar.look_at(closest_enemy.global_transform.origin, Vector3.UP)


func _handle_movement():
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	global_dir = input_dir
	var camera_direction: Vector3 = ($Camera/view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var character_direction = $view.transform.basis.z.normalized()
	target_rotation = atan2(camera_direction.x, camera_direction.z)
	if input_dir.length() > 0 and !movement_lock:
		is_moving = true
		if lockOn == true:
			$BaseModel3D.rotation.y = $enemy_radar.rotation.y - 3
		else:
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.2)
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.2)
		velocity.x = lerpf(velocity.x, character_direction.x * speed_multiplier * 3, 0.2)
		velocity.z = lerpf(velocity.z, character_direction.z * speed_multiplier * 3, 0.2)
	else:
		is_moving = false
		velocity.x = lerpf(velocity.x, 0, 0.2)
		velocity.z = lerpf(velocity.z, 0, 0.2)


	if movement_lock and attacking and input_dir.length() > 0:
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.05)
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
		
func _handle_animations(delta):
	var camattachment = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment
	$Camera.global_transform.origin.x = camattachment.global_transform.origin.x
	$Camera.global_transform.origin.z = camattachment.global_transform.origin.z
	var _animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
#	if is_moving == false and is_on_floor() and attacking == false and is_blocking == false:
#		state_machine.travel("idle")
#	if is_moving == true and is_on_floor() and attacking == false and is_blocking == false:
#		state_machine.travel("move")
	animationTree.set("parameters/StateMachine/conditions/idle", is_moving == false and is_on_floor() and attacking == false and is_blocking == false)
	animationTree.set("parameters/StateMachine/conditions/move", is_moving == true and is_on_floor() and attacking == false and is_blocking == false)
	# Do anims.
	pass 



func _handle_combat(delta):
	if is_blocking and !is_moving:
		state_machine.travel("shield_block_1")
	elif is_blocking and is_moving:
		state_machine.travel("shield_block_run")
	if Input.is_action_pressed("RightClick"):
		is_blocking = true
	else:
		is_blocking = false

	if weaponCollidingWall and attacking and currentweapon.Hurt == true:
		state_machine.travel("hit_cancel")
		stunned = true
		attacking = false
	if time_since_attack <= attack_grace:
		time_since_attack += delta

	movement_lock = current_state in ["Attack_1", "Attack_2", "Attack_3"] or stunned

	if Input.is_action_just_pressed("LeftClick"):
		leftclick = true

	if Input.is_action_pressed("LeftClick") and leftclick == true and !stunned:
		attack_meter += delta
		if attack_meter >= 0.5:
			print("charge_attack_placeholder")
			time_since_attack = 0
			attack_meter = 0.0
			leftclick = false
			attacking = false



	if Input.is_action_just_released("LeftClick") and leftclick == true:
		handle_attack_release()

func handle_attack_release():
	leftclick = false
	if attack_meter < 0.5 and time_since_attack >= attack_grace and !stunned:
		time_since_attack = 0
		if current_state in ["idle", "move", "attack_3_to_idle"]:
			attacking = true
			state_machine.travel("Attack_1")
		match current_state:
			"Attack_1":
				attack_buffer = 1
			"Attack_1_to_idle":
				attacking = true
				state_machine.travel("Attack_2")
			"Attack_2":
				attack_buffer = 2
			"Attack_2_to_idle":
				attacking = true
				state_machine.travel("Attack_3")
	attack_meter = 0

func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			if !lockOn:
				$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.7)
			if attack_buffer == 1:
				state_machine.travel("Attack_2")
				attack_buffer = 0
			else:
				attacking = false
				state_machine.travel("Attack_1_to_idle")
		"Attack_2":
			if !lockOn:
				$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.7)
			if attack_buffer == 2:
				state_machine.travel("Attack_3")
				attack_buffer = 0
			else:
				attacking = false
				state_machine.travel("Attack_2_to_idle")
		"Attack_3":
			if !lockOn:
				$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.7)
			attacking = false
			state_machine.travel("Attack_3_to_idle")
		"hit_cancel":
			stunned = false
			attacking = false



func _on_spear_hitbox_area_entered(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = true
	else:
		weaponCollidingWall = false


func _on_ruined_blade_hitbox_area_entered(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = true


func _on_ruined_blade_hitbox_area_exited(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = false

