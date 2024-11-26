extends Camera3D

@export var mini_camera_mapper_player : MeshInstance3D
@export var player: PlayerController
@export var rotater: Node3D
@export var anchor: SpringArm3D
@export var camera_slot: Node3D
var strength := 10.0
var cameramode = 1
var SEXES := 0.0
var SENSITIVITY = 1000
var lockOn = false
var target_change := false
var value
var testvar
var mouse_time := 0.0
var mouse_cd := 0.1
var target_change_cd := 0.05
var target_change_time := 0.0
var next
var current_one
var affirmed_target
const JOY_DEADZONE : float = 0.15
const JOY_V_SENS : float = 0.5
const JOY_H_SENS : float = 0.5
var camera_velocity := Vector3.ZERO
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assert(anchor, "Anchor not set")

func _process(delta: float) -> void:

	anchor.rotate_y(deg_to_rad(-camera_velocity.y))
	anchor.rotation.x += deg_to_rad(-camera_velocity.x)

	anchor.rotation.x =clamp(anchor.rotation.x,deg_to_rad(-80),deg_to_rad(80))
	if mouse_time < mouse_cd:
		mouse_time += delta

	if target_change_time < target_change_cd:
		target_change_time += delta

	$"../CanvasLayer/Label".text = str(target_change) + str(testvar)

	if owner.owner.lockOn == true:
		if owner.owner.closest_enemy == null:
			owner.owner.lockOn = false
			return
		elif owner.owner.closest_enemy_body.global_position.distance_to(global_position) > owner.owner.max_lock_range: #problem here!!!!
			lockOn = false
			owner.owner.lockOn = false
		if owner.owner.closest_enemy.global_position.distance_to(global_position) > owner.owner.max_lock_range:
			target_change = false
		$"../Node3D".look_at(owner.owner.closest_enemy.global_position)
		rotater.global_rotation.y = lerp_angle(rotater.global_rotation.y, $"../Node3D".global_rotation.y, 0.25)
		anchor.global_rotation.y = lerp_angle(anchor.global_rotation.y, $"../Node3D".global_rotation.y, 0.25)
		if target_change_time >= target_change_cd:
			$pivot.global_rotation.x = lerp_angle($pivot.global_rotation.x, 0, 0.1)
		else:
			$pivot.global_rotation.x = 0
		var speed_var = owner.owner.speed + 1
		var tester_var = testvar /1000 + 1
		if target_change_time >= target_change_cd:
			$pivot.global_rotation.y = lerp_angle($pivot.global_rotation.y, rotater.global_rotation.y, 0.025 * speed_var * tester_var)
		else:
			$pivot.global_rotation.y = rotater.global_rotation.y
		$pivot.global_position = lerp($pivot.global_position, global_position, 0.1)

	elif owner.owner.lockOn == false:
		$pivot.global_rotation.x = lerp_angle($pivot.global_rotation.x, anchor.global_rotation.x, 0.5)
		$pivot.global_rotation.y = lerp_angle($pivot.global_rotation.y, anchor.global_rotation.y, 0.5)
		$pivot.global_position = global_position
	#print(target_change_time)

func _physics_process(delta: float) -> void:
	if $pivot/RayCast3D.is_colliding() == true:
		strength = global_position.distance_to($pivot/RayCast3D.get_collision_point())
		$pivot/RayCast3D/MeshInstance3D.global_position = lerp($pivot/RayCast3D.global_position, $pivot/RayCast3D.get_collision_point(), 0.95)
	if $pivot/RayCast3D.is_colliding() == false:
		$pivot/RayCast3D/MeshInstance3D.global_transform.origin = $pivot/RayCast3D.global_transform.origin - $pivot/RayCast3D.global_transform.basis.z * 12
		strength = 4.0
	#print($pivot.rotation)
	#print(owner)
	var target = player.closest_enemy
	global_transform.origin = global_transform.origin.lerp(camera_slot.global_transform.origin, 0.3)
	rotation = anchor.rotation
	#print(rotater.rotation)
	var best_value = INF
	var event = Input
	#before loop we take var
	if affirmed_target and affirmed_target != current_one:
		current_one = affirmed_target
		target_change_time = 0.0
	for enemy in owner.owner.enemies:
		enemy.raycast.global_position.y = global_position.y
		value = enemy.mini_camera_mapper_thingy.global_position.distance_to(mini_camera_mapper_player.global_position)
		#value = value * sqrt(sqrt(sqrt(sqrt(global_position.distance_to(enemy.global_position)))))
		enemy.locking_value = value
		if enemy.global_position.distance_to(global_position) > owner.owner.max_lock_range:
			enemy.mini_camera_mapper_thingy.global_position = enemy.global_position
		if target_change_time >= target_change_cd and value < best_value and target_change == false and enemy.global_position.distance_to(global_position) <= owner.owner.max_lock_range: #lower the value, more prone the lock on is to lock on to the enemy
			best_value = value
			#if next != current_one:
				#print("next is not the prev one so:")
			#print(enemy)
			#print(current_one, "sex")
			affirmed_target = enemy
	if owner.owner.closest_enemy != current_one:
		target_change_time = 0.0
		SEXES += 1
			#owner.owner.closest_enemy = next
			#if current_one != next and target_change_time >= target_change_cd:
				#SEXES += 1
				#owner.owner.closest_enemy = enemy
				#target_change_time = 0.0
				#target_change = true
	owner.owner.closest_enemy = affirmed_target

	if lockOn == true:
		anchor.rotation.y = lerp_angle(anchor.rotation.y, rotater.rotation.y, 0.25)
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(30) , deg_to_rad(-20))
		anchor.rotation.z = lerp_angle(anchor.rotation.z, rotater.rotation.z, 0.25)
	if owner.owner.lockOn == false:
		
		target_change = false
	if Input.is_anything_pressed()==false or mouse_time > mouse_cd:
		target_change = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		#print(owner.owner.closest_enemy, "sex2", current_one)
		mouse_time = 0
		testvar = abs(event.relative.x + event.relative.y)
	else:
		testvar = 1

	if event is InputEventJoypadMotion:
		mouse_time = 0
		testvar = abs(event.axis_value)
	else:
		testvar = 1
	if event.is_action_pressed("Q") and owner.owner.closest_enemy:
		if lockOn == false and owner.owner.closest_enemy.global_position.distance_to(global_position) < owner.owner.max_lock_range:
			lockOn = true
			target_change = true
		if lockOn == true:
			lockOn = false

	if owner.owner.lockOn == true:
		if event is InputEventMouseMotion:
			# Fix: Use rotate_object_local or rotate_x/y instead of directly modifying global_rotation
			$pivot.rotate_x(-event.relative.y * 0.001)  # Reduced sensitivity for testing
			$pivot.rotate_y(-event.relative.x * 0.001)
			target_change = true

		if event is InputEventMouseMotion and abs(event.relative.x + event.relative.y) > 3:
			testvar = abs(event.relative.x + event.relative.y)
			target_change = false

	if event is InputEventMouseMotion and cameramode == 1 and owner.owner.lockOn == false:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
	if event is InputEventJoypadMotion:
		if event.axis == 2:
			$"../CanvasLayer/Label4".text = str(event) + " " + str(event.axis) + " " + str(event.axis_value)
			if abs(event.get_axis_value()) > JOY_DEADZONE:
				camera_velocity.y = (event.get_axis_value() * JOY_H_SENS)
			else:
				camera_velocity.y = 0
		if event.axis == 3:
			$"../CanvasLayer/Label4".text = str(event) + " " + str(event.axis) + " " + str(event.axis_value)
			if abs(event.get_axis_value()) > JOY_DEADZONE:
				camera_velocity.x = (event.get_axis_value() * JOY_V_SENS)
			else:
				camera_velocity.x = 0
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
	elif event is InputEventScreenDrag and cameramode == 2 and owner.owner.lockOn == false:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(60))
