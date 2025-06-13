extends CanvasLayer
func _ready():
	# Create a 3x3 grid overlay
	create_grid_overlay()

func create_grid_overlay():
	# Create a CanvasLayer to hold our UI element
	
	# Create a ColorRect as the base for our grid
	var grid_container = Control.new()
	grid_container.name = "GridContainer"
	grid_container.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the entire screen
	add_child(grid_container)
	
	# Connect the resize signal to update the grid when the window changes size
	get_viewport().size_changed.connect(_on_viewport_size_changed.bind(grid_container))
	
	# Draw the initial grid
	_draw_grid(grid_container)

func _draw_grid(container):
	# Clear any existing lines
	for child in container.get_children():
		child.queue_free()
	
	# Get current viewport size
	var viewport_size = get_viewport().size
	
	# Grid line color and width
	var line_color = Color(1, 1, 1, 0.3)  # White with some transparency
	var line_width = 2.0
	
	# Create vertical lines
	for i in range(1, 3):  # We need 2 vertical lines for 3 columns
		var v_line = Line2D.new()
		v_line.name = "VerticalLine" + str(i)
		v_line.width = line_width
		v_line.default_color = line_color
		
		# Calculate X position (1/3 and 2/3 of screen width)
		var x_pos = i * (viewport_size.x / 3.0)
		
		# Add points from top to bottom
		v_line.add_point(Vector2(x_pos, 0))
		v_line.add_point(Vector2(x_pos, viewport_size.y))
		
		container.add_child(v_line)
	
	# Create horizontal lines
	for i in range(1, 3):  # We need 2 horizontal lines for 3 rows
		var h_line = Line2D.new()
		h_line.name = "HorizontalLine" + str(i)
		h_line.width = line_width
		h_line.default_color = line_color
		
		# Calculate Y position (1/3 and 2/3 of screen height)
		var y_pos = i * (viewport_size.y / 3.0)
		
		# Add points from left to right
		h_line.add_point(Vector2(0, y_pos))
		h_line.add_point(Vector2(viewport_size.x, y_pos))
		
		container.add_child(h_line)

# Update grid when window is resized
func _on_viewport_size_changed(container):
	_draw_grid(container)
