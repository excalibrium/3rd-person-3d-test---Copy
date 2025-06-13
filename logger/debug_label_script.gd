extends Label

class_name DebugLabel

var m_node: Node
var param_name: String = ""
var params_arr: Array = []
var param_value: String = ""

enum {SINGLE, MULTIPLE}

var debug_param_type

func _init(node: Node, p_name: Variant):
	if p_name == null:
		self.text = "Error when setting either param_name or param_value in node: " + str(self.name)
	match(typeof(p_name)):
		TYPE_STRING:
			param_name = p_name
			debug_param_type = SINGLE
		TYPE_ARRAY:
			params_arr = p_name
			debug_param_type = MULTIPLE
			for i in range(params_arr.size()):
				if i != params_arr.size() - 1:
					param_name += params_arr[i] + "."
				else:
					param_name += params_arr[i]
		_:
			return
	m_node = node
	pass

func _physics_process(_delta: float) -> void:
	if not m_node:
		return
	match(debug_param_type):
		SINGLE:
			param_value = str(m_node[param_name])
		MULTIPLE:
			var cur_dir = m_node
			for i in params_arr:
				cur_dir = cur_dir[i]
			param_value = str(cur_dir)
	update_text()
	pass

func update_text() -> void:
	self.text = str(m_node["name"]) + "\'s " + param_name + " is: " + param_value
	pass
