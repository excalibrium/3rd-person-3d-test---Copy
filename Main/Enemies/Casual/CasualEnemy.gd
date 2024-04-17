extends Enemy

@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
@onready var player = $"../Player"
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var state_machine
var current_state
var target: Node3D
var entered
var state_timer: float
var state_grace: int = 1
var distance_to_player: int 
var tarpos_timer = 0
func _ready():
	state_timer = 0.0
	state_machine = animationTree.get("parameters/playback")
	await get_tree().physics_frame
	print(player.global_position)


func _physics_process(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if tarpos_timer < 3:
		tarpos_timer += delta 
	if state_timer < state_grace:
		state_timer += delta
	current_state = state_machine.get_current_node()
	var seeing = $RayCast3D.get_collider()
	target = seeing
	_handle_combat()

	await get_tree().physics_frame
	_handle_animations()
	print(velocity)
	print(is_moving)
	if abs(velocity) == Vector3.ZERO:
		is_moving = false
	else:
		is_moving = true
	if target == player and !movement_lock and tarpos_timer >= 3:
		tarpos_timer = 0
		navigation_agent.set_target_position(player.global_position)
		if distance_to_player <= 3:
			navigation_agent.set_target_position(global_position + global_transform.basis * Vector3(0, 0, 2))
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	velocity = current_agent_position.direction_to(next_path_position) * SPEED
	move_and_slide()

func _handle_animations():
	look_at(player.global_position)
	animationTree.set("parameters/conditions/idle", is_moving == false and is_on_floor() and attacking == false and !is_blocking)
	animationTree.set("parameters/conditions/is_moving", is_moving == true and is_on_floor() and attacking == false and !is_blocking)
	
func _handle_combat():
	if distance_to_player <= 5:
		var random
		entered = true
		if state_timer >= 3 and !stunned:
			if is_blocking:
				is_blocking = false
			movement_lock = false
			random = randi_range(1, 2)
			state_timer = 0
		if random == 1:
			attacking = true
			movement_lock = true
			state_machine.travel("Attack_1")
		if random == 2:
			print_rich("[b][bgcolor=red]blocking[/bgcolor][/b]")
			is_blocking = true
			movement_lock = true
			state_machine.travel("shield_block_1")
	else:
		entered = false
func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Attack_1":
			movement_lock = false
			attacking = false
			
