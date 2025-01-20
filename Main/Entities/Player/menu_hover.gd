extends MeshInstance3D
@export var cursor: Node3D
var testingvar
var last_hovered
var hoveredOn := false
var clicked := false
var current_hovered
var prev_hovered
var current_clicked
var buttons: Array = [Area3D]
# Called when the node enters the scene tree for the first time.
func _ready():
	if last_hovered in buttons:
		visible = true
		#print("WOOOO")
	elif last_hovered == null:
		visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	buttons = get_tree().get_nodes_in_group("Menutton")
	last_hovered = cursor.hovered_on
	if last_hovered != null:
		global_position = last_hovered.global_position
		global_rotation = lerp(global_rotation, last_hovered.global_rotation, 0.3)
		if last_hovered is Area3D and current_hovered != last_hovered:
			prev_hovered = current_hovered
			testingvar = prev_hovered
			current_hovered = last_hovered
	if current_hovered != null:
		#if clicked == false:
		global_position = current_hovered.global_position
		global_rotation = current_hovered.get_parent().model.global_rotation
	#print(current_hovered)
	if get_parent().in_menu == false:
		visible = false
func _physics_process(delta):
	if last_hovered in buttons:
		visible = true
		#print("WOOOO")
	elif Input.is_action_just_pressed("LeftClick") and last_hovered in buttons:
		visible = false
	if Input.is_action_just_pressed("LeftClick") and get_parent().in_menu:
		clicked = true
		current_clicked = cursor.pressed_on
	if clicked == false or last_hovered == null:
		#visible = true
		get_mesh().surface_get_material(0).grow_amount = lerp(get_mesh().surface_get_material(0).grow_amount, 0.005, 0.3)
	if current_hovered != null and last_hovered != null and current_hovered in buttons and last_hovered in buttons and get_parent().in_menu: #if hovering over a button
		get_mesh().size = lerp(get_mesh().size, current_hovered.get_parent().find_child("mesh").get_mesh().size, 0.4)
		if last_hovered.get_parent().hoveredOn == true and current_hovered != last_hovered and get_mesh().surface_get_material(0).grow_amount >= 0.01:
			get_mesh().surface_get_material(0).grow_amount = 0.3
		if current_clicked != current_hovered:
			get_mesh().surface_get_material(0).grow_amount = 0.005
		if current_clicked in buttons:
			if current_clicked.get_parent().hoveredOn == true and clicked:
				get_mesh().surface_get_material(0).grow_amount = lerp(get_mesh().surface_get_material(0).grow_amount, 0.3, 0.5)
		if current_clicked == last_hovered and Input.is_action_just_released("LeftClick"):
			get_mesh().surface_get_material(0).grow_amount = -0.3
			current_clicked.get_parent().pressed(current_clicked.get_parent().Type)
	if Input.is_action_just_released("LeftClick"):
		clicked = false
	#print(clicked)
	#print("last: ", last_hovered, " current: ", current_hovered, " prev: ", prev_hovered, " currentclicked: ", current_clicked )
	#print("currentgrow: ", get_mesh().surface_get_material(0).grow_amount)
