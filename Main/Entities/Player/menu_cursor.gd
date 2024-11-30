extends Node3D
@export var ray : RayCast3D
var pressed_on
var hovered_on
var mouseRelY
var mousePosY
var mousePosX
var GBreg
# Called when the node enters the scene tree for the first time.
func _ready():
	GBreg = global_transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	hovered_on = ray.get_collider()
#	print(stored)
	#print(pressed_on)
	#global_position += $"../CAM".global_position
	#print($"..".position.z)
	#global_position.z = -455
	visible = false
	if get_parent().in_menu == true:
		visible = true
	if mousePosX and mousePosY and get_parent().in_menu == true:
		position.x = lerp(position.x, mousePosX, 0.1)
		position.y = lerp(position.y, mousePosY, 0.1)
		position.x = position.x/20.0 * %MenuCursorSlot.global_position.distance_squared_to(get_parent().global_position)
		position.y = position.y/20.0 * %MenuCursorSlot.global_position.distance_squared_to(get_parent().global_position)
func _input(event):
	if Input.is_action_just_pressed("LeftClick"):
		pressed_on = ray.get_collider()
	if event is InputEventMouseMotion:
		#print("b")
		#print(get_window().size)
		mouseRelY = -event.relative.y
		mousePosY = -event.position.y +  get_window().size.y /2 
		mousePosX = event.position.x -  get_window().size.x /2 
