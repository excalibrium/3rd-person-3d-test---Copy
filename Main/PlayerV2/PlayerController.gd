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
@onready var _animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
var state_machine
var current_state
@onready var staminabar = $HUD/StaminaBar
@onready var healthbar = $HUD/HealthBar
var speed_multiplier = 1.0
var target_rotation: float = 0.0
var global_dir = 0
var attack_meter: float = 0.0
var shield_meter: float = 0.0
var leftclick = false
var rightclick = false
var attack_state = AttackState.IDLE
var lockOn = false
var enemies = []
var closest_enemy
var current_path := []
var speed
var time_since_actionbar_halt = 1
var stored_velocity: Vector3
var dickrot
var canBeDamaged := false
var rotate_to_view = true
var shift := false
var path_empty := true
var in_mode := false
var shield_activation := false
var charge_attack := false
var RMPos
var lhi = 1
var currentanimplayer
var prev_weapon
var cometspear
var botrk
var fists
func _ready():
	if currentweapon == null:
		LeftHandItem = "Fists"
		fists = fistScene.instantiate()
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.add_child(fists)
		currentweapon = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.get_child(0)
		$BaseModel3D/MeshInstance3D/AnimationTree.set_animation_player("../FistAnimPlayer") 
		prev_weapon = currentweapon
	state_machine = animationTree.get("parameters/StateMachine/playback")
	enemies = get_tree().get_nodes_in_group("enemies")
	player_no = get_tree().get_nodes_in_group("Player")
	staminabar.init_stamina(stamina)
	healthbar.init_health(health)
func _input(event):
	if event.is_action_pressed("1") and LeftHandItem != "CometSpear" and !attacking:
		prev_weapon = currentweapon
		LeftHandItem = "CometSpear"
		cometspear = spearScene.instantiate()
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.remove_child(prev_weapon)
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.add_child(cometspear)
		currentweapon = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.get_child(0)
		currentweapon.position = Vector3(0.279, 0.13, 0.0)
		currentweapon.rotation = Vector3(deg_to_rad(66), deg_to_rad(10), deg_to_rad(-73.4))
	if event.is_action_pressed("2") and LeftHandItem != "BoTRK" and !attacking:
		prev_weapon = currentweapon
		LeftHandItem = "BoTRK"
		botrk = botrkScene.instantiate()
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.remove_child(prev_weapon)
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.add_child(botrk)
		currentweapon = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.get_child(0)
		currentweapon.position = Vector3(-0.108, 0.1, -0.05)
		currentweapon.rotation = Vector3(deg_to_rad(-0.7), deg_to_rad(-12.4), deg_to_rad(-87.6))
	if event.is_action_pressed("0") and LeftHandItem != "Fists" and !attacking:
		prev_weapon = currentweapon
		LeftHandItem = "Fists"
		fists = fistScene.instantiate()
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.remove_child(prev_weapon)
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.add_child(fists)
		currentweapon = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.get_child(0)
	if event.is_action_pressed("Q"):
		if lockOn == false:
			lockOn = true
		elif lockOn == true:
			lockOn = false
	if event.is_action_pressed("Escape"):
		get_tree().quit()
		return
func _process(delta):

	print(LeftHandItem , animationTree.get_animation_player())
	if LeftHandItem == "Fists":
		$BaseModel3D/MeshInstance3D/AnimationTree.set_animation_player("../FistAnimPlayer")
	else:
		$BaseModel3D/MeshInstance3D/AnimationTree.set_animation_player("../AnimationPlayer")
	#print("prev: ", prev_weapon)
	current_state = state_machine.get_current_node()
	current_path = state_machine.get_travel_path()
	_handle_variables(delta)
	_handle_detection()

func _physics_process(delta):
	RMPos = animationTree.get_root_motion_position()
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_animations(delta)
	super(delta) # Call the parent class's _physics_process

func _handle_detection():
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
		$enemy_radar.rotation.y -= PI

func _handle_movement(delta):

	if global_position.y <= -5:
		state_machine.travel("death_01")
		#print("player fell off", player_no)
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
	if rotate_to_view == true and !lockOn and !attacking and !stunned:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.1)
	elif attacking and attack_timer >= attack_grace and !lockOn and !stunned and rotate_to_view == true:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.1)
	if input_dir.length() > 0 and !movement_lock and !instaslow and !staggered and is_on_floor():
		is_moving = true
		if lockOn == true:
			rotate_to_view = false
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.5)
		if !lockOn:
			rotate_to_view = true
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
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.1)
		
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
	var camattachment = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment
	$Camera.global_transform.origin.x = lerp($Camera.global_transform.origin.x, camattachment.global_transform.origin.x, 0.0125)
	$Camera.global_transform.origin.z = lerp($Camera.global_transform.origin.z, camattachment.global_transform.origin.z, 0.0125)
	if instaslow == true:
		$Camera.rotation.z = deg_to_rad(-2)
		$Camera.position.y = -0.1
	else:
		$Camera.rotation.z = 0
#		attackCompensation = 0.05
#	else: attackCompensation = 0.0
	if shift == true:
		shield_meter = 0
	if shield_meter > 0:
		shield_activation = true
	if shield_meter == 0:
		shield_activation = false
	if Input.is_action_just_pressed("emulate"):
		state_machine.travel("ULT")
	if damI < damI_cd:
		damI += delta
	#print(attackCompensation, attack_timer)
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
		speed_multiplier = 7.0
	else:
		speed_multiplier = 2.75

	# regen stamina.
	if time_since_stamina_used >= stamina_grace_period and stamina < max_stamina:
		stamina += delta * stamina_regeneration_rate

func _handle_animations(delta):
#	if is_moving == false and is_on_floor() and attacking == false and is_blocking == false:
#		state_machine.travel("idle")
#	if is_moving == true and is_on_floor() and attacking == false and is_blocking == false:
#		state_machine.travel("move")
	#print("Are we moving? ", is_moving, "  Are we blocking? ", is_blocking, "  Are we running? ", is_running, "  Inning? ", in_mode, "  SEX>", is_on_floor(), "  are we attacking? ", attacking)
	if is_moving == false and is_on_floor() and is_blocking == false and is_running == false and in_mode == true:
		#print("in")
		pass
	if is_moving == false and is_on_floor() and attacking == false and is_blocking == false and is_running == false and in_mode == false:
		pass
		#print("idle")
	if is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == false and speed < 4.8:
		#print("move")
		pass
	animationTree.set("parameters/StateMachine/conditions/in", !staggered and is_moving == false and is_on_floor() and is_running == false and in_mode == true and charge_attack == false)
	animationTree.set("parameters/StateMachine/conditions/idle", !staggered and is_moving == false and is_on_floor() and attacking == false and is_blocking == false and is_running == false and in_mode == false)
	animationTree.set("parameters/StateMachine/conditions/move", !staggered and is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == false and speed < 4.8)
	animationTree.set("parameters/StateMachine/conditions/run", !staggered and is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == true and speed >= 4.8)
	# Do anims.
	pass 

func _handle_combat(delta):
	print(currentweapon)
	var staggeranimhelper = 0
	if staggeranimhelper >= 1:
		staggeranimhelper += delta
	if staggeranimhelper >= 1:
		staggered = false
	if instaslow == false:
		animationTree.set("parameters/TimeScale/scale", 1)
	else:
		animationTree.set("parameters/TimeScale/scale", 0.01)
	#print("current weapon: ",currentweapon," hurting: ", currentweapon.Hurt)
	#print(in_mode)
	print("attack meter: ", attack_meter, "  current path: ", current_path, "  current state: ", current_state )
	if shift == true and is_on_floor() and is_blocking == false and is_running == false:
	#	state_machine.travel("in")
		in_mode = true
	else:
		in_mode = false
	#if is_moving and is_running == false and attacking == false:
		#state_machine.travel("walk")
	#print(attack_meter)
	if !is_blocking:
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D2/Shield/Area3D/CollisionShape3D.disabled = true
	elif current_state in ["shield_block_1", "shield_block_walk", "run_blocking"]:
		if damI >= 0:
			damI -= delta * 1.4
		if damI <= 0 and current_state == "shield_block_1":
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D2/Shield/Area3D/CollisionShape3D.disabled = false
	if damI >= damI_cd:
		canBeDamaged = true
	else:
		canBeDamaged = false
	#print("path:", current_path, "shift:", shift)
	#print("current state:", current_state)
	if !attacking:
		currentweapon.Hurt = false
	path_empty = true
	for path in current_path:
		if path != null:
			path_empty = false
			break
	match current_state: # Attack hurt frame code
		"Attack_bash":
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.1 && attack_timer < 0.375 ):
				offhand.Active = true
			else:
				offhand.Active = false
		"Attack_1":
			currentweapon.attack_multiplier = 1.5
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.3 && attack_timer < 0.4583 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.135
			else:
				currentweapon.Hurt = false
		"Attack_2":
			currentweapon.attack_multiplier = 1
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.3 && attack_timer < 0.5 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.180
			else:
				currentweapon.Hurt = false
		"Attack_3":
			currentweapon.attack_multiplier = 0.75
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.4 && attack_timer < 0.5417 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.125
			else:
				currentweapon.Hurt = false
		"Attack_4":
			currentweapon.attack_multiplier = 0.75
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.1 && attack_timer < 0.375 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.125
			else:
				currentweapon.Hurt = false
		"Attack_5":
			currentweapon.attack_multiplier = 2
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.4 && attack_timer < 0.5833 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.150
			else:
				currentweapon.Hurt = false
		"in_to_H_Attack_1":
			currentweapon.attack_multiplier = 3
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.515 && attack_timer < 0.875 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.350
			else:
				currentweapon.Hurt = false
		"H_Attack_2":
			currentweapon.attack_multiplier = 5
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.7 && attack_timer < 0.875 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.150
			else:
				currentweapon.Hurt = false
		"Attack_C_1":
			shield_activation = false
			attacking = false
			is_blocking = false
			is_running = false
			currentweapon.attack_multiplier = 1
			if instaslow == false:
				attack_timer += delta
			#print(attack_timer)
			if ( attack_timer >= 0.3 && attack_timer < 0.5) or ( attack_timer >= 0.7 && attack_timer < 0.993 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.200
			else:
				currentweapon.Hurt = false

	if currentweapon.Hurt == true:
		match current_state:
			"Attack_1":
				$Hit/A1t1.visible = true
			"Attack_2":
				$Hit/A2t1.visible = true
			"Attack_3":
				$Hit/A3t1.visible = true
			"Attack_4":
				$Hit/A4t1.visible = true
			"Attack_5":
				$Hit/A5t2.visible = true
	else:
		$Hit/A1t1.visible = false
		$Hit/A2t1.visible = false
		$Hit/A3t1.visible = false
		$Hit/A4t1.visible = false
		$Hit/A5t2.visible = false
	if shield_activation and !is_moving and !attacking and !is_running and !stunned:
		#print("shield block 1")
		state_machine.travel("shield_block_1")
		if current_state == "shield_block_1":
			is_blocking = true
	if shield_activation and is_moving and !attacking and !is_running and !stunned:
		state_machine.travel("shield_block_walk")
		is_blocking = true
	if shield_activation and is_moving and !attacking and is_running and !stunned:
		state_machine.travel("run_blocking")
		is_blocking = true
	if current_state != "shield_block_1" and current_state != "shield_block_walk" and current_state != "run_blocking" or shield_activation == false:
		is_blocking = false
	if time_since_engage <= 10:
		time_since_engage += delta
	movement_lock = current_state in ["Light_Damaged_L","Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_C_1", "Attack_C_1_bash", "death_01", "Attack_bash", "in_to_H_Attack_1", "H_Attack_2"] or stunned

	#print(shield_activation, shield_meter, "WOHOOO", is_blocking, attacking)
	if Input.is_action_just_pressed("RightClick"):
		rightclick = true
		if current_state != "shield_block_1" and current_state != "Attack_bash" and Input.is_action_pressed("shiftKey"):
				shift = true

	if Input.is_action_pressed("RightClick") and !stunned and rightclick:
		shield_meter += delta
		if shift == true:
			state_machine.travel("Attack_bash")
			stunned = true
	if Input.is_action_pressed("RightClick") and !stunned:
		#print(rightclick , shield_meter , shift)
		pass

	if Input.is_action_just_released("RightClick"):
		shield_meter = 0
		rightclick = false


	if Input.is_action_just_pressed("shiftKey"):
		shift = true
		#if current_state == "idle":
	if Input.is_action_just_released("shiftKey"):
		shift = false


	if Input.is_action_just_pressed("LeftClick"):
		leftclick = true
	if Input.is_action_pressed("LeftClick") and !stunned and leftclick:
		attack_meter += delta

	if Input.is_action_pressed("LeftClick") and !stunned:
		#print(leftclick)
		if attack_meter >= 0.25 and leftclick:
			attack_meter = 0.0
			attacking = true
			state_machine.travel("Attack_C_1")
			charge_attack = true
			if current_state == "Attack_C_1":
				attack_buffer = 101
			#print("charge_attack_placeholder")
			currentweapon.guard_break = true
			time_since_engage = 0
			leftclick = false
	else:
		attack_meter = 0
	#print(weaponCollidingWall, attacking, currentweapon.Hurt)
	if weaponCollidingWall and attacking and currentweapon.Hurt == true:
		stunned = true
		attacking = false
		state_machine.travel("hit_cancel")

	if Input.is_action_just_released("LeftClick") and leftclick == true:
		handle_attack_release()

func handle_attack_release():
	if attack_meter < 0.5 and time_since_engage >= attack_grace and !stunned:
		#print(attacking, "MUST ATTACK", "buffer?", attack_buffer)
		time_since_engage = 0
		if current_state == "Attack_C_1":
			if in_mode == false:
				attack_buffer = 102
			if in_mode == true:
				attack_buffer = 200
		if in_mode == true and current_state != "H_Attack_2" and current_state != "H_Attack_2_to_in":
			if current_state == "Attack_1":
				attack_buffer = 200
				attacking = true
			if current_state != "Attack_1" and attacking == false and current_state != "Attack_C_1":
				attacking = true
				state_machine.travel("in_to_H_Attack_1")
		if current_state in ["idle", "walk", "run", "walk_to_idle", "idle_to_walk", "attack_5_to_idle", "shield_block_1_to_idle", "Attack_C_1_to_idle", "Attack_bash"] and in_mode == false:
			attacking = true
			state_machine.travel("Attack_1")
		match current_state:
			"in_to_H_Attack_1":
				if in_mode == false:
					attack_buffer = 10
				if in_mode:
					attack_buffer = 201
			"H_Attack_1_to_in":
				if in_mode == false:
					attacking = true
					state_machine.travel("Attack_1")
				if in_mode:
					state_machine.travel("H_Attack_2")
					attacking = true
			"Attack_1":
				if !in_mode:
					attack_buffer = 1
				if in_mode:
					attack_buffer = 200
			"Attack_1_to_idle":
				if in_mode == false:
					state_machine.travel("Attack_2")
					attacking = true
				if in_mode:
					state_machine.travel("in_to_H_Attack_1")
					attacking = true
			"Attack_2":
				if !in_mode:
					attack_buffer = 2
				if in_mode:
					attack_buffer = 200
			"Attack_2_to_idle":
				if in_mode == false:
					state_machine.travel("Attack_3")
					attacking = true
				if in_mode:
					state_machine.travel("in_to_H_Attack_1")
					attacking = true
			"Attack_3":
				if !in_mode:
					attack_buffer = 3
				if in_mode:
					attack_buffer = 200
			"Attack_3_to_idle":
				if in_mode == false:
					state_machine.travel("Attack_4")
					attacking = true
				if in_mode:
					state_machine.travel("in_to_H_Attack_1")
					attacking = true
			"Attack_4":
				if !in_mode:
					attack_buffer = 4
				if in_mode:
					attack_buffer = 200
			"Attack_4_to_idle":
				if in_mode == false:
					state_machine.travel("Attack_5")
					attacking = true
				if in_mode:
					state_machine.travel("in_to_H_Attack_1")
					attacking = true
			"Attack_CA_1":
				if in_mode:
					attack_buffer = 200
		#print(attacking, "NEW MUST ATTACK", "new buffer", attack_buffer)
	attack_meter = 0
	leftclick = false

func _on_animation_tree_animation_started(anim_name):
	if anim_name in ["Attack_1_to_idle", "Attack_2_to_idle", "Attack_3_to_idle", "Attack_4_to_idle", "Attack_5_to_idle", "Attack_6_to_idle", "H_Attack_1_to_in", "H_Attack_2_to_in"]:
		attacking = false
	match anim_name:
		"in_to_H_Attack_1":
			attacking = true
			attack_timer = 0
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
		"Attack_C_1":
			attacking = true
			attack_timer = 0
		"Attack_bash":
			attack_timer = 0
		"Attack_1_to_idle":
			if attack_buffer == 1 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_2")
				attack_buffer = 0
		"Attack_2_to_idle":
			if attack_buffer == 2 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_3")
				attack_buffer = 0
		"Attack_3_to_idle":
			if attack_buffer == 3 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_4")
				attack_buffer = 0
		"Attack_4_to_idle":
			if attack_buffer == 4 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_5")
				attack_buffer = 0
		"H_Attack_1_to_in":
			if attack_buffer == 201 and !weaponCollidingWall:
				state_machine.travel("H_Attack_2")
				attack_buffer = 0
			if attack_buffer == 10 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_1")
				attack_buffer = 0
func _on_animation_tree_animation_finished(anim_name):
	#if !lockOn:
	#	rotate_to_view = true
	if lockOn and anim_name in ["Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6"]:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.75)
	match anim_name:
		"Light_Damaged_L":
			staggered = false
			movement_lock = false
			attacking = false
			stunned = false
			is_moving = false
			attacking = false
			is_blocking = false
			is_running = false
			in_mode = false
			leftclick = false
			rightclick = false
			shield_activation = false
			charge_attack = false
		"in_to_H_Attack_1":
			attack_timer = 0
			if attack_buffer == 10 and !weaponCollidingWall:
				state_machine.travel("Attack_1")
				attack_buffer = 0
			elif attack_buffer == 201 and !weaponCollidingWall:
				state_machine.travel("H_Attack_2")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("H_Attack_1_to_in")
		"in_to_H_Attack_2":
			attack_timer = 0
			if attack_buffer == 202 and !weaponCollidingWall:
				state_machine.travel("H_Attack_3")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("H_Attack_2_to_in")
		"Attack_1":
			attack_timer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			if attack_buffer == 1 and !weaponCollidingWall:
				state_machine.travel("Attack_2")
				attack_buffer = 0
			else:
				if !stunned and current_state == "Attack_1":
					state_machine.travel("Attack_1_to_idle")
		"Attack_2":
			attack_timer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			if attack_buffer == 2 and !weaponCollidingWall:
				state_machine.travel("Attack_3")
				attack_buffer = 0
			else:
				if !stunned and current_state == "Attack_2":
					state_machine.travel("Attack_2_to_idle")
		"Attack_3":
			attack_timer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			if attack_buffer == 3 and !weaponCollidingWall:
				state_machine.travel("Attack_4")
				attack_buffer = 0
			else:
				if !stunned and current_state == "Attack_3":
					state_machine.travel("Attack_3_to_idle")
		"Attack_4":
			attack_timer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			if attack_buffer == 4 and !weaponCollidingWall:
				state_machine.travel("Attack_5")
				attack_buffer = 0
			else:
				if !stunned and current_state == "Attack_4":
					state_machine.travel("Attack_4_to_idle")
		"Attack_5":
			attack_timer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			if attack_buffer == 5 and !weaponCollidingWall:
				state_machine.travel("Attack_6")
				attack_buffer = 0
			else:
				if !stunned and current_state == "Attack_5":
					state_machine.travel("Attack_5_to_idle")
		"Attack_6":
			attack_timer = 0
			if !stunned and current_state == "Attack_5":
				state_machine.travel("Attack_5_to_idle")
		"hit_cancel":
			state_machine.travel("idle")
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
		"Attack_C_1":
			charge_attack = false
			attack_timer = 0
			if attack_buffer == 101:
				state_machine.travel("Attack_C_1")
				attack_buffer = 0
			if attack_buffer == 102:
				state_machine.travel("Attack_1")
				attack_buffer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			attacking = false
			currentweapon.guard_break = false
		"death_01":
			stunned = false
			player_death(0)
		"Attack_bash":
			stunned = false
			shift = false
			attack_timer = 0
			attacking = false
			attack_buffer = 0
#				shift = false
	#			is_blocking = true
	#			print("BLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsexBLOCKsex")
#func _on_hitbox_area_entered(area):
	#if area.is_in_group("walls"):
		#weaponCollidingWall = true
#func _on_hitbox_area_exited(area):
	#if area.is_in_group("walls"):
		#weaponCollidingWall = false

# # # # # #

func player_death(x):
	staggered = false
	global_position = Vector3(0,3,0)
	player_no[x].reset()
	is_moving = false
	attacking = false
	is_blocking = false
	is_running = false
	healthbar.health = health

func damage_by(damaged: int, side = 1):
	#print("damaged you are")
	if side == 1 and canBeDamaged:
		staggered = true
	#	_animationPlayer.play("Light_Damaged_L")
		state_machine.start("Light_Damaged_L")
	if health <= 0:
		stunned = true
		state_machine.stop()
		state_machine.travel("death_01")
		health = 0
	if canBeDamaged:
		health -= damaged
	damI = 0.0
	healthbar.health = health


func guard_break():
	if is_blocking:
		state_machine.travel("hit_cancel")
		is_blocking = false



