@tool
extends AnimationTree

func _ready():
	if !Engine.is_editor_hint():
		self.set_active(true)

