extends Enemy
class_name Casual_EnemyD

@export var mini_camera_mapper_thingy : MeshInstance3D
@export var raycast : RayCast3D
var player
var locking_value
func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]

	main_ready()
	state_machine = animationTree.get("parameters/stater/playback")
	healthbar.init_health(health)
	prio = null
	weapons_in_tree = get_tree().get_nodes_in_group("weapon")
	for each_weapon in weapons_in_tree:
		if each_weapon.owner == self:
			currentweapon = each_weapon

func _process(delta: float) -> void:
	_handle_animations(delta)
	_handle_var(delta)

func _handle_var(delta):
	$SubViewport/Label3.text = str(locking_value)
	raycast.look_at(player.cam.global_position)
	raycast.global_rotation.z -= PI
	#raycast.global_rotation.y -= PI
	raycast.global_rotation.x -= PI
	mini_camera_mapper_thingy.global_position = raycast.get_collision_point()
	#print(raycast.get_collider())
	if raycast.get_collider() == null:
		mini_camera_mapper_thingy.global_position = global_position
	#damI
	if damI < damI_cd:
		damI += delta
	if damI >= damI_cd:
		canBeDamaged = true
	else:
		canBeDamaged = false
	
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
	if think_timer < 1.0 / adrenaline:
			think_timer += delta
	if think_timer >= 1.0 / adrenaline:
		think()
		
		think_timer = 0.0

func _physics_process(delta: float) -> void:
	if stall_meter < stall_cd:
		stall_meter += delta
	animationTree.set("parameters/stater/conditions/walk", staggered == false and is_moving == true and attacking == false and is_blocking == false and is_running == false)
	animationTree.set("parameters/stater/conditions/idle", staggered == false and is_moving == false and attacking == false and is_blocking == false and is_running == false)
	if prio:
		$Raycast.look_at(prio.global_position)
	var current_position = global_position
	var next_position = nav.get_next_path_position()
	nav.velocity = Vector3.ZERO
	move_and_slide()
	if is_on_floor() == false:
		velocity.y -= 1
	if velocity.length() > 0.1 and rot_lock == false and stunned == false and lock_on == false:
		var look_direction = velocity.normalized()
		var current_rotation = basis.get_rotation_quaternion()
		var target_rotation = Quaternion.from_euler(Vector3(0, atan2(-look_direction.x, -look_direction.z), 0))
		var new_rotation = current_rotation.slerp(target_rotation, 5.0 * delta)
		basis = Basis(new_rotation)
	if lock_on == true:
		global_rotation = looker.global_rotation
	if curious_stage == 2:
		$RayCast.look_at(prio.global_position)
	if movement_lock == false and stunned == false:
		velocity = velocity.move_toward(nav.velocity, 0.1)
	else:
		velocity = Vector3.ZERO

func _on_alertness_sphere_area_entered(area: Area3D) -> void:
	if area.is_in_group("alerter"):
		alert(1 / pow(global_position.distance_to(area.global_position), 1.0/6.0), area.owner)


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	nav.velocity = nav.velocity.move_toward(safe_velocity, 0.1)

func damage_by(damaged):
	if health <= 0:
		stunned = true
		state_machine.stop()
		state_machine.travel("death")
		health = 0
	if canBeDamaged:
		health -= damaged
	damI = 0.0
	healthbar.health = health 

func guard_break():
	pass


func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	attack_timer = 0
	match anim_name:
		"block":
			#print("block")
			state_machine.travel("block")
			decision_processing = true
			is_blocking = true
		"Attack_1":
			decision_processing = true 
			attacking = true
			rot_lock = true
		"hit_cancel":
			stunned = true
func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	attack_timer = 0
	match anim_name:
		"block":
			decision_processing = false
			#print("IM DONE block")
			movement_lock = false
			is_blocking = false
			canBeDamaged = true
			damI = damI_cd
		"Attack_1":
			decision_processing = false
			#print("IM DONE")
			movement_lock = false
			#global_rotation.y = lerp_angle(global_rotation.y, looker.global_rotation.y, 0.5)
			#$BaseModel3D/MeshInstance3D/Viego/Skeleton3D/CustomModifier.setreal = true
			attacking = false
			rot_lock = false
		"death":
			current_state = State.IDLE
			attacking = false
			death()
			reset_ai_state()
			curious_stage = 0
			healthbar.health = health
			decision_processing = false
		"hit_cancel":
			decision_processing = false
			reset()
			attack_buffer = 0
			attack_timer = 0
			stunned = false 
			attacking = false
	if attacking == false:
		currentweapon.Hurt = false
func _handle_animations(delta) -> void:
	#print(nav.is_target_reached())
	#print(common.pick_random(), "SEKKUSU")
	if current_attack_target:
		looker.look_at(current_attack_target.global_position)

	current_anim = state_machine.get_current_node()
	match current_anim:
		"Attack_1":
			currentweapon.attack_multiplier = 1.5
			if instaslow == false:
				attack_timer += delta
			if ( attack_timer >= 0.7 && attack_timer < 0.95 ):
				global_rotation.y = lerp_angle(global_rotation.y, looker.global_rotation.y, 1.0)
				$SubViewport/Label.set_text("0.7-0.9")
				#global_rotation.y = lerp_angle(global_rotation.y, looker.global_rotation.y, 0.4)
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.2
			else:
				currentweapon.Hurt = false
				$SubViewport/Label.set_text("NAN")
		"block":
			#print("bloocckckcac")
			damI = 0.0
