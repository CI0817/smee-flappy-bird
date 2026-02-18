extends Node

@export var pipe_scene : PackedScene

# Dictionary to store { "studentID": { "student_name": "...", "email": "..." } }
var local_player_registry : Dictionary = {}
var current_student_id : String = "" # Store the ID for the save_score call later

# User's variables
var player_name : String = "" # Display name (from registry)
var player_email : String = "" # Email (from registry)
var is_logged_in : bool = false

# Game's variables
var registration_db_name : String = "registration"
var leaderboard_db_name: String = "main"
var game_running : bool
var game_over : bool
var scroll 
var score : int = 0
var highscore : int = 0
const SCROLL_SPEED: int = 4 
var screen_size : Vector2i 
var ground_height : int
var pipes : Array
const PIPE_DELAY: int = 100
const PIPE_RANGE : int = 200

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	
	# Connect signals
	$LoginLayer/Control/VBoxContainer/PlayButton.pressed.connect(_on_play_button_pressed)
	$LoginLayer/Control/VBoxContainer/SyncButton.pressed.connect(fetch_registry_updates)
	
	# Backend setup
	SilentWolf.configure({
		"api_key": "Q7jc1b1goC3cWJ29wK9KM3AeRP0vJ0w06w3N8fya",
		"game_id": "smeeflappybird",
		"log_level": 1
	})
	
	new_game()

func fetch_registry_updates():
	print("Fetching player registry from SilentWolf...")
	var label_ref = $LoginLayer/Control/VBoxContainer/Label
	var original_text = label_ref.text
	label_ref.text = "Syncing Database..."
	
	# Fetch top 1000 registrations
	var sw_result = await SilentWolf.Scores.get_scores(1000, registration_db_name).sw_get_scores_complete
	
	if sw_result.success:
		print("Registry fetched successfully.")
		local_player_registry.clear()
		
		for entry in sw_result.scores:
			# SilentWolf returns: { "player_name": "ID", "score": 1, "metadata": {...} }
			var s_id = entry.player_name
			if entry.metadata:
				local_player_registry[s_id] = entry.metadata
		
		print("Loaded " + str(local_player_registry.size()) + " students.")
		label_ref.text = "Database Synced. Enter ID."
	else:
		print("Failed to fetch registry: " + str(sw_result.error))
		label_ref.text = "Sync Failed. Check Internet."

func new_game():
	game_running = false
	game_over = false
	if score > highscore:
		highscore = score
	$HighscoreLabel.text = "HIGHSCORE: " + str(highscore)
	score = 0
	$ScoreLabel.text = "SCORE: " + str(score)
	$GameOver.hide()
	get_tree().call_group("pipes", "queue_free")
	scroll = 0
	pipes.clear()
	generate_pipes()
	$Bird.reset()
	
	if highscore == 0:
		$HighscoreLabel.hide()
	else:
		$HighscoreLabel.show()
		
	if not is_logged_in:
		$LoginLayer.show()
		# Clear the ID input for the next player
		$LoginLayer/Control/VBoxContainer/StudentIDInput.text = ""
		# Reset current ID
		current_student_id = ""
		$LoginLayer/Control/VBoxContainer/StudentIDInput.grab_focus()
	else:
		$LoginLayer.hide()

func _input(event: InputEvent) -> void:
	if is_logged_in and (game_over == false) and (event is InputEventKey):
		if event.keycode == KEY_SPACE and event.pressed:
			if game_running == false:
				start_game()
			else:
				if $Bird.flying:
					$Bird.flap()
					check_top()

func _on_play_button_pressed() -> void:
	var id_input_node = $LoginLayer/Control/VBoxContainer/StudentIDInput
	var input_id = id_input_node.text.strip_edges()
	
	if input_id == "":
		print("Please enter a Student ID")
		return

	# Check our local cache
	if local_player_registry.has(input_id):
		# student found
		var data = local_player_registry[input_id]
		
		current_student_id = input_id
		player_name = data.get("student_name", "Unknown") # Display Name
		player_email = data.get("email", "")
		
		print("Welcome " + player_name)
		is_logged_in = true
		$LoginLayer.hide()
		start_game()
	else:
		# Student not found
		print("ID not found! Please register at the queue station.")
		$LoginLayer/Control/VBoxContainer/Label.text = "ID Not Found! Please Register or Sync."

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$PipeTimer.start()

func _process(_delta: float) -> void:
	if game_running:
		scroll += SCROLL_SPEED
		if scroll >= screen_size.x:
			scroll = 0
		$Ground.position.x = -scroll
		for pipe in pipes:
			pipe.position.x -= SCROLL_SPEED

func _on_pipe_timer_timeout() -> void:
	generate_pipes()
	
func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)
	
func scored():
	score += 1
	$ScoreLabel.text = "SCORE: " + str(score)

func check_top():
	if $Bird.position.y < 0:
		$Bird.position.y = 0

func bird_hit():
	$Bird.falling = true
	stop_game()

func stop_game():
	$PipeTimer.stop()
	$Bird.flying = false
	game_running = false
	game_over = true
	$GameOver.show()

func _on_ground_hit() -> void:
	$Bird.falling = false
	save_score_to_silentwolf()
	stop_game()

func _on_game_over_restart() -> void:
	# Log user out so the next person can play
	is_logged_in = false
	new_game()

func save_score_to_silentwolf():
	if score > 0 and current_student_id != "":
		print("Saving score for ID: " + current_student_id)
		
		# Store the Display Name and Email in metadata again for the main leaderboard
		var metadata = {
			"display_name": player_name,
			"email": player_email
		}
		
		# Save to 'main' leaderboard using Student ID as the key
		await SilentWolf.Scores.save_score(current_student_id, score, leaderboard_db_name, metadata).sw_save_score_complete
		
		print("Score saved!")
# ----------------------------
