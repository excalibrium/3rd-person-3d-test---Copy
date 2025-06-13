extends Weapon
class_name Bomb

func _ready() -> void:
	set_owner(get_parent().owner)

func _on_timer_timeoout():
	$AudioStreamPlayer3D.play()
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.75  # 0.5 seconds = 2 times per second
	timer.start()
	timer.timeout.connect(_on_timer_timeout2)

func _on_timer_timeout2():
	$AudioStreamPlayer3D.play()
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.5  # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeout3)
	timer.start()

func _on_timer_timeout3():
	$AudioStreamPlayer3D.play()
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.33  # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeout4)
	
	timer.start()
func _on_timer_timeout4():
	$AudioStreamPlayer3D.play()
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.25  # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeout5)
	
	timer.start()

func _on_timer_timeout5():
	$AudioStreamPlayer3D.play()
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.25 # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeout6)
	
	timer.start()
func _on_timer_timeout6():
	$AudioStreamPlayer3D.play()
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 0.25  # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeout7)
	
	timer.start()
func _on_timer_timeout7():
	$AudioStreamPlayer3D2.play()
	$AudioStreamPlayer3D2.finished.connect(_on_boom)
	$MeshInstance3D.visible = false
	$MeshInstance3D2.visible = true

	

func _on_boom():
	queue_free()


func prime():
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 1.0  # 0.5 seconds = 2 times per second
	timer.timeout.connect(_on_timer_timeoout)
	
	timer.start()
