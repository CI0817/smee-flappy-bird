extends Node

@export var pipe_scene : PackedScene
@export var input_action : String = "jump_p1" 

var game_running : bool
var game_over : bool
var scroll
var score : int = 0
const SCROLL_SPEED: int = 4
var screen_size : Vector2i 
var ground_height : int
var pipes : Array
const PIPE_DELAY: int = 100
const PIPE_RANGE : int = 200
var player_name: String

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	screen_size = get_viewport().get_visible_rect().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	
	$UserInformation.initialise(screen_size)
	
	# Connect the start button signal
	$UserInformation.game_start_requested.connect(start_game)
	
	new_game()

func new_game():
	# RESET STATE
	game_running = false
	game_over = false
	
	score = 0
	$ScoreLabel.text = "SCORE: " + str(score)
	
	# HIDE Game Over / SHOW Registration
	$GameOver.hide()
	$HighscoreLabel.hide()
	$UserInformation.show()
	
	# Clear pipes
	for pipe in pipes:
		if is_instance_valid(pipe):
			pipe.queue_free()
	
	scroll = 0
	pipes.clear()
	generate_pipes()
	$Bird.reset()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(input_action):
		if game_over == false: 
			# Only jump if the game is actually running
			if game_running:
				if $Bird.flying:
					$Bird.flap()
					check_top()
		else:
			# If game is over, pressing Jump triggers the reset
			new_game()
					
func start_game():
	player_name = $UserInformation.get_player_name()
	var highscore = $UserInformation.get_current_player_highscore()
	$HighscoreLabel.text = player_name + " HIGHSCORE: " + str(highscore)
	$HighscoreLabel.show()
	
	$UserInformation.hide()
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
	$UserInformation.save_user_data(score)
	
	# Show the Game Over screen so they know they died
	$GameOver.show() 

func _on_ground_hit() -> void:
	$Bird.falling = false
	stop_game()

func _on_game_over_restart() -> void:
	new_game()
