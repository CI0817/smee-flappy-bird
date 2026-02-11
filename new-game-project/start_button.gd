extends Button

func initialise(screen_size: Vector2i, info_box: VBoxContainer) -> void:
	# 1. Horizontal Positioning (Center it)
	var start_x = (screen_size.x / 2) - (size.x / 2)
	
	# 2. Vertical Positioning (Underneath the VBox)
	var gap = 50 
	var start_y = info_box.offset_bottom - gap
	
	position = Vector2(start_x, start_y)
