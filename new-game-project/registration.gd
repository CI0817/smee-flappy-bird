extends Control

@onready var name_input = $VBoxContainer/NameInput
@onready var id_input = $VBoxContainer/IDInput
@onready var email_input = $VBoxContainer/EmailInput
@onready var status_label = $VBoxContainer/StatusLabel
@onready var register_btn = $VBoxContainer/RegisterButton

var registration_db_name : String = "registration"
var leaderboard_db_name: String = "main"

func _ready():
	# Configure SilentWolf
	SilentWolf.configure({
		"api_key": "Q7jc1b1goC3cWJ29wK9KM3AeRP0vJ0w06w3N8fya",
		"game_id": "smeeflappybird",
		"log_level": 1
	})
	register_btn.pressed.connect(_on_register_pressed)

func _on_register_pressed():
	var real_name = name_input.text.strip_edges()
	var s_id = id_input.text.strip_edges()
	var email = email_input.text.strip_edges()

	if real_name == "" or s_id == "" or email == "":
		status_label.text = "Error: Please fill in all fields."
		return

	status_label.text = "Registering..."
	register_btn.disabled = true

	# Prepare metadata (Name and Email)
	var metadata = {
		"student_name": real_name,
		"email": email
	}

	# Save to 'registrations' leaderboard
	# We use the Student ID as the 'player_name' key.
	# We give a dummy score of 1.
	var sw_result = await SilentWolf.Scores.save_score(s_id, 1, registration_db_name, metadata).sw_save_score_complete

	if sw_result.success:
		status_label.text = "Success! You are registered."
		await get_tree().create_timer(2.0).timeout
		_clear_form()
	else:
		status_label.text = "Error: " + str(sw_result.error)
	
	register_btn.disabled = false

func _clear_form():
	name_input.text = ""
	id_input.text = ""
	email_input.text = ""
	status_label.text = "Next player please..."
