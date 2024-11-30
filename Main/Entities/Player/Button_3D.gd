extends Node3D

@export var main_type: String
@export var looker: Node3D
@export var hitbox: Node3D
@export var hoverer: Node3D
@export var ray: RayCast3D
@export var cursor: Node3D
@export var Type: String
@export var model: Node3D
var hoveredOn := false
var clicked := false
var pressed_on
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cursor.get_parent().in_menu == false:
		visible = false
	else:
		visible = true
	looker.global_position = global_position
	looker.look_at(cursor.global_position)
	#looker.rotation.y += PI
	#looker.rotation.x = -looker.rotation.x
	#print(looker.rotation)
	if ray.get_collider() == hitbox and cursor.get_parent():
		model.global_rotation.x = lerp_angle(model.global_rotation.x, looker.global_rotation.x, 0.2)
		model.global_rotation.y = lerp_angle(model.global_rotation.y, looker.global_rotation.y, 0.2)
		model.global_rotation.z = lerp_angle(model.global_rotation.z, looker.global_rotation.z, 0.2)
		hoveredOn = true
		cursor.hovered_on = cursor.ray.get_collider()
	else:
		hoveredOn = false
		model.rotation = lerp(model.rotation, Vector3(0,0,0), 0.05)
	#print(pressed_on)
	pressed_on = cursor.pressed_on
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LeftClick"):
		clicked = true
	if hoveredOn == true or pressed_on == hitbox:
		
		if Input.is_action_just_released("LeftClick"):
			clicked = false
	if Input.is_action_just_released("LeftClick"):
		clicked = false
func _physics_process(delta):
	pass
	#print(pressed_on, "and", hoverer.current_clicked, " == ", hoverer.last_hovered)
func pressed(Type):
	print("entering ", Type)
	match Type:
		"Quitting":
			get_tree().quit()
		"Continue":
			cursor.get_parent().menu_pressed()
