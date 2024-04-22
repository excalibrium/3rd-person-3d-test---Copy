extends ProgressBar

@onready var timer = $Timer
@onready var reduction_bar = $ReductionBar


var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health

	if health <= 0:
		health = 0
	
	if health < prev_health:
		timer.start()
	else:
		reduction_bar.value = health
	
func init_health(_health):
	health = health
	max_value = _health
	value = _health
	reduction_bar.max_value = _health
	reduction_bar.value = health


func _on_timer_timeout():
	reduction_bar.value = health
