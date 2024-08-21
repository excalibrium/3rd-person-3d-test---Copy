extends Enemy
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
@onready var playerar = get_tree().get_nodes_in_group("Player")
@onready var player: CharacterBody3D = playerar[0]
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var healthbar = $SubViewport/HealthBar
@onready var vision: PlayerDetector = $Raycast
@onready var timer = $BaseModel3D/Hitbox/CPUParticles3D/emissionTimer
var state_machine
var current_state
var target: Node3D
var entered := false
var state_timer: float
var state_grace: int = 2
var distance_to_player: int 
var tarpos_timer = 0
var seeing: Array[CharacterBody3D]
var ally_found := false
var allies := []
var closest_ally = null
var knocked
var canBeDamaged := false
var shield_break
var insta
func _ready():
	weapons_in_tree = get_tree().get_nodes_in_group("weapon")
	for a in weapons_in_tree:
		if a.owner == self:
			currentweapon = a
	movement_lock = true
	stunned = true
	allies = get_tree().get_nodes_in_group("Ally")
	state_timer = 0.0
	state_machine = animationTree.get("parameters/stater/playback")
	await get_tree().physics_frame
	healthbar.init_health(health)
func _process(delta):
	_handle_variables(delta)
		
func _handle_variables(delta):
	if health < 0:
		health = 0
	healthbar.health = health
	if damI < damI_cd:
		damI += delta
func _physics_process(delta):
	weapons_in_tree = get_tree().get_nodes_in_group("weapon")
	if not is_on_floor():
		velocity.y -= gravity * 1.125
	if movement_lock:
		navigation_agent.set_target_position(self.global_position)
	distance_to_player = global_position.distance_to(player.global_position)
	_handle_combat(delta)
	if tarpos_timer < 3:
		tarpos_timer += delta 
	if state_timer < state_grace:
		state_timer += delta
	current_state = state_machine.get_current_node()
	
	# Get all bodies in vision from player_detector
	seeing = vision.find_bodies()
	# Select the first body that is an ally as target
	for body in seeing:
		if body.is_in_group("Ally"):
			ally_found = true
			target = body
	if seeing == []:
		ally_found = false
	await get_tree().physics_frame
	_handle_animations()

	if abs(velocity.x) <= 0.5 and abs(velocity.z) <= 0.5:
		is_moving = false
	else:
		is_moving = true
	if ally_found and !movement_lock and tarpos_timer >= 0.5:
		tarpos_timer = 0
		navigation_agent.set_target_position(target.global_position)
		if distance_to_player <= 3:
			navigation_agent.set_target_position(global_position + global_transform.basis * Vector3(0, 0, 2))
	#if navigation_agent.is_navigation_finished() and !knocked:
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	velocity.x = lerp(velocity.x, current_agent_position.direction_to(next_path_position).x * SPEED, 0.1)
	velocity.z = lerp(velocity.z, current_agent_position.direction_to(next_path_position).z * SPEED, 0.1)
	move_and_slide()

func _handle_animations():
	if ally_found:
		look_at(target.global_position)

	animationTree.set("parameters/stater/conditions/idle", is_moving == false and is_on_floor() and attacking == false and !is_blocking and !stunned)
	animationTree.set("parameters/stater/conditions/move", is_moving == true and is_on_floor() and attacking == false and !is_blocking and !stunned)
	
func _handle_combat(delta):
	if instaslow == false:
		animationTree.set("parameters/TimeScale/scale", 1)
	else:
		animationTree.set("parameters/TimeScale/scale", 0.01)
	$BaseModel3D/Hitbox/CPUParticles3D.global_rotation.y = player.get_node("BaseModel3D").get_node("MeshInstance3D").global_rotation.y - PI/2

	#print("current weapon: ",currentweapon," hurting: ", currentweapon.Hurt)
	if !is_blocking:
		$BaseModel3D/MeshInstance3D/Viego/Skeleton3D/BoneAttachment3D2/Shield/Area3D/CollisionShape3D.disabled = true
	else:
		$BaseModel3D/MeshInstance3D/Viego/Skeleton3D/BoneAttachment3D2/Shield/Area3D/CollisionShape3D.disabled = false
		damI = 0.0
	if damI >= damI_cd:
		canBeDamaged = true
	else: canBeDamaged = false
	movement_lock = current_state in ["shield_block_1"] or stunned
	if movement_lock:
		navigation_agent.set_target_position(self.global_position)
	var random
	if state_timer >= state_grace:
		random = randi_range(1, 3)
		if is_blocking and random != 3: #if blocking, make it false if decided to not  
			is_blocking = false
			movement_lock = false
	if !attacking:
		currentweapon.Hurt = false
	match current_state:
		"Attack_1":
			currentweapon.attack_multiplier = 2
			attack_timer += delta
			if (attack_timer >= 0.7 && attack_timer < 1.0 ):
				currentweapon.Hurt = true
				currentweapon.hitCD_cap = 0.135
			else:
				currentweapon.Hurt = false
	if weaponCollidingWall and attacking and currentweapon.Hurt == true or player.is_blocking == true and attacking and currentweapon.Hurt == true:
		stunned = true
		attacking = false
		state_machine.travel("hit_cancel")
	movement_lock = current_state in ["Attack_1", "Attack_1_to_idle", "death"]
	if ally_found:
		if state_timer >= state_grace and !stunned and distance_to_player <= 4: # entered range, and if able to change states and is not stunned, it should:
			state_timer = 0
			if random == 1 or random == 2:
				attacking = true
				movement_lock = true
				state_machine.travel("Attack_1")
			if random == 3:
				state_machine.travel("shield_block_1")
				#print_rich("[b][bgcolor=red]blocking[/bgcolor][/b]")
				is_blocking = true

func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			movement_lock = false
			attacking = false
		"death":
			death()
			stunned = false
			state_machine.travel("idle")
		"hit_cancel":
			state_machine.travel("idle")
			attack_buffer = 0
			attack_timer = 0
			stunned = false
			attacking = false
func damage_by(damaged: int):
	timer.start()
	if canBeDamaged:
		$BaseModel3D/Hitbox/CPUParticles3D.emitting = true
		health -= damaged
		movement_lock = true
		#velocity += player.global_position * Vector3(0, 0, 10)
		
		if health <= 0:
			health = 100
			stunned = true
	healthbar.health = health
	damI = 0.0

func detection():

	var closest_distance = INF
	for enemy in allies:
		var distance = position.distance_to(enemy.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_ally = enemy
			
	if closest_ally != null:
		look_at(closest_ally.global_transform.origin, Vector3.UP)


func _on_animation_tree_animation_started(anim_name):
	match anim_name:
		"Attack_1":
			attack_timer = 0


func _on_emission_timer_timeout():
	$BaseModel3D/Hitbox/CPUParticles3D.emitting = false
	timer.stop()

func guard_break():
	if is_blocking:
#		shield_break = true
		stunned = true
		state_machine.travel("hit_cancel")
		is_blocking = false

func push(towards):
	if towards == "left":
		velocity += global_transform.basis * Vector3(10, 0, 0)
	if towards == "right":
		velocity += global_transform.basis * Vector3(-10, 0, 0)
	if towards == "fwd":
		velocity += global_transform.basis * Vector3(0, 0, -10)
	if towards == "bwd":
		velocity += global_transform.basis * Vector3(0, 0, 10)
	if towards == "bwdplayer":
		var direction: Vector3 = global_position - player.global_position
		direction = direction.normalized()
		velocity += direction * 10
	return
