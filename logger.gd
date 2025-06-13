extends Node
class_name Logger
var logging_enabled := true

func LOG_INFO(a:String) -> void:
	if not logging_enabled:
		return
	print("DE BUG ! IN FO: " + a)
