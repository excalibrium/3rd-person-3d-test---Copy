extends Node3D

@export var ingame_ui : Node3D
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

func _ready():
	visible = false

func _process(_delta):
	pass
func _input(event: InputEvent) -> void:
	update_vis()
	if cursor.main_type == main_type:
		if visible == true:
			if Input.is_action_just_pressed("LeftClick"):
				clicked = true
			if hoveredOn == true or pressed_on == hitbox:
				
				if Input.is_action_just_released("LeftClick"):
					clicked = false
			if Input.is_action_just_released("LeftClick"):
				clicked = false
		
func _physics_process(_delta):
	update_vis()
	if cursor.main_type == main_type or cursor.get_parent().in_menu == false:
		if visible == true:
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
		#print(pressed_on, "and", hoverer.current_clicked, " == ", hoverer.last_hovered)
func pressed(Type):
	print("entering ", Type)
	match Type:
		"Quitting":
			get_tree().quit()
		"Continue":
			cursor.type_history.clear()
			cursor.type_history.append("null")
			cursor.get_parent().menu_pressed()
		"Options":
			cursor.set_main_type("options")
			#cursor.type_history.erase(cursor.type_history.back())
		"Back":
			cursor.get_parent().menu_pressed()
			#cursor.type_history.erase(cursor.type_history.back())
		"Audio":
			cursor.set_main_type("audio")
		"Graphic":
			cursor.set_main_type("graphic")
		"Bilinear":
			var viewport = get_viewport()
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		"FSR1.0":
			var viewport = get_viewport()
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		"FSR2.2":
			var viewport = get_viewport()
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		
		"Equipment":
			cursor.get_parent().ingame_menu.change_type(Type, self)
		"Skills":
			cursor.get_parent().ingame_menu.change_type(Type, self)
		"Exit":
			cursor.get_parent().in_game_menu_pressed(get_parent().menu_type)
func update_vis():
	#print(hitbox.get_collision_mask())
	if cursor.main_type != main_type or get_parent() == ingame_ui and ingame_ui.open != true:
		visible = false
		hitbox.monitorable = false
		hitbox.monitoring = false
		hitbox.input_ray_pickable = false
		hitbox.set_collision_mask(0)
		hitbox.set_collision_layer(0)

	if cursor.main_type == main_type or get_parent() == ingame_ui and ingame_ui.open == true:
		visible = true
		hitbox.monitorable = true
		hitbox.monitoring = true
		hitbox.input_ray_pickable = true
		hitbox.set_collision_mask(2048)
		hitbox.set_collision_layer(2048)
