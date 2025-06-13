extends MeshInstance3D
var previous_type = ""

@export var cursor : Node3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if cursor.main_type != previous_type:
		switched(delta)
		print("switch")
		previous_type = cursor.main_type
	visible = cursor.get_parent().in_menu
func switched(delta):
	match cursor.main_type:
		"pause":
			print("pause")
			var tween = create_tween()
			tween.tween_property(self, "global_transform", $"../wallPAU".global_transform, 25.0 * delta).set_trans(Tween.TRANS_CUBIC)
			#global_transform = $"../wallPAU".global_transform
		"options":

			var tween = create_tween()
			tween.tween_property(self, "global_transform", $"../wallOPT".global_transform, 25.0 * delta).set_trans(Tween.TRANS_CUBIC)
