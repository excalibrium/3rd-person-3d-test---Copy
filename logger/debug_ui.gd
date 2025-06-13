extends CanvasLayer

class_name DebugUI

var debug_ui_enabled: bool = true:
	get:
		return debug_ui_enabled
	set(value):
		debug_ui_enabled = value
		@warning_ignore("standalone_ternary")
		if value:
			self.show()
		else:
			self.hide()

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug_ui"):
		debug_ui_enabled = !debug_ui_enabled

func add_debug_label(node: Node, param_name: Variant) -> void:
	var label: DebugLabel = DebugLabel.new(node, param_name)
	%Root.add_child(label)
	pass
