extends Enemy

@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
@onready var player = $"../Player"
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var target: Node3D

func _ready():
	await get_tree().physics_frame
	print(player.global_position)


func _physics_process(_delta):
	var seeing = $RayCast3D.get_collider()
	target = seeing
	await get_tree().physics_frame
	_handle_animations()
	if velocity != Vector3.ZERO:
		is_moving = true
	else:
		is_moving = false
	if target == player:
		navigation_agent.set_target_position(player.global_position)
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * SPEED
	move_and_slide()

func _handle_animations():
	look_at(player.global_position)
	animationTree.set("parameters/conditions/idle", is_moving == false and is_on_floor() and attacking == false)
	animationTree.set("parameters/conditions/is_moving", is_moving == true and is_on_floor() and attacking == false)
