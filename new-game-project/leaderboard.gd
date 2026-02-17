extends Control

# Configuration
var leaderboard_name = "main"
var max_scores = 10 # Display only top 10 players
var refresh_rate = 5.0 # Seconds between refreshes

# References
@onready var score_list = $PanelContainer/VBoxContainer/ScrollContainer/ScoreList

func _ready():
	# Clear any dummy placeholders immediately
	clear_list()
	
	# Backend setup
	SilentWolf.configure({
		"api_key": "Q7jc1b1goC3cWJ29wK9KM3AeRP0vJ0w06w3N8fya",
		"game_id": "smeeflappybird",
		"log_level": 1
	})
	
	# Start the refresh loop
	_refresh_loop()

func _refresh_loop():
	# This loop will run as long as the Leaderboard node exists in the Scene Tree
	while is_inside_tree():
		await load_scores()
		# Wait for X seconds before fetching again
		await get_tree().create_timer(refresh_rate).timeout

func load_scores():
	# Fetch top 10 scores from "main" leaderboard
	var sw_result = await SilentWolf.Scores.get_scores(max_scores, leaderboard_name).sw_get_scores_complete
	
	# Check if the node was closed/freed while we were waiting for the network
	if not is_inside_tree():
		return
	
	if sw_result.success:
		update_score_list(sw_result.scores)
	else:
		print("Failed to load scores: " + str(sw_result.error))

func update_score_list(scores):
	# Clear the old list before adding new ones
	clear_list()
	
	if scores.size() == 0:
		add_row_item("", "No scores yet!", "")
	else:
		var rank = 1
		for score_data in scores:
			# Default to using the Player Name (Student ID)
			var display_name = str(score_data.player_name)
			
			# If metadata exists and has "display_name", use that instead (Student Name)
			if score_data.metadata and score_data.metadata.has("display_name"):
				display_name = str(score_data.metadata.display_name)
			
			add_row_item(str(rank), display_name, str(int(score_data.score)))
			rank += 1

func clear_list():
	for child in score_list.get_children():
		child.queue_free()

func add_row_item(rank_txt: String, name_txt: String, score_txt: String):
	var row = HBoxContainer.new()
	
	# Rank
	var l_rank = Label.new()
	l_rank.text = rank_txt
	l_rank.custom_minimum_size.x = 50
	l_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l_rank)
	
	# Name
	var l_name = Label.new()
	l_name.text = name_txt
	l_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_name.clip_text = true 
	row.add_child(l_name)
	
	# Score
	var l_score = Label.new()
	l_score.text = score_txt
	l_score.custom_minimum_size.x = 80
	l_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l_score)
	
	# Font styling
	for label in [l_rank, l_name, l_score]:
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_font_size_override("font_size", 24)

	score_list.add_child(row)

func _on_close_button_pressed():
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		self.queue_free()
