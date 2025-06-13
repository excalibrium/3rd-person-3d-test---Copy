extends Node3D
var main_type : String
@export var ray : RayCast3D
var pressed_on
var hovered_on
var mouseRelY
var mousePosY
var mousePosX
var GBreg
var prev_type : String
var type_history : Array[String]
var last_used := "null"
# Called when the node enters the scene tree for the first time.
func _ready():
	GBreg = global_transform
	main_type = "null"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	hovered_on = ray.get_collider()
#	print(stored)
	#print(pressed_on)
	#global_position += $"../CAM".global_position
	#print($"..".position.z)
	#global_position.z = -455
	visible = false
	#print(mousePosX, " ", mousePosY)
	if get_parent().in_menu == true or get_parent().in_ingame_menu == true:
		visible = true
	if last_used == "mouse":
		if mousePosX or mousePosY:
			
			if get_parent().in_menu == true or get_parent().in_ingame_menu == true:
				position.x = lerp(position.x, mousePosX, 0.1)
				position.y = lerp(position.y, mousePosY, 0.1)
				position.x = position.x/20.0 * %MenuCursorSlot.global_position.distance_squared_to(get_parent().global_position)
				position.y = position.y/20.0 * %MenuCursorSlot.global_position.distance_squared_to(get_parent().global_position)
	elif last_used == "joypad":
		#print("porno")
		if get_parent().in_menu == true or get_parent().in_ingame_menu == true:
			var stick_x = Input.get_axis("moveLeft", "moveRight")
			var stick_y = Input.get_axis("moveBackward", "moveForward")
			#print(stick_y)
			var movement = Vector3(stick_x, stick_y, 0)
			if movement.length() > 1.0:
				movement = movement.normalized()
			position += Vector3(movement.x / 150.0, movement.y / 150.0, 0.0)
			position.x = clamp(position.x, -0.9, 0.9)
			position.y = clamp(position.y, -0.5, 0.5)
			
			#position.x = position.x/20.0 * %MenuCursorSlot.global_position.distance_squared_to(get_parent().global_position)
			#position.y = position.y/20.0 * %MenuCursorSlot.global_position.distance_squared_to(get_parent().global_position)
func _input(event):
	if Input.is_action_just_pressed("LeftClick"):
		pressed_on = ray.get_collider()
		print(position)
	if event is InputEventMouseMotion:
		last_used = "mouse"
		#print("b")
		#print(get_window().size)
		mouseRelY = -event.relative.y
		mousePosY = -event.position.y +  get_window().size.y /2.0 
		mousePosX = event.position.x -  get_window().size.x /2.0
	if event is InputEventJoypadMotion:
		last_used = "joypad"
	
func set_main_type(type: String):
	#type_history.back() != type:
	type_history.append(main_type)
	main_type = type
