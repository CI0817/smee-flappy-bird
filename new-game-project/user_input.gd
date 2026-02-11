extends VBoxContainer


func _ready():
	pass
	
func initialise(screen_size: Vector2i) -> void:
	
	var box_width = 300
	var box_height = 200
	
	# Calculate the top-left position to center it
	var start_x = (screen_size.x / 2) - (box_width / 2)
	var start_y = (screen_size.y / 2) - (box_height / 2)
	
	# Set the offsets
	self.offset_left = start_x
	self.offset_top = start_y
	self.offset_right = start_x + box_width
	self.offset_bottom = start_y + box_height

	
func get_player_name() -> String:
	return $Name.text

func get_player_email() -> String:
	return $Email.text.to_lower()
