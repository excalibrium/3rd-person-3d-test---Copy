extends Character

class_name PlayerController
var MOVE_BOOL : bool = !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 4.8 and is_on_floor()
var IDLE_BOOL : bool = velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false
var killed := 1.0
@onready var parrying: AudioStreamPlayer3D = $parrying

@export var attack_speed_mult : float
var attack_speed : float

@onready var mat_ray: RayCast3D = $mat_ray

@export var Bone_RightHandItem : BoneAttachment3D

@export_category("Ability System")
var memory_current_state : String = "N/A"
var ability_timer := 0.0
var performing_ability := false
var ability_1 : String
var ability_2 : String
var ability_3 : String
var ult : String
var in_menu := false
var two_fps_counter := 0.0
var throwing := false
var air_throwing := false

@export_category("Extras")
@export var max_lock_range : float = 25.0
@export var raycast_ground : RayCast3D

@export var aim_look_at : Node3D

var player_no: Array #a mechanic that may help me later on. What? planning to add multiplayer? lol
@onready var LHI_bone = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
@onready var BaseModel3D = $BaseModel3D
@onready var view = $view
#@onready var _animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
var state_machine
var current_state
var previous_state
@onready var cam = $Camera/Camera3D
@onready var staminabar = $HUD/StaminaBar
@onready var healthbar = $HUD/HealthBar
var speed_multiplier = 1.0
var target_rotation: float = 0.0
var global_dir = 0
var attack_meter: float = 0.0
var shield_meter: float = 0.0
var throw_meter: float = 0.0

var leftclick = false
var rightclick = false
var lockOn = false
var enemies = []
var closest_enemy
var closest_enemy_body
var current_path := []
var speed := 0.0
var time_since_actionbar_halt = 0.3
var stored_velocity: Vector3
var time_since_stamina_depleted : float = 2.0

var rotation_lock = false
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
var bomb
var fists
#var x: float
var y: float
var z: float
var fps = Engine.get_frames_per_second()
var trail_switch = false
var conqueror_stacks := 0.1
var conqueror_value := 0.0
var is_jumping := false
var jump_start_pos
var jump_time : float
var jump_buffer := 0.0
var jump_activation : bool
var time_since_jump_buffer : float
var distance_to_ground : float
var is_on_air := false
var jump_lock := false
var camera_on_lmr := 0

var hypercharged_throw := false
var dodge_buffer := false
var time_since_dodge_buffer := 0.0
@export var groan_streams : AudioStreamPlayer3D
var current_weapon_code

var throw_timer := 0.0
var on := "nothing"

signal state_changed(new_state)


func _ready():
	DEBUG.add_debug_label(self, "global_position")
	Engine.time_scale = 1.0
	if currentweapon == null:
		LeftHandItem = "Fists"
		fists = weapon_scenes["fistScene"].instantiate()
		LHI_bone.add_child(fists)
		currentweapon = LHI_bone.get_child(0)
		animationTree.set_animation_player("../FistAnimPlayer") 
		prev_weapon = currentweapon

	state_machine = animationTree.get("parameters/StateMachine/playback")
	
	enemies = get_tree().get_nodes_in_group("enemies")
	player_no = get_tree().get_nodes_in_group("Player")
	staminabar.init_stamina(stamina)
	healthbar.init_health(health)
	connect("state_changed", Callable(self, "_on_state_changed"))

func interact():
	#print(cam.interact_ray.get_collider().get_parent())
	if cam.interact_ray.get_collider() and cam.interact_ray.get_collider().get_parent() and cam.interact_ray.get_collider().get_parent().has_method("interacted"):
		print(cam.interact_ray.get_collider().get_parent())
		cam.interact_ray.get_collider().get_parent().interacted(self)
		
func recieve_item(item_code, type):
	match type:
		"skill":
			cam.ingame_menu.skills[item_code].found = true
		"weapon":
			cam.ingame_menu.weapons[item_code].found = true

func _input(event):
	if event.is_action_pressed("ABILITY_1"):
		handle_ability_input(ability_1)
	if event.is_action_pressed("ABILITY_2"):
		handle_ability_input(ability_2)
	if event.is_action_pressed("ABILITY_3"):
		handle_ability_input(ability_3)
	

	if event.is_action_pressed("interact"):
		interact()
	
	
	if event.is_action_pressed("y"):
		if camera_on_lmr == 1:
			camera_on_lmr = 2
		elif camera_on_lmr == 2:
			camera_on_lmr = 0
		elif camera_on_lmr == 0:
			camera_on_lmr = 1
	if event.is_action_released("LeftClick") and stamina > 0.0:
		if throwing == true:
			if is_on_floor() == true:
				state_machine.travel("throw")
			else:
				state_machine.travel("fall_throw")
	if event.is_action_pressed("R"):
		throwing = not throwing
		if throwing:
			cam.fov = 70.0
		else:
			cam.fov = 80.0
		if LeftHandItem == "CometSpear" and throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.45 #0.45
			currentweapon.position = Vector3(0.28, 0.1, -0.04)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
		if LeftHandItem == "CometSpear" and throwing == true:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.00 # 0.95
			currentweapon.position = Vector3(-0.02, 0.078, -0.03)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))
	if event.is_action_pressed("throw_jump"):
		if throwing == true:
			velocity.y += 6.0
		if LeftHandItem == "CometSpear" and throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.45 #0.45
			currentweapon.position = Vector3(0.28, 0.1, -0.04)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
		if LeftHandItem == "CometSpear" and throwing == true:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.0 #0.95
			currentweapon.position = Vector3(-0.02, 0.078, -0.03)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))
	if event.is_action_pressed("1") and cam.ingame_menu.weapon_slots[0].get_ability() != current_weapon_code and !attacking:
		set_weapon(0)
	if event.is_action_pressed("2") and cam.ingame_menu.weapon_slots[1].get_ability() != current_weapon_code and !attacking:
		set_weapon(1)
	if event.is_action_pressed("3") and cam.ingame_menu.weapon_slots[2].get_ability() != current_weapon_code and !attacking:
		set_weapon(2)
	if event.is_action_pressed("4") and cam.ingame_menu.weapon_slots[3].get_ability() != current_weapon_code and !attacking:
		set_weapon(3)
	if event.is_action_pressed("Q"):
		
		if lockOn == false and closest_enemy and closest_enemy.global_position.distance_to(global_position) < max_lock_range:
			lockOn = true
		elif lockOn == true:
			$view.global_rotation.y = $BaseModel3D.global_rotation.y #once
			lockOn = false
	#if event.is_action_pressed("Escape"):
		#get_tree().quit()
		return

func handle_ability_input(slot_index: String):
	match slot_index:
		"hop":
			if is_on_floor() == true:
				state_machine.travel("ability_1_start")
			else:
				if not performing_ability:
					$view.global_rotation.y = aim_look_at.global_rotation.y - PI
					BaseModel3D.global_rotation.y = aim_look_at.global_rotation.y
					#velocity += aim_look_at.global_transform.basis.z * 1.0 * (cam.strength / 2.5)
					velocity += -$view.global_transform.basis.z * 2.0 * (cam.strength / 2.0)
				state_machine.travel("ability_1_down")
		"assault":
			if is_on_floor() == true:
				state_machine.travel("ability_2")
		"hypercharge":
			if is_on_floor() == true:
				throwing = not throwing
				if throwing == true:
					currentweapon.hit(1)
					hypercharged_throw = true
				else:
					hypercharged_throw = false
				if LeftHandItem == "CometSpear" and throwing == false:
					$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.45 #.45
					currentweapon.position = Vector3(0.28, 0.1, -0.04)
					currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
				if LeftHandItem == "CometSpear" and throwing == true:
					$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.00 #.95
					currentweapon.position = Vector3(-0.02, 0.078, -0.03)
					currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))

func detect_surface_type(collider):
	if collider.is_in_group("grass_surface"):
		return "grass"
		
	elif collider.is_in_group("water_surface"):
		#print("ay")
		return "water"
	
	return "nothing"
func _process(delta):
	#print(distance_to_ground)
	if mat_ray.is_colliding():
		var collider = mat_ray.get_collider()
		on = detect_surface_type(collider)
	if distance_to_ground < 2.3:
		if velocity.y < -0.2 and not $grass_drop.playing and on == "grass":
			$grass_drop.play()
		if velocity.y < -0.2 and not $water_drop.playing and on == "water":
			$water_drop.play()
	if not is_on_air:
		if speed > 3.0 and not $grass_run.playing and on == "grass":
			$grass_run.play()
		elif speed > 0.1 and not $grass_walk.playing and on == "grass":
			$grass_walk.play()
		elif speed > 3.0 and not $water_run.playing and on == "water":
			$water_run.play()
		elif speed > 0.1 and not $water_walk.playing and on == "water":
			$water_walk.play()
	$cam_pivot_mesh_copier.global_transform = cam.pivot_mesh.global_transform
	if time_since_stamina_depleted < 5.0:
		time_since_stamina_depleted += delta
	if throwing == false:
		hypercharged_throw = false
	if air_throwing and (is_on_floor() or not throwing):
		air_throwing = false
	if two_fps_counter < 0.5:
		two_fps_counter += delta
	if two_fps_counter >= 0.5:
		two_fps()
		two_fps_counter = 0

	IDLE_BOOL = velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false
	MOVE_BOOL = !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 4.8 and is_on_floor()
	if MOVE_BOOL == true:
		animationTree.set("parameters/StateMachine/blend1d/blend_position", lerp(animationTree.get("parameters/StateMachine/blend1d/blend_position"), 1.0, 0.2))
		animationTree.set("parameters/StateMachine/blend1d2/blend_position", lerp(animationTree.get("parameters/StateMachine/blend1d/blend_position"), 1.0, 0.2))
	elif IDLE_BOOL == true:
		animationTree.set("parameters/StateMachine/blend1d/blend_position", lerp(animationTree.get("parameters/StateMachine/blend1d/blend_position"), -1.0, 0.2))
		animationTree.set("parameters/StateMachine/blend1d2/blend_position", lerp(animationTree.get("parameters/StateMachine/blend1d/blend_position"), -1.0, 0.2))
	#$BaseModel3D.set_quaternion($BaseModel3D.get_quaternion() * animationTree.get_root_motion_rotation())
	RMPos =  (animationTree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()) * Vector3(animationTree.get_root_motion_position().x,animationTree.get_root_motion_position().y,-animationTree.get_root_motion_position().z)
	if current_state == "ability_1_start":
		if ( ability_timer >= 0.2 && ability_timer < 0.3 ):
			velocity.y = 1.0
		#if ( ability_timer > 0.0 && ability_timer < 0.4 ):
		floor_snap_length = 0.0
	else:
		floor_snap_length = 0.1

	global_position.y += RMPos.y * 1.0
	global_position += $BaseModel3D.global_transform.basis * RMPos
	if LeftHandItem == "Fists":
		animationTree.set_animation_player("../FistAnimPlayer")
	else:
		animationTree.set_animation_player("../AnimationPlayer")

	if raycast_ground.is_colliding():
		distance_to_ground = global_position.distance_to(raycast_ground.get_collision_point())
	else:
		distance_to_ground = 100
	if distance_to_ground < 1.1 and velocity.y <= 0.01:
		is_on_air = false
	#print_debug(distance_to_ground)
	current_state = state_machine.get_current_node()
	if current_state != previous_state:
		previous_state = current_state
		emit_signal("state_changed", current_state)
	current_path = state_machine.get_travel_path()
	_handle_variables(delta)
	_handle_detection()
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_animations(delta)
	if is_on_floor() == false and air_throwing == true:
		$BaseModel3D.global_rotation_degrees = Vector3(cam.global_rotation_degrees.x,cam.global_rotation_degrees.y, cam.global_rotation_degrees.z)
	else:
		$BaseModel3D.global_rotation_degrees = Vector3(0.0, $BaseModel3D.global_rotation_degrees.y, 0.0)
	#print(air_throwing)

func _on_state_changed(to):
	if to in ["fall_throw_loop", "fall_throw_charge", "fall_throw", "fall_throw_to_charge"]:
		air_throwing = true
		print(air_throwing)
	else:
		air_throwing = false
func _physics_process(delta):
	conqueror_value = lerpf(conqueror_value, conqueror_stacks, 0.1)
	if Input.is_action_pressed("SpaceBar") and is_on_floor():
		action_bar += 1
		time_since_actionbar_halt = 0
	aim_look_at.look_at(cam.pivot_ray.get_collision_point(), Vector3.UP, true)
	#if throwing == true:
		#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/UB2_applier.influence = 1.0
		#var original_rot = $Chest.global_rotation
		#var rot_to_apply = original_rot + aim_look_at.rotation
		#$Chest.global_rotation = rot_to_apply
	#else:
		#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/UB2_applier.influence = 0.0
	#_handle_movement(delta)
	#_handle_combat(delta)
	#_handle_animations(delta)
	super(delta)

func _handle_detection():
	var closest_distance = INF
	"res://Main/PlayerV2/Player.tscn"
	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy_body = enemy
	if closest_enemy != null:
		$enemy_radar.look_at(closest_enemy.global_transform.origin, Vector3.UP)
		$enemy_radar.rotation.y = wrapf($enemy_radar.rotation.y, -PI, PI)


func _handle_movement(delta):
	move_and_slide()
	if is_on_floor() == true and current_state == "walk_to_jump" and jump_time > 0.2667 :
		state_machine.travel("jump_to_walk")
	if is_on_floor() == true and current_state == "idle_to_jump" and jump_time > 0.2667:
		state_machine.travel("jump_to_idle")
	
	if current_state == "ability_1_down" and distance_to_ground < 5.0 and ability_timer > 0.45:
		
		state_machine.travel("ability_1_end")

	if is_on_floor() and current_state == "ability_1_end" and ability_timer > 0.8:
		state_machine.travel("ability_1_to_idle")

	#elif is_on_floor() == true and current_state in ["walk_to_jump", "idle_to_jump"] and jump_time < 0.2667 and jump_lock == false:
		#state_machine.travel("idle") 
	raycast_ground.global_rotation_degrees.y += 3
	wrapf(raycast_ground.global_rotation_degrees.y, -360, 360)
	#if is_on_air == true:
		#velocity.x = velocity.x / 0.9
		#velocity.z = velocity.z / 0.9
	if global_position.y <= -100:
		state_machine.travel("death_01")
	if Input.is_action_pressed("emulate"):
		ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", "true")
		ProjectSettings.save()
	var spd : float = velocity.length();
	speed = spd
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	global_dir = input_dir
	var camera_direction: Vector3 = ($Camera/view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var character_direction = -$view.transform.basis.z.normalized()
	target_rotation = atan2(-camera_direction.x, -camera_direction.z)
	
	var bone_rot = $UpperBody_skewer.rotation
	#print($UpperBody_skewer.rotation_degrees)
	if lockOn == true:
		if throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.0 # 0.0
		#else:
			#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 0.0
		if abs(wrapf($Camera/Camera3D/pivot.global_rotation.y - $BaseModel3D.global_rotation.y, -PI, PI)) <= PI/1.75:
			bone_rot.y = $Camera/Camera3D/pivot.global_rotation.y - $BaseModel3D.global_rotation.y
		else:
			bone_rot.y = $UpperBody_skewer_true.global_rotation.y
		
	else:
		if throwing == false:
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.0
			if abs(wrapf($Camera/Camera3D/pivot.global_rotation.y - $BaseModel3D.global_rotation.y, -PI, PI)) <= PI/2.0:
				bone_rot.y = $Camera/Camera3D/pivot.global_rotation.y - $BaseModel3D.global_rotation.y
			else:
				bone_rot.y = $UpperBody_skewer_true.global_rotation.y

	bone_rot.x = -$Camera/Camera3D.rotation.x / 1.1

	bone_rot.y = wrapf(bone_rot.y, -PI, PI)

	if throwing == true:
		if not lockOn:
			rotate_to_view = false

		bone_rot.y = $UpperBody_skewer_true.global_rotation.y
		#if current_state in ["fall_throw_charge","throw_to_charge"]:
			
			#bone_rot.y = $UpperBody_skewer_true.global_rotation.y - PI/36.0


	if is_on_floor():
		if throwing == false:
			
			$UpperBody_skewer.rotation.x = lerp($UpperBody_skewer.rotation.x, bone_rot.x / 1.5, 10.0 * delta)
			$UpperBody_skewer.rotation.y = lerp($UpperBody_skewer.rotation.y, bone_rot.y, 10.0 * delta)
			$UpperBody_skewer.rotation.z = lerp($UpperBody_skewer.rotation.z, bone_rot.z, 10.0 * delta)
		else:
			$UpperBody_skewer.rotation = $UpperBody_skewer.rotation.lerp(bone_rot, 1.0)
	else:
		$UpperBody_skewer.rotation = Vector3(0.0, $UpperBody_skewer.rotation.lerp(bone_rot, 1.0).y, $UpperBody_skewer.rotation.lerp(bone_rot, 1.0).z)
	if current_state in ["run"]:
		$UpperBody_skewer.rotation.x = $UpperBody_skewer_true.rotation.x
	if current_state in ["ability_1_start","ability_1_down","ability_1_end", "Attack_C_1", "Light_Damaged_R","Light_Damaged_L"]:
		$UpperBody_skewer.rotation = $UpperBody_skewer_true.rotation
	if current_state in ["chest_open"]:
		$UpperBody_skewer.rotation.y = $UpperBody_skewer_true.rotation.y
	if attacking == true or performing_ability == true or is_rolling:
		$UpperBody_skewer.rotation.y = $UpperBody_skewer_true.global_rotation.y
		if is_rolling:
			$UpperBody_skewer.rotation = $UpperBody_skewer_true.global_rotation

	if rotate_to_view == true and not attacking and not stunned and not rotation_lock:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 1.0)
	elif attacking and attack_timer >= attack_grace and !lockOn and !stunned and rotate_to_view == true and not rotation_lock:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 1.0)
	if lockOn == true and is_running == false and is_rolling == false and in_menu == false:
		rotate_to_view = true
		if throwing == true:
			rotate_to_view = false
			
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, delta * 30)
	if lockOn == false or is_running == true and is_rolling == true and in_menu == false:
		rotate_to_view = true

	if input_dir.length() > 0 and !movement_lock and !instaslow and !staggered and is_on_floor() and in_menu == false:
		is_moving = true
		if Input.is_action_pressed("moveForward") and Input.is_action_pressed("moveLeft") and !lockOn:
			$UpperBody_skewer.rotation.z = lerp_angle($UpperBody_skewer.rotation.z, -PI / 8, delta * 6)
		elif Input.is_action_pressed("moveForward") and Input.is_action_pressed("moveRight") and !lockOn:
			$UpperBody_skewer.rotation.z = lerp_angle($UpperBody_skewer.rotation.z, PI / 8, delta * 6)
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, delta * 12)
		velocity = lerp(velocity, character_direction * speed_multiplier, delta * 6)
		stored_velocity = velocity
	elif is_on_floor():
		is_moving = false
		velocity.x = lerpf(velocity.x, 0, delta * 18)
		velocity.z = lerpf(velocity.z, 0, delta * 18)

	elif is_on_floor() == false:
		velocity.x = lerp(velocity.x, character_direction.x * speed_multiplier, delta * 6)
		velocity.z = lerp(velocity.z, character_direction.z * speed_multiplier, delta * 6)
	$UpperBody_skewer.rotation.z = lerp_angle($UpperBody_skewer.rotation.z, 0.0, delta * 6)
	if movement_lock and attacking and input_dir.length() > 0:
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, delta * 6)

	if jump_buffer == 1.0 and is_on_floor() and current_state in ["jump_to_walk", "jump_to_idle", "run_to_idle", "idle", "walk", "idle_to_walk", "walk_to_idle"]:
		if !staggered and is_moving == false and is_on_floor() and attacking == false and is_blocking == false and is_running == false and in_mode == false:
			state_machine.travel("idle_to_jump")
		if !staggered and is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == false:
			state_machine.travel("walk_to_jump")
		jump_time = 0
		jump_start_pos = global_position.y
		jump_lock = false
		is_jumping = true
		action_bar = 0
		jump_buffer = 0
		jump_activation = true
	
	if jump_activation == true:
		jump_time = delta + jump_time
		if velocity.y < -0.9:
			jump_lock = true
			is_jumping = false
		if jump_time > 0.2667 and is_on_floor() == true and velocity.y >= 0.0 and jump_lock == false:
			velocity.y = 3.0
			#print("velytrue")
			is_on_air = true
			is_jumping = false
			jump_activation = false
	if distance_to_ground > 2.0:
		#print("flyingtrue")
		is_on_air = true
	if Input.is_action_just_released("SpaceBar"):
		if action_bar < 20 and is_on_floor():
			dodge_buffer = true
			time_since_dodge_buffer = 0.0
		action_bar = 0
	if dodge_buffer == true:
		time_since_dodge_buffer += delta
		if time_since_dodge_buffer < 0.35 and stamina > 0.0: #-10
			dodge()
		else: 
			dodge_buffer = false
			time_since_dodge_buffer = 0.0
func _handle_variables(delta):
	if performing_ability == true:
		ability_timer += delta
	if throwing == true and not rotation_lock:
		
		if lockOn == false:
			$Thrown_target.look_at($Camera/Camera3D/pivot/RayCast3D/MeshInstance3D.global_position)
			$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $Thrown_target.rotation.y, 0.5)
	#$Throw_test.global_rotation = $BaseModel3D/MeshInstance3D.global_rotation
	#var camattachment = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment
	var camattachmentright = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment/right
	var camattachmentleft = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment/left
	var camattachmentmiddle = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment/middle
	
	#var cam3dTO = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment/right.global_transform.origin
	var cam3dthrow = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CameraAttachment/throw.global_transform.origin
	if not throwing:
		if time_since_engage >= 8:
			cam.anchor.spring_length = lerp(cam.anchor.spring_length, 1.75, 0.1)
		else:
			cam.anchor.spring_length = lerp(cam.anchor.spring_length, 3.5, 0.1)
		if camera_on_lmr == 1:
			$Camera.global_transform.origin = lerp($Camera.global_transform.origin, camattachmentright.global_transform.origin, 0.125)
		elif camera_on_lmr == 0:
			$Camera.global_transform.origin = lerp($Camera.global_transform.origin, camattachmentleft.global_transform.origin, 0.125)
		elif camera_on_lmr == 2:
			$Camera.global_transform.origin = lerp($Camera.global_transform.origin, camattachmentmiddle.global_transform.origin, 0.125)
			
		#$Camera.global_transform.origin.x = lerp($Camera.global_transform.origin.x, camattachment.global_transform.origin.x, 0.0125)
	else:
		cam.anchor.spring_length = lerp(cam.anchor.spring_length, 1.85, 0.25)
		#$BaseModel3D.global_rotation_degrees.y += -10 * delta
		$Camera.global_transform.origin = lerp($Camera.global_transform.origin, cam3dthrow, 0.125)
	#else:
		#camera_original_position = cam.position
		#$Camera.rotation.z = 0
	#print(shield_activ	ation, shield_meter, offhand.perfect_active)
	if shift == true:
		shield_meter = 0.0
	if shield_meter > 0.0:
		shield_activation = true
	if (shield_meter > 0.0 && shield_meter < 24.0*delta):
		offhand.perfect_active = true
	else:
		offhand.perfect_active = false
	if shield_meter == 0.0:
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

	if Input.is_action_just_pressed("B") and is_jumping == false:
		jump_buffer = 1.0
		time_since_jump_buffer = 0.0
	if time_since_jump_buffer < 0.35:
		time_since_jump_buffer += delta
	if jump_buffer == 1.0 and time_since_jump_buffer >= 0.35:
		jump_buffer = 0.0

	#RUNNING
	if action_bar > 20 and stamina > 0 and is_moving and time_since_stamina_depleted >= 4.0:
		is_running = true
		stamina -= delta * stamina_drain_rate / 2.0
		time_since_stamina_used = 0.0
	else:
		is_running = false

	if is_running == true:
		speed_multiplier = 4.1
	elif throwing == true:
		speed_multiplier = 0.75
	else:
		speed_multiplier = 1.5
	# regen stamina.
	if time_since_stamina_used >= stamina_grace_period and stamina < max_stamina:
		stamina += delta * stamina_regeneration_rate
	$"BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/helmet mesh".get_active_material(0).set_shader_parameter("conqueror", clampf(conqueror_value, 1.0, 10.0))
	if time_since_engage < 3 and trail_switch == false:
		currentweapon.attack_init()
		trail_switch = true
	if time_since_engage >= 3 and trail_switch == true:
		currentweapon.attack_end()
		trail_switch = false
	if time_since_engage >= 3 and conqueror_stacks > 0.1:
		conqueror_stacks = lerp(conqueror_stacks, 0.0, delta * 100)
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
	animationTree.set("parameters/StateMachine/conditions/idle", is_on_floor() == true and throwing == false and velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false)
	#animationTree.set("parameters/StateMachine/conditions/idlent", throwing == false and velocity.y <= 0 and !staggered and is_moving == false and attacking == false and is_blocking == false and is_running == false and in_mode == false)
	animationTree.set("parameters/StateMachine/conditions/move", throwing == false and !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 3.0 and is_on_floor())
	#animationTree.set("parameters/StateMachine/conditions/movent", throwing == false and !staggered and is_moving == true and attacking == false and is_blocking == false and is_running == false and speed < 4.8 and is_on_floor())
	animationTree.set("parameters/StateMachine/conditions/fall", is_on_floor() == false and throwing == false)
	
	animationTree.set("parameters/StateMachine/conditions/run", throwing == false and !staggered and is_moving == true and is_on_floor() and attacking == false and is_blocking == false and is_running == true and speed >= 3.0)
	animationTree.set("parameters/StateMachine/conditions/throw", throwing == true and air_throwing == false)
	animationTree.set("parameters/StateMachine/conditions/fall_throw", throwing == true and is_on_floor() == false)
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
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer.set("speed_scale", 1.0)
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer2.set("speed_scale", 1.0)
		

	else:
		animationTree.set("parameters/TimeScale/scale", 0.01)
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer.set("speed_scale", 0.01)
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer2.set("speed_scale", 0.01)
	attack_speed = 1.0
	if attacking == true:
		attack_speed *= attack_speed_mult
	if currentweapon is Weapon:
		currentweapon.anim_player.speed_scale = attack_speed
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer.speed_scale = attack_speed
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer2.speed_scale = attack_speed
	animationTree.set("parameters/TimeScale/scale", animationTree.get("parameters/TimeScale/scale") * attack_speed)
	if shift == true and is_on_floor() and is_blocking == false and is_running == false:
		in_mode = true
	else:
		in_mode = false
	if !is_blocking:
		$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/RightHandItem/Shield/Area3D/CollisionShape3D.disabled = true
	elif current_state in ["shield_block_1", "shield_block_walk", "run_blocking"]:
		if damI >= 0:
			damI -= delta * 1.4
		if damI <= 0 and current_state == "shield_block_1":
			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/RightHandItem/Shield/Area3D/CollisionShape3D.disabled = false
	if damI >= damI_cd:
		canBeDamaged = true
	else:
		canBeDamaged = false
	if !attacking:
		currentweapon.Hurt = false
	
	match current_state: # Attack hurt frame code AND DEATH!!!! YARRR GRRRRR DEATHHH!!!
		"throw":
			if instaslow == false:
				throw_timer += delta
			if throw_timer >= 0.296:
				one_shot(staminabar_update,-10.0)
				#throw_timer = 0.0
				throw_weapon()
				throw_timer = 0.0
		"fall_throw":
			if instaslow == false:
				throw_timer += delta
			if throw_timer >= 0.296:
				one_shot(staminabar_update,-10.0) 
				throw_weapon()
				throw_timer = 0.0
		"death_01":
			damI = 0
		"Attack_bash":
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.01 && attack_timer < 0.375 ):
				offhand.Active = true
			else:
				offhand.Active = false
		"Attack_1":
			currentweapon.attack_multiplier = 3
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.35 && attack_timer < 0.35+(delta*attack_speed) ):
				currentweapon.hit(1)
			if LeftHandItem == "Fists":
				if ( attack_timer >= 0.2 && attack_timer < 0.41 ): 
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.090 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
			else:
				if ( attack_timer >= 0.3 && attack_timer < 0.5883 ):
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.135 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
		"Attack_2":
			currentweapon.attack_multiplier = 2
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.42 && attack_timer < 0.42+(delta*attack_speed) ):
				currentweapon.hit(1)
			if LeftHandItem == "Fists":
				if ( attack_timer >= 0.27 && attack_timer < 0.45 ): 
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.090 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
			else:
				if ( attack_timer >= 0.3 && attack_timer < 0.625 ):
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.180 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
		"Attack_3":
			currentweapon.attack_multiplier = 1.5
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if LeftHandItem == "Fists":
				if ( attack_timer >= 0.23 && attack_timer < 0.45 ): 
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.090 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
			else:
				if ( attack_timer >= 0.4 && attack_timer < 0.625 ):
					one_shot(staminabar_update,-10.0)
					currentweapon.hit(3)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.125 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
		"Attack_4":
			currentweapon.attack_multiplier = 1.5
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if LeftHandItem == "Fists":
				if ( attack_timer >= 0.23 && attack_timer < 0.41 ): 
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.090 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
					
			else:
				if ( attack_timer >= 0.1 && attack_timer < 0.375 ):
					one_shot(staminabar_update,-10.0)
					currentweapon.hit(3)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.125 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
		"Attack_5":
			currentweapon.attack_multiplier = 4
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.38 && attack_timer < 0.38+(delta*attack_speed) ):
				currentweapon.hit(1)
			if LeftHandItem == "Fists":
				if ( attack_timer >= 0.4 && attack_timer < 0.75 ): 
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.09 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
			else:
				if ( attack_timer >= 0.4 && attack_timer < 0.75 ):
					one_shot(staminabar_update,-10.0)
					currentweapon.Hurt = true
					currentweapon.hitCD_cap = 0.150 - (delta*attack_speed)
				else:
					currentweapon.Hurt = false
		"ability_2":
			currentweapon.attack_multiplier = 2
			if ( attack_timer >= 1.37 && attack_timer < 1.43 ):
				currentweapon.attack_multiplier = 6
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.05 && attack_timer < 0.1 ) or ( attack_timer >= 0.29 && attack_timer < 0.34 ) or ( attack_timer >= 0.55 && attack_timer < 0.6 ) or ( attack_timer >= 0.79 && attack_timer < 0.84 ) or ( attack_timer >= 0.97 && attack_timer < 1.11 ) or ( attack_timer >= 1.38 && attack_timer < 1.43 ):
				currentweapon.hit(1)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.0
			else:
				currentweapon.Hurt = false
				currentweapon.owners_hurt.clear()
				currentweapon.owners.clear()
				currentweapon.boxes_hit.clear()
				currentweapon.blacklisted_boxes.clear()
		"ability_1_end":

			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if attack_timer >= 0.25 and is_on_floor() == true:
				one_shot(staminabar_update,-10)
				currentweapon.hitCD_cap = 0.150
				for a in $AbilityCol/Ability_1AOE.get_overlapping_bodies():
					if a is Casual_Enemy and a.has_method("damage_by") and a.health > 0.0:
						a.damage_by(20,self)
						#$AbilityCol/S_Hit_FX_CS.visible = true
						if a.health > 0.0:
							a.stun()
						attack_timer = 0.0
				attack_timer = 0.0
			else:
				currentweapon.Hurt = false
		"ability_2_bash":
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.01 && attack_timer < 0.25 ):
				one_shot(staminabar_update,-10)
				offhand.Active = true
				for a in offhand.hurtbox.get_overlapping_bodies():
					if a is Casual_Enemy and a.has_method("stun") and a.health > 0.0:
						#await get_tree().create_timer(delta).timeout
						a.stun()
			else:
				offhand.Active = false
		"in_to_H_Attack_1":
			currentweapon.attack_multiplier = 3
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.515 && attack_timer < 0.875 ):
				one_shot(staminabar_update,-10)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.350 - (delta*attack_speed)
			else:
				currentweapon.Hurt = false
		"H_Attack_2":
			currentweapon.attack_multiplier = 5
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.7 && attack_timer < 0.875 ):
				one_shot(staminabar_update,-15)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.150 - (delta*attack_speed)
			else:
				currentweapon.Hurt = false
		"Attack_roll":
			
			currentweapon.attack_multiplier = 3
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.4333 && attack_timer < 0.6667 ):
				one_shot(staminabar_update,-10)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.200 - (delta*attack_speed)
			else:
				currentweapon.Hurt = false
		"Attack_C_1":
			shield_activation = false
			attacking = false
			is_blocking = false
			is_running = false
			currentweapon.attack_multiplier = 1
			if instaslow == false:
				attack_timer += (delta*attack_speed)
			if ( attack_timer >= 0.3 && attack_timer < 0.5) or ( attack_timer >= 0.7 && attack_timer < 0.993 ):
				one_shot(staminabar_update,-5)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.200 - (delta*attack_speed)
			else:
				currentweapon.Hurt = false
	#if current_state != "throw" or current_state != "fall_throw" :
		#throw_timer = 0.0
	if current_state == "ability_2":
		is_blocking = true
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
	movement_lock = current_state in ["staggered", "throw_charge","Light_Damaged_R","Light_Damaged_L","Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1", "Attack_C_1_bash", "death_01", "Attack_bash", "in_to_H_Attack_1", "H_Attack_2", "fall_throw", "throw", "ability_1_start", "ability_2_from_idle"] or stunned

	if Input.is_action_just_pressed("RightClick"):
		rightclick = true
		if current_state != "ability_2" and current_state != "shield_block_1" and current_state != "Attack_bash" and Input.is_action_pressed("shiftKey"):
				shift = true

	if Input.is_action_pressed("RightClick") and !stunned and rightclick:
		shield_meter += delta
		if shift == true:
			state_machine.travel("Attack_bash")
			stunned = true
	if Input.is_action_pressed("RightClick") and !stunned:
		pass

	if Input.is_action_just_released("RightClick"):
		shield_meter = 0.0
		rightclick = false


	if Input.is_action_just_pressed("shiftKey"):
		shift = true
	if Input.is_action_just_released("shiftKey"):
		shift = false

	if Input.is_action_just_pressed("LeftClick") and in_menu == false:
		if cam.in_ingame_menu == false:
			leftclick = true
			if not is_on_floor() and air_throwing == true:
				gravity = 4.0
			else:
				gravity = 4.9 * 2.0
	if Input.is_action_pressed("LeftClick") and !stunned and leftclick and stamina > 0.0:
		attack_meter += delta
		throw_meter += delta
	if Input.is_action_pressed("LeftClick") and !stunned and stamina > 0.0:
		if attack_meter >= 0.25 and leftclick and throwing == false:
			attack_meter = 0.0
			attacking = true
			state_machine.travel("Attack_C_1")
			charge_attack = true
			if current_state == "Attack_C_1":
				attack_buffer = 101
			currentweapon.guard_break = true
			time_since_engage = 0
			leftclick = false
		if attack_meter >= 0.25 and leftclick and throwing == true:
			state_machine.travel("throw_charge")
			if is_on_floor() == false:
				state_machine.travel("fall_throw_charge")
	else:
		attack_meter = 0
	if weaponCollidingWall and attacking and currentweapon.Hurt == true:
		stunned = true
		attacking = false
		#rotation_lock = true
		state_machine.travel("staggered")
	if Input.is_action_just_released("LeftClick") and leftclick == true and stamina > 0.0:
		handle_attack_release()

func handle_attack_release():
	if throwing == true and current_state == "throw_charge" or current_state == "fall_throw_charge":
		
		if is_on_floor() == true:
			state_machine.travel("throw")
		else:
			state_machine.travel("fall_throw")
	if attack_meter < 0.25 and time_since_engage >= attack_grace and !stunned:
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
	if current_state in ["staggered"]:
		rotation_lock = true
	else:
		rotation_lock = false
	memory_current_state = "NA"
	if lockOn and anim_name in ["Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1"]:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.75)
	if anim_name in ["Attack_1_to_idle", "Attack_2_to_idle", "Attack_3_to_idle", "Attack_4_to_idle", "Attack_5_to_idle", "Attack_6_to_idle", "Attack_roll_to_idle", "H_Attack_1_to_in", "H_Attack_2_to_in"]:
		attacking = false
	if anim_name in ["H_Attack_2", "in_to_H_Attack_1", "Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1", "Attack_bash"]:
		attacking = true
		attack_timer = 0.0
	if anim_name in ["ability_1_start", "ability_1_down", "ability_2", "ability_2_from_idle"]:
		performing_ability = true
	if anim_name in ["ability_2"]:
		currentweapon.scale *= 1.25
		attack_timer = 0.0
		ability_timer = 0.0
		damI = 0.0
		damI_cd = 1.583
	if anim_name in ["ability_1_start", "ability_1_down"]:
		attack_timer == 0.0
	match anim_name:
		"throw_to_charge":
			throw_meter = 0.0
		"chest_open":
			staggered = true
		"Light_Damaged_R":
			attack_timer = 0.0
			offhand.Active = false
		"Light_Damaged_L":
			attack_timer = 0.0
			offhand.Active = false
		"ability_1_to_idle":
			ability_timer = 0.0
		"H_Attack_2":
			
			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"in_to_H_Attack_1":

			$hit_heavy.play()
			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_1":

			cam.anchor.spring_length = lerp(cam.anchor.spring_length, 1.75, 0.1)
			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_2":

			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_3":

			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer.play("A3 swing")
			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_4":

			$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer2.play("A4 swing")
			#groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_5":
			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_6":
			attacking = true
			attack_timer = 0.0
		"Attack_roll":

			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_C_1":
			groan_streams.play()
			attacking = true
			attack_timer = 0.0
		"Attack_bash":
			#attacking = true # EXPERIMENTAL. DELETE IF BUG DANGER ALERT FIXME ATTENTION CRITICAL HACK
			attack_timer = 0.0
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
			gravity = 9.8
		"fall_throw":
			throw_timer = 0.0
			gravity = 9.8
		"Roll":
			staminabar_update(-10.0)
			damI_cd = 1.0
			damI = 0.0
			throwing = false
			rotate_to_view = true
			is_rolling = true
		"ability_2_bash":
			offhand.Active = true
func _on_animation_tree_animation_finished(anim_name):
	if lockOn and anim_name in ["Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_C_1"]:
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $enemy_radar.rotation.y, 0.75)
	if anim_name in ["H_Attack_2", "in_to_H_Attack_1", "Attack_1", "Attack_2", "Attack_3", "Attack_4", "Attack_5", "Attack_6", "Attack_roll", "Attack_C_1", "Attack_bash"]:
		pass
	if anim_name in ["ability_1_end", "ability_2_bash"]:
		performing_ability = false
	if anim_name in ["ability_2"]:
		damI_cd = 0.08
		currentweapon.scale = Vector3.ONE
		if is_on_floor() == true:
			ability_timer = 0.0
	match anim_name:
		"chest_open":
			staggered = false
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
		"Light_Damaged_R":
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
			attack_timer = 0.0
			if attack_buffer == 202 and !weaponCollidingWall:
				state_machine.travel("H_Attack_3")
				attack_buffer = 0
			else:
				if !stunned:
					state_machine.travel("H_Attack_2_to_in")

		"Attack_1":
			conqueror_stacks += 0.1
			attack_timer = 0.0
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
			attack_timer = 0.0
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
		"staggered":
			state_machine.travel("idle")
			rotation_lock = false
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
			performing_ability = false
			player_death(0)
		"Attack_bash":
			offhand.Active = false
			stunned = false
			shift = false
			attack_timer = 0
			attacking = false
			attack_buffer = 0
		"Roll":
			damI_cd = 0.08
			rotate_to_view = false
			is_rolling = false
		"ability_1_end":
			attack_timer = 0.0
			ability_timer = 0.0
			$AbilityCol/S_Hit_FX_CS.visible = false
		"ability_2":
			attack_timer = 0.0
			state_machine.travel("ability_2_bash")
		"ability_2_bash":
			offhand.Active = false
		"throw":
			throw_timer = 0.0
func player_death(x):
	staggered = false
	global_position = Vector3(0,3,0)
	player_no[x].reset()
	is_moving = false
	attacking = false
	is_blocking = false
	is_running = false
	healthbar.health = health

func damage_by(damaged: int,by, side = 1):
	if canBeDamaged:
		health -= damaged
		shake(damaged/2.0)
		if side == 1 and canBeDamaged:
			staggered = true
			throwing = false
			var a = randf()
			$view.global_rotation.y = by.global_rotation.y - PI
			BaseModel3D.look_at(by.global_position)
			velocity += global_transform.basis.x * 13.3
			if a < 0.5:
				state_machine.start("Light_Damaged_L")
			else:
				state_machine.start("Light_Damaged_R")
				
		if health <= 0:
			stunned = true
			state_machine.stop()
			if current_state != "death_01":
				state_machine.start("death_01")
			health = 0
		damI = 0.0
	healthbar.health = health

func parried(by):
	state_machine.travel("staggered")
	parrying.play()
	is_blocking = false
	#rotation_lock = true
func throw_weapon():
	var thrown_weapon = null
	throwable = throwableScene.instantiate()
	add_child(throwable)
	if lockOn == true:
		throwable.target = closest_enemy
	throwable.linear_velocity = Vector3.ZERO
	throwable.angular_velocity = Vector3.ZERO
	throwable.global_rotation = $BaseModel3D.global_rotation
	throwable.global_rotation.x -= $UpperBody_skewer.global_rotation.x / 1.0 - 0.025
	throwable.global_rotation.y -= 0.25 / cam.strength

	#$Throw_test.global_rotation.x = 0
	throwable.global_position = $BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/LeftHandItem.global_position
	thrown_weapon = currentweapon
	if throw_meter < 0.1:
		currentweapon.attack_multiplier = 1
	if throw_meter >= 0.1 && throw_meter < 0.75:
		currentweapon.attack_multiplier = 2
	if throw_meter >= 0.75:
		currentweapon.attack_multiplier = 5
	if hypercharged_throw == true:
		currentweapon.attack_multiplier = 10
	currentweapon.my_owner = self
	#print(cam.strength)

	throw_meter = 0.0
	currentweapon.reparent(throwable, true)
	thrown_weapon.position = Vector3.ZERO
	var impulse = -throwable.global_transform.basis.z * (cam.strength / 2.0) * 5 * (1.0+throw_meter)
	if currentweapon.type == "throw":
		thrown_weapon.prime()
		impulse = throwable.global_transform.basis.z * 15
		throwable.collision_layer = 8
		throwable.collision_mask = 8
	groan_streams.play()
	set_weapon(-1)
	print(currentweapon.type)
	throwable.apply_central_impulse(impulse)
	throwable.global_rotation = $BaseModel3D.global_rotation
	thrown_weapon.rotation_degrees -= Vector3(0.0,5.0,0.0) 
	thrown_weapon.thrown = true
	
func set_weapon(weapon_no : int = 0):
	current_weapon_code = cam.ingame_menu.weapon_slots[weapon_no].get_ability()
	var current_str: String
	#var current_int: int
	var handheld
	if weapon_no >= 0:
		current_str = cam.ingame_menu.weapon_slots[weapon_no].get_ability()
		print(cam.ingame_menu.weapon_slots[weapon_no])
	else:
		print(current_str)
	if current_str in weapons:
		handheld = weapons[current_str]
	else:
		handheld = 0
	match handheld:
		0:
			prev_weapon = currentweapon
			LeftHandItem = "Fists"
			fists = weapon_scenes["fistScene"].instantiate()
			print(str(currentweapon) + " Hello, read this.")
			if LHI_bone.get_children() != []:
			#print(LHI_bone.get_children())
				LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(fists)
			currentweapon = LHI_bone.get_child(0)
		2:
			prev_weapon = currentweapon
			LeftHandItem = "BoTRK"
			botrk = weapon_scenes["botrkScene"].instantiate()
			LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(botrk)
			currentweapon = LHI_bone.get_child(0)
			currentweapon.position = Vector3(-0.108, 0.1, -0.05)
			currentweapon.rotation = Vector3(deg_to_rad(-0.7), deg_to_rad(-12.4), deg_to_rad(-87.6))
		1:
			prev_weapon = currentweapon
			LeftHandItem = "CometSpear"
			cometspear = weapon_scenes["spearScene"].instantiate()
			LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(cometspear)
			currentweapon = LHI_bone.get_child(0)
			currentweapon.position = Vector3(0.28, 0.1, -0.04)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
			if throwing == true or air_throwing == true:
				$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.00 # 0.95
				currentweapon.position = Vector3(-0.02, 0.078, -0.03)
				currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))
		3:
			prev_weapon = currentweapon
			LeftHandItem = "Bomb"
			bomb = weapon_scenes["bombScene"].instantiate()
			LHI_bone.remove_child(prev_weapon)
			LHI_bone.add_child(bomb)
			currentweapon = LHI_bone.get_child(0)
			currentweapon.position = Vector3(0.28, 0.1, -0.04)
			currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(2), deg_to_rad(-90))
			if throwing == true:
				$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/CustomModifier.influence = 1.0 # 0.95
				currentweapon.position = Vector3(-0.02, 0.078, -0.03)
				currentweapon.rotation = Vector3(deg_to_rad(11), deg_to_rad(175.0), deg_to_rad(-95.0))
	print(handheld)
func two_fps() -> void:
	pass
	
func update_ability():
	ability_1 = cam.ingame_menu.slots[0].get_ability()
	ability_2 = cam.ingame_menu.slots[1].get_ability()
	ability_3 = cam.ingame_menu.slots[2].get_ability()
	ult = cam.ingame_menu.slots[3].get_ability()

func shake(mag):
	cam.active = false
	var mag10 = mag/10.0
	$Camera.position += Vector3(randf_range(-mag10,mag10), randf_range(-mag10/2.0,mag10/2.0),randf_range(-mag10,mag10))
	cam.rotation_degrees += Vector3(randf_range(-mag,mag),randf_range(-mag,mag),randf_range(-mag,mag))
	#await get_tree().create_timer(1.175).timeout
	cam.active = true
func dodge():
	state_machine.travel("Roll")
	attacking = false

func staminabar_update(x: float = 0.0):
	stamina += x
	if stamina < 0.0:
		stamina = 0.0
	if stamina <= 0.0:
		time_since_stamina_depleted = 0.0
	staminabar.stamina = stamina
	time_since_stamina_used = 0.0
func one_shot(xfunc: Callable,arg):
	if memory_current_state != current_state:
		xfunc.call(arg)
		memory_current_state = current_state

func gave_damage():
	$onhit_light5.play()
	staminabar_update(10.0)
	print("take that!")

func on_parry():
	state_machine.start("Attack_bash")

func chest_open():
	state_machine.start("chest_open")
