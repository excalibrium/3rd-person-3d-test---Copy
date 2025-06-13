extends Node3D

class_name PlayerDetector

@export var ray_count: int = 4
@export var ray_length: float = 20.0
@export var detection_angle: float = 60.0

var raycasts: Array[RayCast3D] = []

func _ready():
	# Remove any children.
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()
	generate_raycasts()

# Sets up raycasts based on the exported values.
func generate_raycasts():
	# Step size, as in, how many degrees between each raycast
	var end_angle = -90 - (detection_angle / 2)
	var start_angle = -90 + (detection_angle / 2)
	var step_size = (end_angle - start_angle) / ray_count
	for idx in ray_count:
		var ray_h = RayCast3D.new()
		var ray_target = calculate_pos_from_angle(ray_length, start_angle + (step_size * idx))
		ray_h.target_position = Vector3(ray_target.x, 0, ray_target.y)
		# Add all raycasts to an array so we can loop over them.
		raycasts.push_back(ray_h)
		add_child(ray_h)

# Returns a new Vector2 based on a given angle (degrees) and length (meters, float)
func calculate_pos_from_angle(length: float, angle: float) -> Vector2:
	var angle_radians = deg_to_rad(angle)
	return Vector2(length * cos(angle_radians), length * sin(angle_radians))

func _physics_process(delta):
	pass

# Returns a reference to the body if a body is found, returns null if not.
func find_bodies() -> Array[CharacterBody3D]:
	var retval: Array[CharacterBody3D]
	for ray in raycasts:
		if !ray.is_colliding():
			continue
		if ray.get_collider() is CharacterBody3D:
			retval.push_back(ray.get_collider())
	return retval
