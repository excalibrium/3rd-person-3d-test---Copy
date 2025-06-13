extends ProgressBar

@onready var timer = $Timer
@onready var reduction_bar = $ReductionBar


var posture = 0 : set = _set_posture

func _set_posture(new_posture):
	var prev_posture = posture
	posture = min(max_value, new_posture)
	value = posture

	if posture <= 0:
		posture = 0
	
	if posture < prev_posture:
		timer.start()
	else:
		reduction_bar.value = posture
	
func init_posture(_posture):
	posture = posture
	max_value = _posture
	value = _posture
	reduction_bar.max_value = _posture
	reduction_bar.value = posture


func _on_timer_timeout():
	reduction_bar.value = posture
