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

var player_no: Array
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
var state_machine
var current_state
@onready var staminabar = $HUD/StaminaBar
@onready var healthbar = $HUD/HealthBar
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
var speed
var time_since_actionbar_halt = 1
var stored_velocity: Vector3
var dickrot
@onready var animation_tree = $BaseModel3D/MeshInstance3D/AnimationTree
var RMPos
func _ready():
	state_machine = animationTree.get("parameters/StateMachine/playback")
	enemies = get_tree().get_nodes_in_group("enemies")
	player_no = get_tree().get_nodes_in_group("Player")
	staminabar.init_stamina(stamina)
	healthbar.init_health(health)
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
	#print(RMPos)
	#print(global_position)
	current_state = state_machine.get_current_node()
	current_path = state_machine.get_travel_path()
	#print(current_path)
	#print(current_state)
	#print(movement_lock)
	#print(attacking)
	#print(attack_state)
	#print(attack_meter)
	#print(weaponCollidingWall)
	_handle_variables(delta)
	_handle_detection()

func _physics_process(delta):
	RMPos = animation_tree.get_root_motion_position()
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_animations(delta)
	super(delta) # Call the parent class's _physics_process

func _handle_detection():
	closest_enemy = null
	var closest_distance = INF
	"res://Main/PlayerV2/Player.tscn"
	#print(closest_distance)
	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
			
	if closest_enemy != null:
		#print("Closest enemy: ", closest_enemy.name)
		$enemy_radar.look_at(closest_enemy.global_transform.origin, Vector3.UP)


func _handle_movement(delta):
	if global_position.y <= -5:
		state_machine.travel("death_01")
		print("player fell off", player_no)
	if Input.is_action_pressed("emulate"):
		ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", "true")
		ProjectSettings.save()
	var spd : float = velocity.length();
	speed = spd
	#print(velocity)
	#print(spd)
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	global_dir = input_dir
	var camera_direction: Vector3 = ($Camera/view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var character_direction = $view.transform.basis.z.normalized()
	target_rotation = atan2(camera_direction.x, camera_direction.z)
	if input_dir.length() > 0 and !movement_lock and is_on_floor():
		is_moving = true
		if lockOn == true:
			$BaseModel3D.rotation.y = $enemy_radar.rotation.y - PI
		else:
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.2)
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.2)
		#velocity.x = lerpf(velocity.x, character_direction.x * speed_multiplier, 0.075)
		#velocity.z = lerpf(velocity.z, character_direction.z * speed_multiplier, 0.075)
		velocity = lerp(velocity, character_direction * speed_multiplier, 0.075)
		stored_velocity = velocity
	elif is_on_floor():
		is_moving = false
		velocity.x = lerpf(velocity.x, 0, 0.15)
		velocity.z = lerpf(velocity.z, 0, 0.15)
	var current_rotation := transform.basis.get_rotation_quaternion().normalized()

	global_position += $BaseModel3D.global_transform.basis * RMPos

	if movement_lock and attacking and input_dir.length() > 0:
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.05)
		if !lockOn:
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.1)

	if Input.is_action_pressed("SpaceBar") and is_on_floor():
		action_bar += 1
		time_since_actionbar_halt = 0
	if Input.is_action_just_pressed("SpaceBar") and action_bar >= 20:
		velocity.y += 5
		#velocity.z = stored_velocity.z
		#velocity.x = stored_velocity.x
		action_bar = 0
	dickrot = character_direction

func _handle_variables(delta):
	#print(health)
	if time_since_actionbar_halt < 0.3:
		time_since_actionbar_halt += delta
	if time_since_actionbar_halt >= 0.3:
		action_bar = 0
	#print(action_bar)
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
		speed_multiplier = 8.0
	else:
		speed_multiplier = 3.0

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
	animationTree.set("parameters/StateMachine/conditions/idle", is_moving == false and is_on_floor() and attacking == false and is_blocking == false and is_running == false)
	animationTree.set("parameters/StateMachine/conditions/move", is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == false and speed < 4.8)
	animationTree.set("parameters/StateMachine/conditions/run", is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == true and speed >= 4.8)
	# Do anims.
	pass 

func _handle_combat(delta):
	print("path:", current_path)
	print("current state:", current_state)
	if !attacking:
		currentweapon.Hurt = false

	match current_state:
		"Attack_1":
			currentweapon.attack_multiplier = 2
			attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.3 && attack_timer < 0.4583 ):
				currentweapon.Hurt = true
			else:
				currentweapon.Hurt = false
		"Attack_2":
			currentweapon.attack_multiplier = 2
			attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.3 && attack_timer < 0.5 ):
				currentweapon.Hurt = true
			else:
				currentweapon.Hurt = false
		"Attack_3":
			currentweapon.attack_multiplier = 0.5
			attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.4 && attack_timer < 0.5417 ):
				currentweapon.Hurt = true
			else:
				currentweapon.Hurt = false
		"Attack_4":
			currentweapon.attack_multiplier = 0.5
			attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.1 && attack_timer < 3.375 ):
				currentweapon.Hurt = true
			else:
				currentweapon.Hurt = false
	#print("hurt :", currentweapon.Hurt)
	print(currentweapon.attack_multiplier)


	if is_blocking and !is_moving and !attacking and !is_running:
		state_machine.travel("shield_block_1")
	elif is_blocking and is_moving and !attacking and !is_running:
		state_machine.travel("shield_block_walk")
	elif is_blocking and is_moving and !attacking and is_running:
		state_machine.travel("run_blocking")
	if Input.is_action_pressed("RightClick"):
		attack_buffer = 0
		is_blocking = true
	else:
		is_blocking = false

	if time_since_engage <= 10:
		time_since_engage += delta
	movement_lock = current_state in ["Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_C_1", "Attack_C_1_bash"] or stunned

	if Input.is_action_just_pressed("LeftClick"):
		leftclick = true

	if Input.is_action_pressed("LeftClick") and !stunned:
		attack_meter += delta
		if attack_meter >= 0.5:
			state_machine.travel("Attack_C_1")
			print("charge_attack_placeholder")
			time_since_engage = 0
			attack_meter = 0.0
			leftclick = false

	#print(weaponCollidingWall, attacking, currentweapon.Hurt)
	if weaponCollidingWall and attacking and currentweapon.Hurt == true:
		stunned = true
		attacking = false
		state_machine.travel("hit_cancel")

	if Input.is_action_just_released("LeftClick") and leftclick == true:
		handle_attack_release()

func handle_attack_release():
	if attack_meter < 0.5 and time_since_engage >= attack_grace and !stunned:
		print(attacking, "MUST ATTACK", "buffer?", attack_buffer)
		time_since_engage = 0
		if current_state in ["idle", "walk", "run", "walk_to_idle", "idle_to_walk", "attack_3_to_idle"]:
			attacking = true
			state_machine.travel("Attack_1")
		match current_state:
			"Attack_1":
				attack_buffer = 1
			"Attack_1_to_idle":
				state_machine.travel("Attack_2")
				attacking = true
			"Attack_2":
				attack_buffer = 2
			"Attack_2_to_idle":
				state_machine.travel("Attack_3")
				attacking = true
			"Attack_3":
				attack_buffer = 3
			"Attack_3_to_idle":
				state_machine.travel("Attack_4")
				attacking = true
			"Attack_C_1":
				state_machine.travel("Attack_C_1_bash")
		print(attacking, "NEW MUST ATTACK", "new buffer", attack_buffer)
	attack_meter = 0
	leftclick = false
func _on_animation_tree_animation_started(anim_name):
	if anim_name in ["Attack_1_to_idle", "Attack_2_to_idle", "Attack_3_to_idle", "Attack_4_to_idle", "Attack_5_to_idle", "Attack_6_to_idle"]:
		attacking = false
	match anim_name:
		"Attack_1":
			attacking = true
			attack_timer = 0
		"Attack_2":
			attacking = true
			attack_timer = 0
		"Attack_3":
			attacking = true
			attack_timer = 0
		"Attack_4":
			attacking = true
			attack_timer = 0
		"Attack_5":
			attacking = true
			attack_timer = 0
		"Attack_6":
			attacking = true
			attack_timer = 0
		"Attack_1_to_idle":
			if attack_buffer == 1 and !weaponCollidingWall:
				state_machine.travel("Attack_2")
				attack_buffer = 0
		"Attack_2_to_idle":
			if attack_buffer == 2 and !weaponCollidingWall:
				state_machine.travel("Attack_3")
				attack_buffer = 0
		"Attack_3_to_idle":
			if attack_buffer == 3 and !weaponCollidingWall:
				state_machine.travel("Attack_4")
				attack_buffer = 0
func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			attack_timer = 0
			if attack_buffer == 1 and !weaponCollidingWall:
				state_machine.travel("Attack_2")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("Attack_1_to_idle")
		"Attack_2":
			attack_timer = 0
			if attack_buffer == 2 and !weaponCollidingWall:
				state_machine.travel("Attack_3")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("Attack_2_to_idle")
		"Attack_3":
			attack_timer = 0
			if attack_buffer == 3 and !weaponCollidingWall:
				state_machine.travel("Attack_4")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("Attack_3_to_idle")
		"Attack_4":
			attack_timer = 0
			if attack_buffer == 4 and !weaponCollidingWall:
				state_machine.travel("Attack_5")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("Attack_4_to_idle")
		"Attack_5":
			attack_timer = 0
			if attack_buffer == 5 and !weaponCollidingWall:
				state_machine.travel("Attack_6")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("Attack_5_to_idle")
		"Attack_6":
			attack_timer = 0
			if !stunned:
				state_machine.travel("Attack_5_to_idle")
		"hit_cancel":
			state_machine.travel("idle")
			stunned = false
			attacking = false
		"death_01":
			stunned = false
			player_death(0)
func _on_hitbox_area_entered(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = true
func _on_hitbox_area_exited(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = false


func _on_ruined_blade_hitbox_area_entered(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = true
func _on_ruined_blade_hitbox_area_exited(area):
	if area.is_in_group("walls"):
		weaponCollidingWall = false

func player_death(x):
	global_position = Vector3(0,3,0)
	player_no[x].reset()
	is_moving = false
	attacking = false
	is_blocking = false
	is_running = false
	healthbar.health = health
func damage_by(damaged: int):
	print("damaged you are")
	health -= damaged
	if health <= 1:
		state_machine.travel("death_01")
		stunned = true
	
	healthbar.health = health
	




