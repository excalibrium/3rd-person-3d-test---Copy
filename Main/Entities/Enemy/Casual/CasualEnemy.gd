extends Enemy
class_name Casual_Enemy

@onready var parrying: AudioStreamPlayer3D = $parried

@export var mini_camera_mapper_thingy : MeshInstance3D
@export var raycast : RayCast3D
var player
var locking_value
var nav_timer : float
@export var particle_pool : Array[GPUParticles3D]
func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
	main_ready()
	state_machine = animationTree.get("parameters/stater/playback")
	healthbar.init_health(health)
	posturebar.init_posture(posture)
	
	prio = null
	weapons_in_tree = get_tree().get_nodes_in_group("weapon")
	for each_weapon in weapons_in_tree:
		if each_weapon.owner == self:
			currentweapon = each_weapon
	
	
func _process(delta: float) -> void:
	pass
	#global_position += $BaseModel3D.global_transform.basis * RMPos
func _handle_var(delta):
	$SubViewport/Label3.text = str(locking_value)
	raycast.look_at(player.global_position)
	if raycast.get_collider() == null:
		mini_camera_mapper_thingy.global_position = global_position
	else:
		mini_camera_mapper_thingy.global_position = raycast.get_collision_point()

	#damI
	if damI < damI_cd:
		damI += delta
	if damI >= damI_cd:
		canBeDamaged = true
	else:
		canBeDamaged = false
	
	if velocity < Vector3(0.1, 0.1, 0.1):
		#if current_state == State.ATTACK:
			#current_attack_substate = AttackSubstate.AWAIT
		think()
	
	#Is moving?
	if abs(velocity.x + velocity.z) > 0.125:
		is_moving = true
	else:
		is_moving = false

	#Curiosity mechanic
	if curious >= 0.0 and curious_stage < 2:
		curious -= delta / 2
	if curious <= 0.0:
		unalert()

	#Think timer/adrenaline mechanic
	if think_timer < (1.0 + cdm_seed) / adrenaline:
		#print(think_timer)
		think_timer += delta * adrenaline
	if think_timer >= (1.0 + cdm_seed) / adrenaline:
		think()
		#print("thunk")
		think_timer = 0.0

func _physics_process(delta: float) -> void: #shitass code
	_handle_animations(delta)
	_handle_var(delta)
	current_anim = state_machine.get_current_node()
	$BaseModel3D.set_quaternion($BaseModel3D.get_quaternion() * animationTree.get_root_motion_rotation())
	RMPos = (animationTree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()) * animationTree.get_root_motion_position()
	global_position += $BaseModel3D.global_transform.basis * RMPos / 10.0
	if stall_meter <= stall_cd + cdm_seed:
		stall_meter += delta
	animationTree.set("parameters/stater/conditions/walk", stunned == false and is_moving == true and attacking == false and is_blocking == false and is_running == false)
	animationTree.set("parameters/stater/conditions/idle", stunned == false and is_moving == false and attacking == false and is_blocking == false and is_running == false)
	if prio:
		$Raycast.look_at(prio.global_position)

	if movement_lock == false and stunned == false:
		nav_timer += delta
		if nav_timer >= 0.25:
	
			var current_position = global_position
			var next_position = nav.get_next_path_position()
			var new_velocity = (next_position - current_position).normalized() * current_speed
			nav.velocity = new_velocity
			nav_timer = 0.0
		velocity = velocity.move_toward(nav.velocity, 0.1)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, 0.1)
		
	# Apply gravity only when needed
	if not is_on_floor():
		velocity.y -= 1
	
	# Handle rotation
	if velocity.length() > 0.1 and not rot_lock and not stunned and not lock_on:
		# Calculate target rotation once
		var look_direction = velocity.normalized()
		var target_angle = atan2(-look_direction.x, -look_direction.z)
		var target_rotation = Quaternion.from_euler(Vector3(0, target_angle, 0))
		
		# Interpolate rotation
		basis = Basis(basis.get_rotation_quaternion().slerp(target_rotation, 5.0 * delta))
	elif lock_on:
		global_rotation.y = looker.global_rotation.y
	
	if curious_stage == 2:
		$Raycast.look_at(prio.global_position)
	
	# Apply movement
	
	move_and_slide()

func _on_alertness_sphere_area_entered(area: Area3D) -> void:
	if area.is_in_group("alerter"):
		alert(1 / pow(global_position.distance_to(area.global_position), 1.0/6.0), area.owner)


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	nav.velocity = nav.velocity.move_toward(safe_velocity, 0.1)
	#print("eah")
func damage_by(damaged,by : Node3D):
	if canBeDamaged == false:
		posture -= damaged*2
		if not posture <= 0.0:
			by.parried(self)
			#posture= 100
		else:
			canBeDamaged = true
			parried(self)
			posture= 100
	if canBeDamaged:
		velocity += global_transform.basis.z * 3.25
		if by.has_method("gave_damage"):
			by.gave_damage()
		spawn_blood(global_position, by)
		if damaged < max_health / 3.0:
			if randf() < 0.5:
				state_machine.start("light_damaged_L")
			else:
				state_machine.start("light_damaged_R")
		else:
			state_machine.start("heavy_damaged")

		$AudioStreamPlayer3D.pitch_scale = (0.7 + (randf()/10.0))
		$AudioStreamPlayer3D.play()
		posture -= damaged/2
		health -= damaged
		if health <= 0:
			stunned = true
			state_machine.stop()
			if current_anim != "death":
				state_machine.start("death")
			health = 0
		if by is PlayerController:
			by.shake(damaged/5.0)
	healthbar.health = health
	posturebar.posture = posture
	#if posture <= 0.0:
		#parried(self)
		#posture= 100
	if health <= 0:
		stunned = true
		state_machine.stop()
		if current_anim != "death":
			state_machine.start("death")
			print("muh")
		health = 0.0
	healthbar.health = health
	posturebar.posture = posture

	stalling = false

func gave_damage():
	print("yeehaw")

func stun():
	state_machine.travel("stunned")
	staggered = true
	is_blocking = false
	attacking = false
	movement_lock = false
	decision_processing = false
	current_attack_substate = AttackSubstate.AWAIT
func on_parry():
	pass
func parried(by):
	if is_blocking or attacking or attacking == false and health > 0.0:
		by.on_parry()
		parrying.play()
		state_machine.travel("hit_cancel")
		staggered = true
		is_blocking = false
		attacking = false
		movement_lock = false
		decision_processing = false
		current_attack_substate = AttackSubstate.AWAIT
func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	attack_timer = 0
	if anim_name in ["light_damaged_L", "light_damaged_R", "heavy_damaged"]:
		decision_processing = true
	match anim_name:
		"block":
			#state_machine.travel("block")
			is_blocking = true
		"Attack_1":
			movement_lock = true
			attacking = true
			rot_lock = true
		"hit_cancel":
			movement_lock = false
			stunned = true
		"stunned":
			movement_lock = false
			stunned = true
		"light_damaged_L":
			movement_lock = false
			stunned = true
			rot_lock = true
		"light_damaged_R":
			movement_lock = false
			stunned = true
			rot_lock = true
		"heavy_damaged":
			movement_lock = false
			stunned = true
			rot_lock = true
func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"hit_cancel":
			print("whatthefuck?")
		#print("dude")
	movement_lock = false
	attack_timer = 0
	if anim_name in ["Attack_1", "hit_cancel", "block", "light_damaged_L", "light_damaged_R", "heavy_damaged"]:
		attacking = false
		is_blocking = false
		rot_lock = false
		decision_processing = false
		current_attack_substate = AttackSubstate.AWAIT
	match anim_name:
		"block":
			movement_lock = false
			canBeDamaged = true
			damI = damI_cd
		"Attack_1":
			movement_lock = false
			current_attack_substate = AttackSubstate.AWAIT
		"death":
			movement_lock = false
			player.killed += 1.0
			current_state = State.IDLE
			death()
			reset_ai_state()
			curious_stage = 0
			healthbar.health = health
			posturebar.posture = posture

			decision_processing = false
			player.enemies.erase(self)
			queue_free()
			current_attack_substate = AttackSubstate.AWAIT
		"hit_cancel":
			movement_lock = false
			
			decision_processing = false
			velocity = Vector3.ZERO
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
			current_attack_substate = AttackSubstate.AWAIT
			stunned = false
		"stunned":
			movement_lock = false
			
			decision_processing = false
			velocity = Vector3.ZERO
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
			current_attack_substate = AttackSubstate.AWAIT
			stunned = false
		"light_damaged_L":
			movement_lock = false
			
			decision_processing = false
			#velocity = Vector3.ZERO
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
			current_attack_substate = AttackSubstate.AWAIT
			stunned = false
		"light_damaged_R":
			movement_lock = false
			decision_processing = false
			#velocity = Vector3.ZERO
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
			current_attack_substate = AttackSubstate.AWAIT
			stunned = false
		"heavy_damaged":
			movement_lock = false
			
			decision_processing = false
			velocity = Vector3.ZERO
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
			current_attack_substate = AttackSubstate.AWAIT
			stunned = false
	if attacking == false:
		currentweapon.Hurt = false
func _handle_animations(delta) -> void:
	if instaslow == false:
		animationTree.set("parameters/TimeScale/scale", 1)
		#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer.set("speed_scale", 1.0)
		#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer2.set("speed_scale", 1.0)
	else:
		animationTree.set("parameters/TimeScale/scale", 0.01)
		#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer.set("speed_scale", 0.01)
		#$BaseModel3D/MeshInstance3D/Bones_arm/Skeleton3D/BoneAttachment3D/VFX/AnimationPlayer2.set("speed_scale", 0.01)
		
	if current_attack_target:
		looker.look_at(current_attack_target.global_position)

	current_anim = state_machine.get_current_node()
	match current_anim:
		"Attack_1":
			currentweapon.attack_multiplier = 1.5
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.7 && attack_timer < 0.95 ):
				#currentweapon.hit(2)
				global_rotation.y = lerp_angle(global_rotation.y, looker.global_rotation.y, 0.9)
				$SubViewport/Label.set_text("0.7-0.9")
				#global_rotation.y = lerp_angle(global_rotation.y, looker.global_rotation.y, 0.4)
				currentweapon.Hurt = true
				
				currentweapon.hitCD_cap = 0.2
			else:
				currentweapon.Hurt = false
				$SubViewport/Label.set_text("NAN")
		"block":
			damI = 0.0
func spawn_blood(position: Vector3, by):
	var splat = splatScene.instantiate()
	add_child(splat)

	splat.trajectory = (Vector3.ONE * (by.currentweapon.current_velocity) / (abs((by.currentweapon.current_velocity)))) + Vector3.UP / 2.0
	splat.active = true
	for particles in particle_pool:
		if !particles.emitting:
			particles.restart()
			particles.global_position = position
			particles.emitting = true
			particles.draw_pass_1.center_offset = Vector3([-1.5, -1.0, 1.0, 1.5][randi_range(0, 3)], [-0.75, -0.25, 0.25, 0.75][randi_range(0, 3)], 0.0)
			break
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("F"):
		print("=== AI DEBUG INFO ===")
		print("State: ", current_state, " | Attack Substate: ", current_attack_substate)
		print("Target: ", current_attack_target)
		print("Prio: ", prio)
		print("Curious: ", curious, " | Stage: ", curious_stage)
		print("Decision Processing: ", decision_processing)
		print("Movement Lock: ", movement_lock)
		print("Stunned: ", stunned)
		print("Health: ", health, "/", max_health)
