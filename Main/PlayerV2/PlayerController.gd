extends Character

class_name PlayerController

var speed_multiplier = 1.0
var target_rotation: float = 0.0

func _physics_process(delta):
	_handle_movement()
	_handle_animations()
	super(delta) # Call the parent class's _physics_process

func _handle_movement():
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	var camera_direction: Vector3 = ($Camera/view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var character_direction = $view.transform.basis.z.normalized()
	if input_dir.length() > 0:
		target_rotation = atan2(camera_direction.x, camera_direction.z)
		$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.2)
		$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.2)
		velocity.x = lerpf(velocity.x, character_direction.x * speed_multiplier * 3, 0.2)
		velocity.z = lerpf(velocity.z, character_direction.z * speed_multiplier * 3, 0.2)
	else:
		velocity.x = lerpf(velocity.x, 0, 0.2)
		velocity.z = lerpf(velocity.z, 0, 0.2)

func _handle_animations():
	# Do anims.
	pass