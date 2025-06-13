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

func _ready():
	visible = false

func _process(_delta):
	#if cursor.get_parent().in_menu == false or cursor.main_type != main_type:
		#visible = false
		#switch(false, Type, delta, true)
	#else:
		#visible = true
		#switch(true, Type, delta, true)
	if visible == true:
		#looker.global_position = global_position
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
func _input(_event: InputEvent) -> void:
	update_type(Type)
	update_vis()
	if visible == true:
		if Input.is_action_just_pressed("LeftClick"):
			clicked = true
		if hoveredOn == true or pressed_on == hitbox:
			
			if Input.is_action_just_released("LeftClick"):
				clicked = false
		if Input.is_action_just_released("LeftClick"):
			clicked = false
	
func _physics_process(delta):
	if hoverer.clicked == true and hoverer.current_clicked == hitbox:
		model.position.x = -cursor.position.x * 1.3 - 0.1
		hitbox.position.x = -cursor.position.x * 1.3 - 0.1
	model.position.x = clamp(model.position.x, -0.5, 0.499)
	hitbox.position.x = clamp(hitbox.position.x, -0.5, 0.499)
	#print($mesh1.position.x)
	$MeshInstance3D.position = Vector3.ZERO
	update_vis()
	#print(pressed_on, "and", hoverer.current_clicked, " == ", hoverer.last_hovered)
func pressed(Type):
	print("entering ", Type)
	match Type:
		"Audioslider":
			print("porno")
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
func switch(sw_bool: bool,Type, delta, once:=false):
	if sw_bool == false:
		return
	match Type:
		"Quitting":
			var tween = create_tween()
			tween.tween_property(self, "global_position", Vector3.RIGHT * 30, 25.0 * delta).set_trans(Tween.TRANS_CUBIC)
		"Continue":
			var tween = create_tween()
			tween.tween_property(self, "global_position", Vector3.RIGHT * 30, 25.0 * delta).set_trans(Tween.TRANS_CUBIC)
		"Options":
			var tween = create_tween()
			tween.tween_property(self, "global_position", Vector3.RIGHT * 30, 25.0 * delta).set_trans(Tween.TRANS_CUBIC)
			print(tween.finished)
		"Back":
			var tween = create_tween()
			tween.tween_property(self, "global_position", Vector3.RIGHT * 30, 25.0 * delta).set_trans(Tween.TRANS_CUBIC)

func update_vis():
	if cursor.main_type != main_type:
		visible = false
		hitbox.monitorable = false
		hitbox.monitoring = false
		hitbox.input_ray_pickable = false
		hitbox.set_collision_mask(0)
		hitbox.set_collision_layer(0)

	if cursor.main_type == main_type:
		visible = true
		hitbox.monitorable = true
		hitbox.monitoring = true
		hitbox.input_ray_pickable = true
		hitbox.set_collision_mask(2048)
		hitbox.set_collision_layer(2048)

func update_type(Type):
	match Type:
		"Audioslider":
			#print(round(remap($mesh1.position.x, -0.5, 0.5, 0, 100)))
			$Model/SubViewport/Label.set_text(str(round(remap(model.position.x, 0.5, -0.5, 0, 100))))
			var normalized = round(remap(model.position.x, 0.5, -0.5, 0, 100)) / 100
			var db = linear_to_db(normalized)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
		"Resolutionslider":
			#print(ProjectSettings.get_setting("rendering/scaling_3d/scale"))
			#print(round(remap($mesh1.position.x, -0.5, 0.5, 0, 100)))
			var viewport = get_viewport()
			match viewport.scaling_3d_mode:
				Viewport.SCALING_3D_MODE_BILINEAR:
					$Model/SubViewport/Label.set_text(str(round(remap(model.position.x, 0.5, -0.5, 25, 200))  / 100))
					var normalized = round(remap(model.position.x, 0.5, -0.5, 25, 200)) / 100
					viewport.scaling_3d_scale = normalized
				Viewport.SCALING_3D_MODE_FSR:
					$Model/SubViewport/Label.set_text(str(round(remap(model.position.x, 0.5, -0.5, 25, 99))  / 100))
					var normalized = round(remap(model.position.x, 0.5, -0.5, 25, 99)) / 100
					viewport.scaling_3d_scale = normalized
				Viewport.SCALING_3D_MODE_FSR2:
					$Model/SubViewport/Label.set_text(str(round(remap(model.position.x, 0.5, -0.5, 25, 100))  / 100))
					var normalized = round(remap(model.position.x, 0.5, -0.5, 25, 100)) / 100
					viewport.scaling_3d_scale = normalized
