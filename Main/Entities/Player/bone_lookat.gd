extends LookAtModifier3D

var within := false
@export var player: PlayerController
func _process(delta: float) -> void:

	if not is_target_within_limitation():
		if within:
			var tween = create_tween()
			tween.tween_property(self, "influence", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		within = false
	else:
		if not within:
			var tween = create_tween()
			tween.tween_property(self, "influence", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		within = true
		
