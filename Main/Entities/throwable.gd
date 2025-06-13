extends RigidBody3D

var target = null
@onready var looker = $lookat
#@onready var velocity = $velocity
var timer := 0.0
var born := 0.0
var is_thrown: bool = false

func _ready():
	pass

func _process(_delta):
	born += _delta
	if born >= 15.0:
		queue_free()

func _physics_process(_delta: float) -> void:
	if !is_thrown:
		return
	var velocity = linear_velocity
	var look_direction = velocity.normalized()
	$lookat/MeshInstance3D.global_position = global_position + look_direction
	#if look_direction.normalized().dot(Vector3.UP) > 0.00000000000000001:
	#global_position = look_direction / 0.999999
	#if global_position != global_position + look_direction:
	#if look_direction != Vector3(0.0, 0.0, 0.0):
	look_at(global_position + look_direction) #colinear eror
	
