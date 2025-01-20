@tool
extends AnimationTree
@export var setactive: bool
func _process(delta: float) -> void:
	if setactive == false:
		set_active(false)
	else:
		set_active(true)
#func _process(delta):
		#if name == "FistsAnimTree" and owner.LeftHandItem == "Fists":
			#self.set_active(true)
		#else:
			#self.set_active(false)
		#if name == "AnimationTree" and owner.LeftHandItem != "Fists":
			#self.set_active(true)
		#else:
			#self.set_active(false)
