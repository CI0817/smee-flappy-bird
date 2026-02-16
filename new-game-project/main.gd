extends Node

@export var pipe_scene : PackedScene

# User's variables
var player_name : String = ""
var player_email : String = ""
var is_logged_in : bool = false

# Game's variables
var game_running : bool
var game_over : bool
var scroll # used to move images across the screen
var score : int = 0
var highscore : int = 0
const SCROLL_SPEED: int = 4 # slower or faster for scrolling
var screen_size : Vector2i 
var ground_height : int
var pipes : Array
const PIPE_DELAY: int = 100
const PIPE_RANGE : int = 200

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	
	# Connect the button signal via code to ensure it works
	$LoginLayer/Control/VBoxContainer/PlayButton.pressed.connect(_on_play_button_pressed)
	
	# Configure SilentWolf back-end database
	SilentWolf.configure({
		"api_key": "Q7jc1b1goC3cWJ29wK9KM3AeRP0vJ0w06w3N8fya",
		"game_id": "smeeflappybird",
		"log_level": 1
	})
	
	new_game()

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
		
	# Check if we need to show the login screen
	if not is_logged_in:
		$LoginLayer.show()
	else:
		$LoginLayer.hide()

func _input(event: InputEvent) -> void:
	# Added check: Only allow space bar if logged in and login layer is hidden
	if is_logged_in and (game_over == false) and (event is InputEventKey):
		if event.keycode == KEY_SPACE and event.pressed:
			if game_running == false:
				start_game()
			else:
				if $Bird.flying:
					$Bird.flap()
					check_top()

# --- NEW FUNCTION ---
func _on_play_button_pressed() -> void:
	var name_input = $LoginLayer/Control/VBoxContainer/NameInput
	var email_input = $LoginLayer/Control/VBoxContainer/EmailInput
	
	if name_input.text != "" and email_input.text != "":
		player_name = name_input.text
		player_email = email_input.text
		is_logged_in = true
		$LoginLayer.hide()
		# You can optionally call start_game() here immediately
	else:
		print("Please enter both name and email!")
# --------------------

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$PipeTimer.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	# Reset the user info flag
	is_logged_in = false
	
	# Clear the input field
	$LoginLayer/Control/VBoxContainer/NameInput.text = ""
	$LoginLayer/Control/VBoxContainer/EmailInput.text = ""
	
	# Call new game
	new_game()

func save_score_to_silentwolf():
	# We only want to save if the score is greater than 0
	if score > 0:
		print("Attempting to save score...")
		
		# structure: save_score(player_name, score, leaderboard_name, metadata)
		# We store the email in the 'metadata' dictionary so it doesn't show up publicly 
		# on the leaderboard but is saved in the database.
		var metadata = { "email": player_email }
		
		# "main" is the name of the leaderboard you created on the website
		await SilentWolf.Scores.save_score(player_name, score, "main", metadata).sw_save_score_complete
		
		print("Score saved successfully!")
