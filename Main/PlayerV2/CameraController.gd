extends Camera3D

@export var player: PlayerController
@export var rotater: Node3D
@export var anchor: SpringArm3D
@export var camera_slot: Node3D
var cameramode = 1
var SENSITIVITY = 1000
var lockOn = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assert(anchor, "Anchor not set")

func _physics_process(_delta):
	var target = player.closest_enemy
	global_transform.origin = global_transform.origin.lerp(camera_slot.global_transform.origin, 0.1)
	rotation = anchor.rotation
	#print(rotater.rotation)
	if lockOn == true:
		rotater.look_at(target.global_position)
		anchor.rotation.y = lerp_angle(anchor.rotation.y, rotater.rotation.y, 0.25)
		anchor.rotation.x = lerp_angle(anchor.rotation.x, rotater.rotation.x, 0.25)
		anchor.rotation.z = lerp_angle(anchor.rotation.z, rotater.rotation.z, 0.25)
func _input(event):
	if event.is_action_pressed("Q"):
		if lockOn == false:
			lockOn = true
		elif lockOn == true:
			lockOn = false
	if event is InputEventMouseMotion and cameramode == 1 and lockOn == false:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
	if event is InputEventScreenDrag and cameramode == 2 and lockOn == false:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
