extends Node2D

# Signal to tell Main that the user is ready to play
signal game_start_requested

const SAVE_PATH = "user://user_data.json"
var player_name: String
var player_email: String

func _ready() -> void:
	# Connect the button signal
	$StartButton.pressed.connect(_on_start_button_pressed)

func initialise(screen_size: Vector2i) -> void:
	$UserInput.initialise(screen_size)
	$StartButton.initialise(screen_size, $UserInput)
	# Ensure the button is visible so players know to click it
	$StartButton.show()

func _on_start_button_pressed() -> void:
	# Ensure fields are not empty
	var raw_name = $UserInput.get_player_name()
	var raw_email = $UserInput.get_player_email()
	
	if raw_name.strip_edges() == "" or raw_email.strip_edges() == "":
		print("Registration incomplete.")
		return 
		
	# 2. Save data and signal Main to start
	save_name_and_email()
	game_start_requested.emit()

func save_name_and_email()-> void:
	player_name = $UserInput.get_player_name()
	player_email = $UserInput.get_player_email()

func save_user_data(score: int)-> void:
	var primary_key =  player_email.to_lower()
	var all_users = load_all_user_data()
	var is_new_player = not all_users.has(primary_key)
	var is_highscore = false

	if not is_new_player:
		if score > all_users[primary_key].score:
			is_highscore = true
	
	if is_new_player or is_highscore:
		var player_data = {
			"name": player_name,
			"email": player_email,
			"score": score, 
			"timestamp": Time.get_datetime_string_from_system()
		}
		all_users[primary_key] = player_data
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(all_users, "\t"))
			file.close()

func load_all_user_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {} 
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK:
		return json.data 
	return {}

func get_current_player_highscore()-> int:
	if player_email == "": return 0
	var all_users = load_all_user_data()
	if not all_users.has(player_email): return 0
	return all_users[player_email].score
		
func get_player_name() -> String:
	if player_name == "": return ""
	return player_name + "'s"
