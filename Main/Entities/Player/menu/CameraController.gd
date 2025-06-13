extends Camera3D

@export var Mlooker : Node3D
@export var Mray : Node3D
var in_menu := false
var in_ingame_menu := false
@export var ingame_menu : Node3D

var active := true
@export var Mcursor : Node3D
var pressed_rot
@export var mini_camera_mapper_player : MeshInstance3D
@export var player: PlayerController
@export var rotater: Node3D
@export var anchor: SpringArm3D
@export var camera_slot: Node3D
@export var pivot_ray : RayCast3D
@export var interact_ray : RayCast3D
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
@onready var pivot_mesh = $pivot/RayCast3D/MeshInstance3D
func _ready():
	player = get_tree().get_nodes_in_group("Player")[0]
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assert(anchor, "Anchor not set")

func _process(delta: float) -> void:
	$"../CanvasLayer/cursor_type".set_text(str(Mcursor.main_type))
	$"../CanvasLayer/cursor_prev_type".set_text(str(Mcursor.type_history))
	#print(global_rotation_degrees)
	#print(rotation_degrees)
	Mcursor.look_at(global_position)
	Mray.look_at(Mcursor.global_position)
	
	if in_menu == false and in_ingame_menu == false:
		Mcursor.global_position = $MenuCursorSlot.global_position
	
	anchor.rotate_y(deg_to_rad(-camera_velocity.y))
	anchor.rotation.x += deg_to_rad(-camera_velocity.x)
	anchor.rotation.x =clamp(anchor.rotation.x,deg_to_rad(-60),deg_to_rad(60))
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
		$locked.look_at(owner.owner.closest_enemy.global_position)
		rotater.global_rotation.y = lerp_angle(rotater.global_rotation.y, $locked.global_rotation.y, 0.25)
		anchor.global_rotation.y = lerp_angle(anchor.global_rotation.y, $locked.global_rotation.y, 0.25)
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
	if active == true:
		global_transform.origin = global_transform.origin.lerp(camera_slot.global_transform.origin, 0.3)
	if owner.owner.lockOn == true:
		$pivot.global_rotation.x = lerp_angle($pivot.global_rotation.x, anchor.global_rotation.x, 0.5)
		$pivot.global_rotation.y = lerp_angle($pivot.global_rotation.y, anchor.global_rotation.y, 0.5)
		anchor.look_at(affirmed_target.global_position)
		#print("loked")
		#anchor.rotation.x = $locked.rotation.x * 3.0
	rotation.y = lerp_angle(rotation.y, anchor.rotation.y, 0.25)
	rotation.x = lerp_angle(rotation.x, anchor.rotation.x, 0.25)
	rotation.z = lerp_angle(rotation.z, anchor.rotation.z, 0.25)
	
	#GLogger.LOG_INFO(str(global_rotation_degrees.x))
	if abs(global_rotation_degrees.x) >= 70.0:
		#global_rotation.y = $BaseModel3D.global_rotation.y #once
		lockOn = false
		owner.owner.lockOn = false

	var _target = player.closest_enemy
	#print(rotater.rotation)
	var best_value = INF
	#before loop we take var
	if affirmed_target and affirmed_target != current_one:
		current_one = affirmed_target
		target_change_time = 0.0
	for enemy in owner.owner.enemies:
		value = enemy.mini_camera_mapper_thingy.global_position.distance_to(mini_camera_mapper_player.global_position)
		value = value * sqrt(sqrt(sqrt(sqrt(global_position.distance_to(enemy.global_position)))))
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

	if lockOn == true: #deprecated
		anchor.rotation.y = lerp_angle(anchor.rotation.y, rotater.rotation.y, 0.25)
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(30) , deg_to_rad(-20))
		#if affirmed_target:
		#anchor.look_at(affirmed_target.global_position)
		anchor.rotation.z = lerp_angle(anchor.rotation.z, rotater.rotation.z, 0.25)
	if owner.owner.lockOn == false:
		
		target_change = false
	if Input.is_anything_pressed()==false or mouse_time > mouse_cd:
		target_change = true
func _physics_process(_delta: float) -> void:
	if pivot_ray.is_colliding() == true:
		strength = global_position.distance_to(pivot_ray.get_collision_point())
		$pivot/RayCast3D/MeshInstance3D.global_position = lerp(pivot_ray.global_position, pivot_ray.get_collision_point(), 0.95)
	if pivot_ray.is_colliding() == false:
		$pivot/RayCast3D/MeshInstance3D.global_transform.origin = pivot_ray.global_transform.origin - pivot_ray.global_transform.basis.z * 12
		strength = 4.0
	#print($pivot.rotation)
	#print(owner)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Escape"):
		menu_pressed()
	if in_menu == false:
		if Input.is_action_just_pressed("K"):
			in_game_menu_pressed("Skills")
		if Input.is_action_just_pressed("J"):
			in_game_menu_pressed("Equipment")
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
			$pivot.rotate_x(-event.relative.y * 0.001)  # Reduced sensitivity for testing
			$pivot.rotate_y(-event.relative.x * 0.001)
			target_change = true

		if event is InputEventMouseMotion and abs(event.relative.x + event.relative.y) > 3:
			testvar = abs(event.relative.x + event.relative.y)
			target_change = false

	if event is InputEventMouseMotion and cameramode == 1 and owner.owner.lockOn == false and in_menu == false and in_ingame_menu == false:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
	if player.is_on_floor() == true:
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-55) , deg_to_rad(55))
		
	else:
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-70) , deg_to_rad(70))
		
	if event is InputEventJoypadMotion:
		if event.axis == 2:
			$"../CanvasLayer/Label4".text = str(event) + " " + str(event.axis) + " " + str(event.axis_value)
			if abs(event.get_axis_value()) > JOY_DEADZONE:
				camera_velocity.y = (event.get_axis_value() * JOY_H_SENS *(Engine.get_frames_per_second() / 200.0))
			else:
				camera_velocity.y = 0
		if event.axis == 3:
			$"../CanvasLayer/Label4".text = str(event) + " " + str(event.axis) + " " + str(event.axis_value)
			if abs(event.get_axis_value()) > JOY_DEADZONE:
				camera_velocity.x = (event.get_axis_value() * JOY_V_SENS * (Engine.get_frames_per_second() / 200.0))
			else:
				camera_velocity.x = 0
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-55) , deg_to_rad(50))
	elif event is InputEventScreenDrag and cameramode == 2 and owner.owner.lockOn == false:
		anchor.rotation.y -= event.relative.x / SENSITIVITY
		anchor.rotation.x -= event.relative.y / SENSITIVITY
		anchor.rotation.x = clamp(anchor.rotation.x , deg_to_rad(-55) , deg_to_rad(50))

func menu_pressed():
	if in_menu == false:
		Mcursor.set_main_type("pause")
		player.set_physics_process(false)
		Engine.time_scale = 0.05
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		for i in range(Mcursor.type_history.size() - 1,-1,-1):
			if Mcursor.type_history[i] == Mcursor.main_type:
				Mcursor.type_history.erase(Mcursor.type_history.back())
		Mcursor.main_type = str(Mcursor.type_history.pop_back())
	if Mcursor.main_type == "null":
		player.set_physics_process(true)
		Engine.time_scale = 1.0
		if in_ingame_menu == false:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Mcursor.main_type == "null":
		player.in_menu = false
		in_menu = false
	else:
		player.in_menu = true
		in_menu = true

func in_game_menu_pressed(type: String):
	if ingame_menu.menu_type == type or in_ingame_menu == false:
		in_ingame_menu = !in_ingame_menu
		ingame_menu.open = !ingame_menu.open
		if in_ingame_menu == true:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		elif in_menu == false:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	match type:
		"Skills":
			ingame_menu.change_type(type, null)
		"Equipment":
			ingame_menu.change_type(type, null)
