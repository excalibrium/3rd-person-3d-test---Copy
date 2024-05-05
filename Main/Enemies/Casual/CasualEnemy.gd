extends Enemy
class_name Casual_Enemy
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
@onready var playerar = get_tree().get_nodes_in_group("Player")
@onready var player: CharacterBody3D = playerar[0]
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var healthbar = $SubViewport/HealthBar
@onready var vision: PlayerDetector = $Raycast
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
var damI := 0.0
var damI_cd := 0.1
func _ready():
	allies = get_tree().get_nodes_in_group("Ally")
	state_timer = 0.0
	state_machine = animationTree.get("parameters/playback")
	await get_tree().physics_frame
	healthbar.init_health(health)
func _process(delta):
	_handle_variables(delta)
	#print(currentweapon)
		
func _handle_variables(delta):
	if health < 0:
		health = 0
	healthbar.health = health
	if damI < damI_cd:
		damI += delta
func _physics_process(delta):
	if movement_lock:
		navigation_agent.set_target_position(self.global_position)
	distance_to_player = global_position.distance_to(player.global_position)
	_handle_combat()
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
	#print(seeing)
	await get_tree().physics_frame
	_handle_animations()
	#print(velocity)

	if abs(velocity) == Vector3.ZERO:
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
	velocity = lerp(velocity, current_agent_position.direction_to(next_path_position) * SPEED, 0.1)
	move_and_slide()

func _handle_animations():

	if ally_found:
		look_at(target.global_position)
		#$BaseModel3D.global_rotation.y -= PI

	animationTree.set("parameters/conditions/idle", is_moving == false and is_on_floor() and attacking == false and !is_blocking and !stunned)
	animationTree.set("parameters/conditions/is_moving", is_moving == true and is_on_floor() and attacking == false and !is_blocking and !stunned)
	
func _handle_combat():
	if damI >= damI_cd:
		canBeDamaged = true
	else: canBeDamaged = false
#	print(player.get_node("BaseModel3D").global_transform.basis * Vector3(0, 0, 5))
	movement_lock = current_state in ["shield_block_1"] or stunned
	if movement_lock:
		navigation_agent.set_target_position(self.global_position)
	var random
	if state_timer >= state_grace:
		random = randi_range(1, 2)
		if is_blocking and random != 2: #if blocking, make it false if decided to not  
			is_blocking = false
			movement_lock = false
	


	if ally_found:
		if state_timer >= state_grace and !stunned and distance_to_player <= 4: # entered range, and if able to change states and is not stunned, it should:
			state_timer = 0
			if random == 1:
				attacking = true
				movement_lock = true
				state_machine.travel("Attack_1")
			if random == 2:
				state_machine.travel("shield_block_1")
				print_rich("[b][bgcolor=red]blocking[/bgcolor][/b]")
				is_blocking = true
	
	#print(random)
	#print(movement_lock)
func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			movement_lock = false
			attacking = false
		"death_01":
			death()
			stunned = false
			state_machine.travel("idle")
func damage_by(damaged: int):
	#print("YEAOOCH", health)
	#print(damaged)
	if canBeDamaged:
		health -= damaged
		movement_lock = true
		velocity =  player.get_node("BaseModel3D").global_transform.basis * Vector3(0, 0, 5)
		if health <= 0:
			health = 0
			state_machine.travel("death_01")
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
		#print("Closest enemy: ", closest_enemy.name)
		look_at(closest_ally.global_transform.origin, Vector3.UP)
