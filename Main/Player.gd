extends CharacterBody3D

class_name _Player

const SPEED = 3.0
const JUMP_VELOCITY = 4
const SENSITIVITY = 600
const RESET_TIME_THRESHOLD = 0.25

@export var camstick : VirtualJoystick
@onready var staminabar = $CanvasLayer/StaminaBar

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var actionbar = 0
var is_moving = false
var target_rotation = 0
var is_striking = 0
var time_since_release = 0
var is_running = false
var is_dodging = false
var DODGE_SPEED = 8
var dodge_duration = 0.6  # Set the dodge duration in seconds (adjust as needed)
var dodge_timer = 0
var dir_x = 0
var dir_z = 0
var stored_dir_x = 0
var stored_dir_z = 0
var viewrot = 0
var backstep_duration = 0.4
var fwd = false
var bwd = false
var lft = false
var rgt = false
# Add stamina-related variables
var stamina = 100
var max_stamina = 100
var stamina_drain_rate = 20
var stamina_regeneration_rate = 32
var stamina_grace_period = 1  # Set the grace period to 1 seconds (adjust as needed)
var time_since_stamina_used = 0
var animationPlayer
@onready var animationTree = $BaseModel3D/MeshInstance3D/AnimationTree
var deceleration_speed = 10.0  # Adjust the deceleration speed as needed
var cameramode = 1
func _ready():
	if cameramode == 1:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	staminabar.init_stamina(stamina)
	animationPlayer = $BaseModel3D/MeshInstance3D/AnimationPlayer
#	animationPlayer.play("idle", 1, 1)
signal test
func _physics_process(delta):
	$Camera3D.global_transform.origin = $Camera3D.global_transform.origin.lerp($view_anchor/Node3D.global_transform.origin, 0.1)
	$Camera3D.rotation = $view_anchor.rotation
	if Input.is_action_pressed("LongBar") and is_on_floor():
		actionbar += 1
		time_since_release = 0  # Reset the time counter when the action is pressed

	if Input.is_action_just_pressed("ui_accept"):
		test.emit()

	# Add gravity when not on the floor.
	if not is_on_floor():
		velocity.y -= gravity * delta * 1.125
	# Handle Stamina based calculations.
	if time_since_stamina_used < stamina_grace_period:
		time_since_stamina_used += delta
	if stamina < 0:
		stamina = 0
		time_since_release = 0
	staminabar.stamina = stamina
	# Handle Running.
	if time_since_release < RESET_TIME_THRESHOLD:
		time_since_release += delta
	else:
		actionbar = 0  # Reset actionbar to 0 after the specified time threshold

	# Set is_running based on the condition
	if actionbar > 20 and stamina > 1 and is_moving:
		is_running = true
		stamina -= delta * stamina_drain_rate  # Drain stamina while running
		time_since_stamina_used = 0  # Reset the grace period timer when stamina is used
	else:
		is_running = false

		# If the character is not running and the grace period has passed, regenerate stamina.
		if time_since_stamina_used >= stamina_grace_period and stamina < max_stamina:
			stamina += delta * stamina_regeneration_rate

	# Handle jump.
	if actionbar > 20 and is_running and is_moving and Input.is_action_just_pressed("LongBar") and is_on_floor():
		if abs(velocity.x) > 2 or abs(velocity.z) > 2:
			stamina -= 10
			velocity.y = JUMP_VELOCITY
			actionbar = 0
			time_since_stamina_used = 0
	if is_on_floor():  # Only apply movement and rotation when not on the floor (jumping) and nah i'd win.
		var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
		var direction = ($view_anchor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var dirview = $view.transform.basis.z.normalized()

		dir_x = direction.x
		dir_z = direction.z
		# Adjust speed based on whether running or not.
		var speed_multiplier = 1.0
		if is_running:
			speed_multiplier = 1.5  # Adjust the multiplier as needed

# Handle dodging.
		if is_dodging and is_striking < 2:
			dodge_timer += delta
			if is_moving:
				if dodge_timer <= dodge_duration:
					actionbar = 0
					# Apply dodging velocity when moving
					velocity.x = stored_dir_x * DODGE_SPEED * speed_multiplier
					velocity.z = stored_dir_z * DODGE_SPEED * speed_multiplier
					time_since_stamina_used = 0
				else:
			# Reset dodging state
					is_dodging = false
					dodge_timer = 0
		if is_dodging and is_striking < 2:
			dodge_timer += delta
			if !is_moving:
				if dodge_timer <= backstep_duration:
					# Apply faster dodge when standing still
					velocity.x = -dirview.x * DODGE_SPEED * speed_multiplier / 2
					velocity.z = -dirview.z * DODGE_SPEED * speed_multiplier / 2
					time_since_stamina_used = 0
				else:
			# Reset dodging state
					is_dodging = false
					dodge_timer = 0
		if not is_dodging:
			if direction and is_striking < 2:
			# Calculate rotation angle based on movement direction.
				target_rotation = atan2(direction.x, direction.z)
				#$DR.rotation.y = lerp_angle($DR.rotation.y, target_rotation, 0.4)  # Adjust the interpolation factor as needed
				$BaseModel3D.rotation.y = lerp_angle($BaseModel3D.rotation.y, $view.rotation.y, 0.2)
				$view.rotation.y = lerp_angle($view.rotation.y, target_rotation, 0.2)  # Adjust the interpolation factor as needed
				velocity.x = lerpf(velocity.x, dirview.x * speed_multiplier * 3, 0.2)
				velocity.z = lerpf(velocity.z, dirview.z * speed_multiplier * 3, 0.2)

				is_moving = true
			else:
				if is_moving:
				# If not actively moving, finish the rotation smoothly using the stored target_rotation.
					$BaseModel3D.rotation.y = target_rotation
					$view.rotation.y = target_rotation  # Adjust the interpolation factor as needed
					
					#$DR.rotation.y = target_rotation  # Adjust the interpolation factor as needed
					is_moving = false

				velocity.x = lerpf(velocity.x, 0, 0.2)
				velocity.z = lerpf(velocity.z, 0, 0.2)
		animationTree.set("parameters/conditions/Idle", input_dir == Vector2.ZERO)
		animationTree.set("parameters/conditions/move", input_dir != Vector2.ZERO)
	move_and_slide()

func _input(event):
	if event.is_action_pressed("interact"):
		print(fwd)
		print(bwd)
		print(lft)
		print(rgt)
	if event.is_action_pressed("moveForward"):
		fwd = true
		lft = false
		rgt = false
		if bwd:
			print("180 from FWD to BWD")
			bwd = false
	if event.is_action_pressed("moveBackward"):
		bwd = true
		lft = false
		rgt = false
		if fwd:
			print("180 from BWD to FWD")
			fwd = false
	if event.is_action_pressed("moveLeft"):
		lft = true
		bwd = false
		fwd = false
		if rgt:
			print("180 from LFT to RGT")
			rgt = false
	if event.is_action_pressed("moveRight"):
		rgt = true
		bwd = false
		fwd = false
		if lft:
			print("180 from RGT to LFT")
			lft = false
	if event.is_action_pressed("LeftClick") and !is_dodging and is_on_floor():
		is_striking = 1
	if Input.is_action_just_released("LongBar") and is_on_floor():
		if actionbar < 20 and !is_dodging and is_striking < 2 and stamina > 1:
			stored_dir_x = dir_x
			stored_dir_z = dir_z
			$view.rotation.y = target_rotation  # Adjust the interpolation factor as needed
			stamina -= 10
			is_dodging = true

		if actionbar > 1 and is_moving:
			time_since_release = 0  # Reset the time counter when releasing LongBar with actionbar > 1
			if stamina > 1:
				time_since_stamina_used = 0  # Reset the grace period timer when stamina is used
		else:
			actionbar = 0

	if event.is_action_pressed("Escape"):
		get_tree().quit()
		return

	if event is InputEventMouseMotion and cameramode == 1:
		$view_anchor.rotation.y -= event.relative.x / SENSITIVITY
		$view_anchor.rotation.x -= event.relative.y / SENSITIVITY
		$view_anchor.rotation.x = clamp($view_anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
	if event is InputEventScreenDrag and cameramode == 2:
		$view_anchor.rotation.y -= event.relative.x / SENSITIVITY
		$view_anchor.rotation.x -= event.relative.y / SENSITIVITY
		$view_anchor.rotation.x = clamp($view_anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
		
		

#func _on_animation_player_animation_started(anim_name): unused until plan 2025
	#if anim_name == "reaper_swing_1":
		#is_striking = true
		#print("STARTattack")
	
#func _on_animation_player_animation_finished(anim_name):
	#if anim_name == "reaper_swing_1":
		#print("attackDONE")
		#is_striking = false
		#animationPlayer.play("reaper_swing_1_recovery", 0, 1)
	#else:
		#animationPlayer.play("idle", 1, 8)
