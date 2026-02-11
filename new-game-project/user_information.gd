extends Node2D
const SAVE_PATH = "user://user_data.json"
var player_name: String
var player_email: String

func initialise(screen_size: Vector2i) -> void:
	$UserInput.initialise(screen_size)
	$StartButton.initialise(screen_size, $UserInput) # Currently hidden, not sure if we should even use a start button
	
func save_name_and_email()-> void:
	player_name = $UserInput.get_player_name()
	player_email = $UserInput.get_player_email()

func save_user_data(score: int)-> void:
	# We use dictionary to load and store data
	var primary_key =  player_email.to_lower()
	var all_users = load_all_user_data()
	
	var is_new_player = not all_users.has(primary_key)
	var is_highscore = false

	
	if not is_new_player:
		if score > all_users[primary_key].score:
			is_highscore = true
	
	# Only update if we have new player, or existing player sets a new highscore
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
			var json_string = JSON.stringify(all_users, "\t")
			file.store_string(json_string)
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
	var all_users = load_all_user_data()
	var is_new_player = not all_users.has(player_email)
	
	if is_new_player:
		return 0
	else:
		return all_users[player_email].score
		
func get_player_name() -> String:
	if player_name == "":
		return ""
	return player_name + "'s"
