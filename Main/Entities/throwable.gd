extends RigidBody3D

var target = null
@onready var looker = $lookat
@onready var velocity = $velocity
var timer := 0.0

func _physics_process(delta):
	var velocity = linear_velocity
	if velocity.length() > 0:
		var look_direction = velocity.normalized()
		if target:
			#look_at(global_position - target.global_position + Vector3(0,1,0))
			global_position = lerp(global_position, target.global_position + Vector3(0,1,0), 0.05)
		elif look_direction.normalized().dot(Vector3.UP) > 0.0000000000000000000001:
			look_at(global_position - look_direction)
