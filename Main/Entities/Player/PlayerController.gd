extends Character

class_name PlayerController

var MOVE_BOOL : bool = !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 4.8 and is_on_floor()
var IDLE_BOOL : bool = velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false
var killed := 1.0
@export var ability_1 : String
@export var ability_2 : String
@export var ability_3 : String
@export var ult : String
var in_menu := false
var two_fps_counter := 0.0
var throwing := false
@export var max_lock_range : float = 25.0
@export var raycast_ground : RayCast3D

var player_no: Array #a mechanic that may help me later on. What? planning to add multiplayer? lol
@onready var LHI_bone = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
#@onready var _animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
var state_machine
var current_state
@onready var cam = $Camera/Camera3D
@onready var staminabar = $HUD/StaminaBar
@onready var healthbar = $HUD/HealthBar
var speed_multiplier = 1.0
var target_rotation: float = 0.0
var global_dir = 0
var attack_meter: float = 0.0
var shield_meter: float = 0.0
var leftclick = false
var rightclick = false
var lockOn = false
var enemies = []
var closest_enemy
var closest_enemy_body
var current_path := []
var speed
var time_since_actionbar_halt = 0.3
var stored_velocity: Vector3

var rotate_to_view = true
var shift := false
var path_empty := true
var in_mode := false
var shield_activation := false
var charge_attack := false
var lhi = 1
var currentanimplayer
var prev_weapon
var throwable
var cometspear
var botrk
var fists
#var x: float
var y: float
var z: float
var fps = Engine.get_frames_per_second()
var trail_switch = false
var conqueror_stacks := 0.1
var is_jumping := false
var jump_start_pos
var jump_time : float
var jump_buffer := 0.0
var jump_activation : bool
var time_since_jump_buffer : float
var distance_to_ground : float
var is_on_air := false

var throw_timer := 0.0
func _ready():
	Engine.time_scale = 1.0
	if currentweapon == null:
		LeftHandItem = "Fists"
		fists = fistScene.instantiate()
		LHI_bone.add_child(fists)
		currentweapon = LHI_bone.get_child(0)
		animationTree.set_animation_player("../FistAnimPlayer") 
		prev_weapon = currentweapon

	state_machine = animationTree.get("parameters/StateMachine/playback")
	enemies = get_tree().get_nodes_in_group("enemies")
	player_no = get_tree().get_nodes_in_group("Player")
	staminabar.init_stamina(stamina)
	healthbar.init_health(health)
func _input(event):
	if event.is_action_pressed("ABILITY_1"):
		match ability_1:
			"hop":
				
				state_machine.travel("ability_1")
	if event.is_action_pressed("ABILITY_2"):
		match ability_2:
			"spring":
				print("sniff")
	if event.is_action_pressed("ABILITY_3"):
		match ability_3:
			"bomboclat":
				print("uohh")
	
	
	
	
	
	
	
	if event.is_action_pressed("x"):
		if throwing == true:
			state_machine.travel("throw")
	if event.is_action_pressed("R"):
		throwing = not throwing
		if LeftHandItem == "CometSpear" and throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.45
			currentweapon.position = Vector3(0.28, 0.1, -0.04)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
		if LeftHandItem == "CometSpear" and throwing == true:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.5
			currentweapon.position = Vector3(-0.02, 0.078, -0.03)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))

	if event.is_action_pressed("1") and LeftHandItem != "CometSpear" and !attacking:
		set_weapon("CometSpear")
	if event.is_action_pressed("2") and LeftHandItem != "BoTRK" and !attacking:
		set_weapon("BoTRK")
	if event.is_action_pressed("0") and LeftHandItem != "Fists" and !attacking:
		set_weapon("Fist")
	if event.is_action_pressed("Q"):
		if lockOn == false and closest_enemy and closest_enemy.global_position.distance_to(global_position) < max_lock_range:
			lockOn = true
		elif lockOn == true:
			$view.global_rotation.y = $BaseModel3D.global_rotation.y
			lockOn = false
	#if event.is_action_pressed("Escape"):
		#get_tree().quit()
		return
func _process(delta):
	if two_fps_counter < 0.5:
		two_fps_counter += delta
	if two_fps_counter >= 0.5:
		two_fps()
		two_fps_counter = 0
	#$Throw_test.global_rotation = $BaseModel3D/MeshInstance3D.global_rotation
	#$Throw_test.global_position = $Thrown.global_position
	#print($BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence)
	IDLE_BOOL = velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false
	MOVE_BOOL = !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 4.8 and is_on_floor()
	if MOVE_BOOL == true:
		animationTree.set("parameters/StateMachine/blend1d/blend_position", 1)
		animationTree.set("parameters/StateMachine/blend1d2/blend_position", 1)
	elif IDLE_BOOL == true:
		animationTree.set("parameters/StateMachine/blend1d/blend_position", -1)
		animationTree.set("parameters/StateMachine/blend1d2/blend_position", -1)
	#print(global_dir)
	#$BaseModel3D.set_quaternion($BaseModel3D.get_quaternion() * animationTree.get_root_motion_rotation())
	RMPos =  (animationTree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()) * animationTree.get_root_motion_position()
	if current_state == "ability_1":
		velocity = Vector3.ZERO
	if current_state != "walk_to_jump" and current_state != "idle_to_jump":
		global_position.y += RMPos.y
		global_position += $BaseModel3D.global_transform.basis * RMPos
	elif global_dir != Vector2(0,0):
		global_position += $BaseModel3D.global_transform.basis * RMPos
	if LeftHandItem == "Fists":
		animationTree.set_animation_player("../FistAnimPlayer")
	else:
		animationTree.set_animation_player("../AnimationPlayer")

	if raycast_ground.is_colliding():
		distance_to_ground = global_position.distance_to(raycast_ground.get_collision_point())
	else:
		distance_to_ground = 100
	if distance_to_ground < 1.01 and velocity.y <= 0:
		is_on_air = false
	current_state = state_machine.get_current_node()
	current_path = state_machine.get_travel_path()
	_handle_variables(delta)
	_handle_detection()
func _physics_process(delta):
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_animations(delta)
	super(delta)

func _handle_detection():
	var closest_distance = INF
	"res://Main/PlayerV2/Player.tscn"
	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy_body = enemy
	#print(closest_enemy_body)
	if closest_enemy != null:
		$enemy_radar.look_at(closest_enemy.global_transform.origin, Vector3.UP)
		$enemy_radar.rotation.y -= PI
		$enemy_radar.rotation.y = wrapf($enemy_radar.rotation.y, -PI, PI)


func _handle_movement(delta):
	move_and_slide()
	if velocity.y <= 0 and current_state == "walk_to_jump" and is_on_floor() and jump_time > 0.2667:
		state_machine.travel("jump_to_walk")
	raycast_ground.global_rotation_degrees.y += 15
	wrapf(raycast_ground.global_rotation_degrees.y, -360, 360)
	#if is_on_air == true:
		#velocity.x = velocity.x / 0.9
		#velocity.z = velocity.z / 0.9
	if global_position.y <= -5:
		state_machine.travel("death_01")
	if Input.is_action_pressed("emulate"):
		ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", "true")
		ProjectSettings.save()
	var spd : float = velocity.length();
	speed = spd
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	global_dir = input_dir
	var camera_direction: Vector3 = ($Camera/view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var character_direction = $view.transform.basis.z.normalized()
	target_rotation = atan2(camera_direction.x, camera_direction.z)
	
	var bone_rot = $UpperBody_skewer.rotation

	if lockOn:
		if throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.0
		bone_rot = $enemy_radar.rotation
	else:
		if throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.45
		if abs($UpperBody_skewer.rotation.y) >= PI / 2:
			bone_rot.y =  $UpperBody_skewer_true.global_rotation.y
		elif abs($UpperBody_skewer.rotation.y) <= PI / 2:
			bone_rot.y = $Camera/Camera3D.rotation.y - PI

	bone_rot.x = -$Camera/Camera3D.rotation.x
	bone_rot -= $BaseModel3D.rotation
	bone_rot.y = wrapf(bone_rot.y, -PI, PI)
	#bone_rot.y = clamp(bone_rot.y, -PI/2, PI/2)
	if throwing == true:
		if lockOn == false:
			rotate_to_view = false
		bone_rot.y = $UpperBody_skewer_true.global_rotation.y
		$UpperBody_skewer.global_rotation.y = $UpperBody_skewer_true.global_rotation.y
	if abs(bone_rot.y) >= PI / 2:
		bone_rot.y = $UpperBody_skewer_true.global_rotation.y
	# Smooth interpolation
	$UpperBody_skewer.rotation = $UpperBody_skewer.rotation.lerp(bone_rot, 0.1)
	
	if attacking == true:
		$UpperBody_skewer.global_rotation.y = $UpperBody_skewer_true.global_rotation.y
	if rotate_to_view == true and !attacking and !stunned:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.1)
	elif attacking and attack_timer >= attack_grace and !lockOn and !stunned and rotate_to_view == true:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.1)
	if lockOn == true and is_running == false and is_rolling == false and in_menu == false:
		#print("wow")
		rotate_to_view = false
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.5)
	if lockOn == false or is_running == true and is_rolling == true and in_menu == false:
		rotate_to_view = true
		#print("dont wow")

	if input_dir.length() > 0 and !movement_lock and !instaslow and !staggered and is_on_floor() and in_menu == false:
		is_moving = true
		if Input.is_action_pressed("moveForward") and Input.is_action_pressed("moveLeft") and !lockOn:
			$UpperBody_skewer.rotation.z = lerp_angle($UpperBody_skewer.rotation.z, -PI / 8, 0.1)
		elif Input.is_action_pressed("moveForward") and Input.is_action_pressed("moveRight") and !lockOn:
			$UpperBody_skewer.rotation.z = lerp_angle($UpperBody_skewer.rotation.z, PI / 8, 0.1)
		else:
			$UpperBody_skewer.rotation.z = lerp_angle($UpperBody_skewer.rotation.z, 0.0, 0.1)
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.2)
		velocity = lerp(velocity, character_direction * speed_multiplier, 0.075)
		stored_velocity = velocity
	elif is_on_floor():
		is_moving = false
		velocity.x = lerpf(velocity.x, 0, 0.3)
		velocity.z = lerpf(velocity.z, 0, 0.3)
	#print(is_on_air)
	#if global_dir == Vector2(0,0) and current_state in ["jump_to_walk", "jump_to_idle"]:
		#velocity.x = lerpf(velocity.x, 0, 0.02)
		#velocity.z = lerpf(velocity.z, 0, 0.02)
		#print(velocity)
	elif is_on_air:
	#	$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.04)
		velocity.x = lerp(velocity.x, character_direction.x * speed_multiplier, 0.1)
		velocity.z = lerp(velocity.z, character_direction.z * speed_multiplier, 0.1)
	#var current_rotation := transform.basis.get_rotation_quaternion().normalized()

	if movement_lock and attacking and input_dir.length() > 0:
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.1)
		
	if Input.is_action_pressed("SpaceBar") and is_on_floor():
		action_bar += 1
		time_since_actionbar_halt = 0

	if jump_buffer == 1.0 and current_state in ["idle", "walk", "idle_to_walk", "walk_to_idle"] or jump_buffer == 1.0 and is_on_floor() and current_state in ["jump_to_walk", "jump_to_idle", "run_to_idle"]:
		if !staggered and is_moving == false and is_on_floor() and attacking == false and is_blocking == false and is_running == false and in_mode == false:
			state_machine.travel("idle_to_jump")
		if !staggered and is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == false:
			state_machine.travel("walk_to_jump")
		jump_time = 0
		jump_start_pos = global_position.y
		is_jumping = true
		action_bar = 0
		jump_buffer = 0
		jump_activation = true
		
	if jump_activation == true:
		jump_time = delta + jump_time
		if jump_time > 0.2667 and is_on_floor() and velocity.y >= 0.0:
			velocity.y = 3.0
			#print("velytrue")
			is_on_air = true
			is_jumping = false
			jump_activation = false

	if distance_to_ground > 2.0:
		#print("flyingtrue")
		is_on_air = true
	if Input.is_action_just_released("SpaceBar") and action_bar < 20 and is_on_floor():
		damI_cd = 1.0
		damI = 0.0
		state_machine.travel("Roll")
		action_bar = 0
func _handle_variables(delta):
	if throwing == true:
		if lockOn == false:
			$Thrown_target.look_at($Camera/Camera3D/pivot/RayCast3D/MeshInstance3D.global_position)
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $Thrown_target.rotation.y - PI, 0.5)
	#$Throw_test.global_rotation = $BaseModel3D/MeshInstance3D.global_rotation
	var camattachment = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment
	var camAttTO = camattachment.global_transform.origin
	var cam3dTO = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment/right.global_transform.origin
	if throwing == false:
		$Camera/view_anchor.spring_length = 3.5
		$Camera.global_transform.origin.x = lerp($Camera.global_transform.origin.x, camattachment.global_transform.origin.x, 0.0125)
		$Camera.global_transform.origin.z = lerp($Camera.global_transform.origin.z, camattachment.global_transform.origin.z, 0.0125)
	else:
		$Camera/view_anchor.spring_length = 2.0
		$BaseModel3D.global_rotation_degrees.y += -10 * delta
		$Camera.global_transform.origin = lerp($Camera.global_transform.origin, cam3dTO, 0.0125)
	if instaslow == true:
		if in_menu == false:
			$Camera/Camera3D.rotation.z = lerp($Camera/Camera3D.rotation.z, deg_to_rad(randf_range(-4.0, 4.0)), 0.5)
		$Camera.position.y = -0.1
	else:
		$Camera.rotation.z = 0
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
	if time_since_actionbar_halt < 0.3:
		time_since_actionbar_halt += delta
	if time_since_actionbar_halt >= 0.3:
		action_bar = 0
	if time_since_stamina_used < stamina_grace_period:
		time_since_stamina_used += delta
	if stamina < 0:
		stamina = 0
	staminabar.stamina = stamina

	if Input.is_action_just_pressed("SpaceBar") and action_bar >= 20 or Input.is_action_just_pressed("B") and is_jumping == false:
		jump_buffer = 1.0
		time_since_jump_buffer = 0.0
	if time_since_jump_buffer < 0.35:
		time_since_jump_buffer += delta
	if jump_buffer == 1.0 and time_since_jump_buffer >= 0.35:
		jump_buffer = 0.0

	#RUNNING
	if action_bar > 20 and stamina > 1 and is_moving:
		is_running = true
		stamina -= delta * stamina_drain_rate
		time_since_stamina_used = 0
	else:
		is_running = false

	if is_running == true:
		speed_multiplier = 3.5
	elif throwing == true:
		speed_multiplier = 0.75
	else:
		speed_multiplier = 1.5
	# regen stamina.
	if time_since_stamina_used >= stamina_grace_period and stamina < max_stamina:
		stamina += delta * stamina_regeneration_rate
	$"BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/helmet mesh".get_active_material(0).set_shader_parameter("conqueror", conqueror_stacks)
	if time_since_engage < 3 and trail_switch == false:
		currentweapon.attack_init()
		trail_switch = true
	if time_since_engage >= 3 and trail_switch == true:
		currentweapon.attack_end()
		trail_switch = false
	if time_since_engage >= 3 and conqueror_stacks > 0.1:
		conqueror_stacks = lerp(conqueror_stacks, 0.0, delta / 10)
	#print(current_state, current_path)
func _handle_animations(_delta):
	#print(distance_to_ground)
	#if distance_to_ground < 0.75 and velocity.y <= 0:
		#is_on_air = false

	if attacking == false and is_blocking == false and is_running == true and speed >= 3.5:
		print("ran")
	if is_moving == false and is_on_floor() and attacking == false and is_blocking == false and is_running == false and in_mode == false:
		pass
	if is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == false and speed < 4.8:
		pass
	animationTree.set("parameters/StateMachine/conditions/in", throwing == false and velocity.y <= 0 and !staggered and is_moving == false and is_on_floor() and is_running == false and in_mode == true and charge_attack == false)
	animationTree.set("parameters/StateMachine/conditions/idle", throwing == false and velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false)
	#animationTree.set("parameters/StateMachine/conditions/idlent", throwing == false and velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false)
	animationTree.set("parameters/StateMachine/conditions/move", throwing == false and !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 3.0 and is_on_floor())
	#animationTree.set("parameters/StateMachine/conditions/movent", throwing == false and !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 4.8 and is_on_floor())
	
	animationTree.set("parameters/StateMachine/conditions/run", throwing == false and !staggered and is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == true and speed >= 3.0)
	animationTree.set("parameters/StateMachine/conditions/throw", throwing == true)
	#print(is_on_floor())
	pass 

func _handle_combat(delta):
	var staggeranimhelper = 0
	if staggeranimhelper >= 1:
		staggeranimhelper += delta
	if staggeranimhelper >= 1:
		staggered = false
	if instaslow == false:
		animationTree.set("parameters/TimeScale/scale", 1)
	else:
		animationTree.set("parameters/TimeScale/scale", 0.01)
	if shift == true and is_on_floor() and is_blocking == false and is_running == false:
		in_mode = true
	else:
		in_mode = false
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
	if !attacking:
		currentweapon.Hurt = false
	
	match current_state: # Attack hurt frame code AND DEATH!!!! YARRR GRRRRR DEATHHH!!!
		"throw":
			throw_timer += delta
			if throw_timer >= 0.2916666666666667:
				throw_weapon()
				throw_timer = 0.0
		"death_01":
			damI = 0
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
			if ( attack_timer >= 0.3 && attack_timer < 0.4583 ):
				currentweapon.hit(1)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.135
			else:
				currentweapon.Hurt = false
		"Attack_2":
			currentweapon.attack_multiplier = 1
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.3 && attack_timer < 0.5 ):
				currentweapon.hit(2)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.180
			else:
				currentweapon.Hurt = false
		"Attack_3":
			currentweapon.attack_multiplier = 0.75
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.4 && attack_timer < 0.5417 ):
				currentweapon.hit(3)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.125
			else:
				currentweapon.Hurt = false
		"Attack_4":
			currentweapon.attack_multiplier = 0.75
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.1 && attack_timer < 0.375 ):
				currentweapon.hit(4)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.125
			else:
				currentweapon.Hurt = false
		"Attack_5":
			currentweapon.attack_multiplier = 2
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.4 && attack_timer < 0.5833 ):
				currentweapon.hit(2)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.150
			else:
				currentweapon.Hurt = false
		"in_to_H_Attack_1":
			currentweapon.attack_multiplier = 3
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.515 && attack_timer < 0.875 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.350
			else:
				currentweapon.Hurt = false
		"H_Attack_2":
			currentweapon.attack_multiplier = 5
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.7 && attack_timer < 0.875 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.150
			else:
				currentweapon.Hurt = false
		"Attack_roll":
			currentweapon.attack_multiplier = 3
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.4333 && attack_timer < 0.6667 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.200
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
			if ( attack_timer >= 0.3 && attack_timer < 0.5) or ( attack_timer >= 0.7 && attack_timer < 0.993 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.200
			else:
				currentweapon.Hurt = false
	if current_state != "throw":
		throw_timer = 0.0
	if !throwing and shield_activation and !is_moving and !attacking and !is_running and !stunned:
		state_machine.travel("shield_block_1")
		if current_state == "shield_block_1":
			is_blocking = true
	if !throwing and shield_activation and is_moving and !attacking and !is_running and !stunned:
		state_machine.travel("shield_block_walk")
		is_blocking = true
	if !throwing and shield_activation and is_moving and !attacking and is_running and !stunned:
		state_machine.travel("run_blocking")
		is_blocking = true
	if throwing and current_state != "shield_block_1" and current_state != "shield_block_walk" and current_state != "run_blocking" or shield_activation == false:
		is_blocking = false
	if time_since_engage <= 10:
		time_since_engage += delta
#abilities and attacks "required" to put here V V V WARNING
	movement_lock = current_state in ["Light_Damaged_L","Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1", "Attack_C_1_bash", "death_01", "Attack_bash", "in_to_H_Attack_1", "H_Attack_2", "throw", "ability_1"] or stunned

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
		pass

	if Input.is_action_just_released("RightClick"):
		shield_meter = 0
		rightclick = false


	if Input.is_action_just_pressed("shiftKey"):
		shift = true
	if Input.is_action_just_released("shiftKey"):
		shift = false

	if Input.is_action_just_pressed("LeftClick"):
		leftclick = true
	if Input.is_action_pressed("LeftClick") and !stunned and leftclick:
		attack_meter += delta

	if Input.is_action_pressed("LeftClick") and !stunned:
		if attack_meter >= 0.25 and leftclick:
			attack_meter = 0.0
			attacking = true
			state_machine.travel("Attack_C_1")
			charge_attack = true
			if current_state == "Attack_C_1":
				attack_buffer = 101
			currentweapon.guard_break = true
			time_since_engage = 0
			leftclick = false
	else:
		attack_meter = 0
	if weaponCollidingWall and attacking and currentweapon.Hurt == true:
		stunned = true
		attacking = false
		state_machine.travel("hit_cancel")

	if Input.is_action_just_released("LeftClick") and leftclick == true:
		handle_attack_release()

func handle_attack_release():
	if attack_meter < 0.5 and time_since_engage >= attack_grace and !stunned:
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
		if current_state in ["idle", "walk", "run", "walk_to_idle", "idle_to_walk", "attack_5_to_idle", "shield_block_1_to_idle", "Attack_roll_to_idle","Attack_C_1_to_idle", "Attack_bash"] and in_mode == false:
			attacking = true
			state_machine.travel("Attack_1")
		if current_state in ["Roll", "roll_to_idle", "roll_to_walk"]:
			state_machine.travel("Attack_roll")
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
			"Attack_roll":
				if !in_mode:
					attack_buffer = 999
				if in_mode:
					attack_buffer = 200
			"Attack_roll_to_idle":
				if in_mode == false:
					state_machine.travel("Attack_1")
					attacking = true
				if in_mode:
					state_machine.travel("in_to_H_Attack_1")
					attacking = true
			"Attack_CA_1":
				if in_mode:
					attack_buffer = 200
	attack_meter = 0
	leftclick = false

func _on_animation_tree_animation_started(anim_name):
	if lockOn and anim_name in ["Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll"]:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.75)
	if anim_name in ["Attack_1_to_idle", "Attack_2_to_idle", "Attack_3_to_idle", "Attack_4_to_idle", "Attack_5_to_idle", "Attack_6_to_idle", "Attack_roll_to_idle", "H_Attack_1_to_in", "H_Attack_2_to_in"]:
		attacking = false
	if anim_name in ["H_Attack_2", "in_to_H_Attack_1", "Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1", "Attack_bash"]:
#		print("SWOOOSH! BITCH!!!")
		attacking = true
		attack_timer = 0
	match anim_name:
		"H_Attack_2":
			attacking = true
			attack_timer = 0
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
		"Attack_roll":
			attacking = true
			attack_timer = 0
		"Attack_C_1":
			attacking = true
			attack_timer = 0
		"Attack_bash":
			#attacking = true # EXPERIMENTAL. DELETE IF BUG DANGER ALERT FIXME ATTENTION CRITICAL HACK
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
		"Attack_roll_to_idle":
			if attack_buffer == 999 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_1")
				attack_buffer = 0
		"H_Attack_1_to_in":
			if attack_buffer == 201 and !weaponCollidingWall:
				state_machine.travel("H_Attack_2")
				attack_buffer = 0
			if attack_buffer == 10 and !weaponCollidingWall and in_mode == false:
				state_machine.travel("Attack_1")
				attack_buffer = 0
		"throw":
			throw_timer = 0.0
		"Roll":
			throwing = false
			rotate_to_view = true
			is_rolling = true
func _on_animation_tree_animation_finished(anim_name):
	if lockOn and anim_name in ["Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6"]:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.75)
	if anim_name in ["H_Attack_2", "in_to_H_Attack_1", "Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1", "Attack_bash"]:
		pass
	match anim_name:
		"jump_to_idle":
			is_jumping = false
		"jump_to_walk":
			is_jumping = false
		"Light_Damaged_L":
			throwing = false
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
			conqueror_stacks += 0.1
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
			conqueror_stacks += 0.1
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
			conqueror_stacks += 0.1
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
			conqueror_stacks += 0.1
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
			conqueror_stacks += 0.1
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
		"Attack_roll":
			conqueror_stacks += 0.1
			attack_timer = 0
			if attack_buffer == 200 and !weaponCollidingWall:
				state_machine.travel("in_to_H_Attack_1")
				attack_buffer = 0
			if attack_buffer == 999 and !weaponCollidingWall:
				state_machine.travel("Attack_1")
				attack_buffer = 0
			else:
				if !stunned and current_state == "Attack_roll":
					state_machine.travel("Attack_roll_to_idle")
		"hit_cancel":
			state_machine.travel("idle")
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
		"Attack_C_1":
			conqueror_stacks += 0.2
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
		"Roll":
			damI_cd = 0.08
			rotate_to_view = false
			is_rolling = false
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
	if side == 1 and canBeDamaged:
		staggered = true
		throwing = false
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

func throw_weapon():
	var thrown_weapon = null
	throwable = throwableScene.instantiate()
	add_child(throwable)
	if lockOn == true:
		throwable.target = closest_enemy
	throwable.linear_velocity = Vector3.ZERO
	throwable.angular_velocity = Vector3.ZERO
	throwable.global_rotation = $BaseModel3D.global_rotation
	throwable.global_rotation.x += $UpperBody_skewer.global_rotation.x / 1.6
	#$Throw_test.global_rotation.x = 0
	throwable.global_position = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.global_position
	thrown_weapon = currentweapon
	currentweapon.attack_multiplier = 10
	currentweapon.my_owner = self
	currentweapon.reparent(throwable, true)
	set_weapon("Fist")
	var impulse = throwable.global_transform.basis.z * cam.strength * 5 # Forward is -Z in Godot
	throwable.apply_central_impulse(impulse)
	thrown_weapon.thrown = true
func set_weapon(weapon_name):
	match weapon_name:
		"Fist":
			prev_weapon = currentweapon
			LeftHandItem = "Fists"
			fists = fistScene.instantiate()
			LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(fists)
			currentweapon = LHI_bone.get_child(0)
		"BoTRK":
			prev_weapon = currentweapon
			LeftHandItem = "BoTRK"
			botrk = botrkScene.instantiate()
			LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(botrk)
			currentweapon = LHI_bone.get_child(0)
			currentweapon.position = Vector3(-0.108, 0.1, -0.05)
			currentweapon.rotation = Vector3(deg_to_rad(-0.7), deg_to_rad(-12.4), deg_to_rad(-87.6))
		"CometSpear":
			prev_weapon = currentweapon
			LeftHandItem = "CometSpear"
			cometspear = spearScene.instantiate()
			LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(cometspear)
			currentweapon = LHI_bone.get_child(0)
			currentweapon.position = Vector3(0.28, 0.1, -0.04)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
			if throwing == true:
				$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.5
				currentweapon.position = Vector3(-0.02, 0.078, -0.03)
				currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))
func two_fps() -> void:
	pass
