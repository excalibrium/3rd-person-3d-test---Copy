extends Camera3D

@export var anchor: SpringArm3D
@export var camera_slot: Node3D

var SENSITIVITY = 600

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assert(anchor, "Anchor not set")

func _physics_process(_delta):
	global_transform.origin = global_transform.origin.lerp(camera_slot.global_transform.origin, 0.1)
	rotation = anchor.rotation

func _input(event):
	if event is InputEventMouseMotion:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
