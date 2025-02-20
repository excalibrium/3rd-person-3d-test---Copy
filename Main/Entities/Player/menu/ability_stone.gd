extends Node3D
@onready var camera_3d: Camera3D = $"../../../.."

@export var ability_name : String
#@export var origin : Node3D
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

var slotted := false # bool to check if we are in a slot or not.
var fillback : bool
var last_slotted : Node3D #The slot we were in. (Node3D)
var slotted_in : Node3D #Which slot we are in. (Node3D)

func _ready():
	$Model/SubViewport/Label.set_text(ability_name)
func _process(_delta):
	#if cursor.get_parent().in_menu == false or cursor.main_type != main_type:
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
			$Model/Sprite3D.visible = true
			model.global_rotation.x = lerp_angle(model.global_rotation.x, looker.global_rotation.x, 0.2)
			model.global_rotation.y = lerp_angle(model.global_rotation.y, looker.global_rotation.y, 0.2)
			model.global_rotation.z = lerp_angle(model.global_rotation.z, looker.global_rotation.z, 0.2)
			hoveredOn = true
			cursor.hovered_on = cursor.ray.get_collider()
		else:
			$Model/Sprite3D.visible = false
			hoveredOn = false
			model.global_rotation = lerp(model.global_rotation, Vector3(0,0,0), 0.05)
		#print(pressed_on)
		pressed_on = cursor.pressed_on
	if $"../../..".open == true:
		_ingame_menu_process(_delta)
		
func _physics_process(delta: float) -> void:
	if $"../../..".open == true:
		_ingame_menu_process(delta)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("LeftClick"):
		if slotted == true and slotted_in:
			if slotted_in.prev_stone != slotted_in.stone and slotted_in.full == false and slotted_in.stone != null:
				slotted_in.prev_stone = slotted_in.stone
			slotted_in.stone = self
			slotted_in.full = true
			
		model.position.z = 0.0
	update_vis()
	if visible == true:
		if Input.is_action_just_pressed("LeftClick"):
			clicked = true
		if hoveredOn == true or pressed_on == hitbox:
			
			if Input.is_action_just_released("LeftClick"):
				clicked = false
		if Input.is_action_just_released("LeftClick"):
			clicked = false
			camera_3d.player.update_ability()
func _ingame_menu_process(delta):
	#if slotted == false:
		#print("yehoow")
	if hoverer.clicked == true and hoverer.current_clicked == hitbox:
		#print("slotted: ", slotted, " slotted in: ", slotted_in)
		if slotted == false:
			model.global_position = cursor.global_position * 0.999

		hitbox.global_position = cursor.global_position * 0.999
		#model.position.z = 0.0
		#hitbox.position.z = 0.0
	else:
		if slotted == false:
			model.position = Vector3.ZERO
			#print("zerod")

		hitbox.position = model.position
		
	#print($mesh1.position.x)
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
	if is_visible_in_tree() == false:
		#hitbox.monitorable = false
		#hitbox.monitoring = false
		hitbox.input_ray_pickable = false
		hitbox.set_collision_mask(4096)
		hitbox.set_collision_layer(4096)

	if is_visible_in_tree() == true:
		hitbox.monitorable = true
		hitbox.monitoring = true
		hitbox.input_ray_pickable = true
		hitbox.set_collision_mask(6144) #12 and 13
		hitbox.set_collision_layer(6144)

func _on_area_area_entered(area: Area3D) -> void:
	
	if area.is_in_group("slot"):
		slotted = true
		slotted_in = area.get_parent()
		model.global_position.y = area.global_position.y
		model.global_position.x = area.global_position.x
		model.global_position.z = area.global_position.z
		model.position.z = 0.01
		if slotted_in.full == true and slotted_in.stone != self:
			slotted_in.unslot("nonperm")

func _on_area_area_exited(area: Area3D) -> void:
	if area.is_in_group("slot"):
		slotted = false
		if slotted_in.stone != null and slotted_in.full:
			slotted_in.prev_stone = slotted_in.stone
		slotted_in.stone = null
		if slotted_in.prev_stone and slotted_in.prev_stone.fillback == true and slotted_in.prev_stone != self:
			slotted_in.prev_stone.slot(slotted_in.prev_stone.slotted_in)
			
		else:
			if slotted_in.full == true:
				slotted_in.full = false
				#print("a")
func reset(slot : Node3D, mayback:= false):
	slotted = false
	fillback = mayback
	last_slotted = slot

func slot(lockslot):
	
	model.global_position = lockslot.global_position
	model.position.z = 0.01
	hitbox.position = model.position
	slotted = true
	slotted_in = lockslot
	#if slotted_in.stone != null:
	slotted_in.prev_stone = slotted_in.stone
	slotted_in.stone = self
	slotted_in.full = true
