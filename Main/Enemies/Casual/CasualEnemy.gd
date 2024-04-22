extends Enemy
class_name Casual_Enemy
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
@onready var player = $"../Player"
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var raycasts: Array[RayCast3D] = []
var state_machine
var current_state
var target: Node3D
var entered := false
var state_timer: float
var state_grace: int = 2
var distance_to_player: int 
var tarpos_timer = 0
var seeing: Array
func _ready():
	var raycasts_node = get_node("Raycast") # Adjust the path as necessary
	for child in raycasts_node.get_children():
		if child is RayCast3D:
			raycasts.append(child)
	state_timer = 0.0
	state_machine = animationTree.get("parameters/playback")
	await get_tree().physics_frame


func _physics_process(delta):
	
	distance_to_player = global_position.distance_to(player.global_position)
	_handle_combat()
	if tarpos_timer < 3:
		tarpos_timer += delta 
	if state_timer < state_grace:
		state_timer += delta
	current_state = state_machine.get_current_node()
	for i in raycasts:
		seeing.push_front(i.get_collider())
		if seeing.size() >= 36:
			seeing = [i.get_collider()]

	for i in range(seeing.size()):
		if seeing[i] != null and seeing[i].is_in_group("Ally"):
			target = seeing[i]
			break # Exit the loop once the first ally is found

	await get_tree().physics_frame
	_handle_animations()
	#print(velocity)
	#print(is_moving)
	if abs(velocity) == Vector3.ZERO:
		is_moving = false
	else:
		is_moving = true
	for element in seeing:
		if element != null and element.is_in_group("Ally") and !movement_lock and tarpos_timer >= 0.5:
			tarpos_timer = 0
			navigation_agent.set_target_position(target.global_position)
			if distance_to_player <= 3:
				navigation_agent.set_target_position(global_position + global_transform.basis * Vector3(0, 0, 2))
			break # Exit the loop once the conditions are met for the first ally
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	velocity = current_agent_position.direction_to(next_path_position) * SPEED
	move_and_slide()

func _handle_animations():
	for element in seeing:
		if element != null and element.is_in_group("Ally"):
			look_at(target.global_position)
			break
	animationTree.set("parameters/conditions/idle", is_moving == false and is_on_floor() and attacking == false and !is_blocking)
	animationTree.set("parameters/conditions/is_moving", is_moving == true and is_on_floor() and attacking == false and !is_blocking)
	
func _handle_combat():
	var random
	if state_timer >= state_grace:
		random = randi_range(1, 2)
		if is_blocking and random != 2: #if blocking, make it false if decided to not  
			is_blocking = false
			movement_lock = false
	if distance_to_player <= 4:
		entered = true
		if entered and state_timer >= state_grace and !stunned: # entered range, and if able to change states and is not stunned, it should:
			movement_lock = false
			state_timer = 0
			if random == 1:
				attacking = true
				movement_lock = true
				state_machine.travel("Attack_1")
			if random == 2:
				state_machine.travel("shield_block_1")
				print_rich("[b][bgcolor=red]blocking[/bgcolor][/b]")
				is_blocking = true
				navigation_agent.set_target_position(self.global_position)
				movement_lock = true

	else:
		entered = false
	print(random)
func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			movement_lock = false
			attacking = false
			
