extends Node

@export var pipe_scene : PackedScene
@export var input_action : String = "jump_p1"
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

func _ready() -> void:
	# Wait for the SubViewportContainer to perform its layout.
	# The size is often (0,0) or incorrect during the very first frame.
	await get_tree().process_frame
	await get_tree().process_frame
	
	screen_size = get_viewport().get_visible_rect().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
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
	
	# Only delete pipes belonging to THIS player.
	# Using "call_group" deletes the other player's pipes too, causing crashes.
	for pipe in pipes:
		if is_instance_valid(pipe):
			pipe.queue_free()
	
	scroll = 0
	pipes.clear()
	generate_pipes()
	$Bird.reset()
	if highscore == 0:
		$HighscoreLabel.hide()
	else:
		$HighscoreLabel.show()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(input_action):
		if game_over == false: 
			# Normal gameplay logic
			if game_running == false:
				start_game()
			else:
				if $Bird.flying:
					$Bird.flap()
					check_top()
		else:
			# If game is over, pressing Jump will restart it!
			new_game()
					
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
	stop_game()

func _on_game_over_restart() -> void:
	new_game()
