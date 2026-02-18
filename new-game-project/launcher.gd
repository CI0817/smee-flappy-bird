extends Control


func _on_register_button_pressed() -> void:
	get_tree().change_scene_to_file("res://registration.tscn")


func _on_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_leaderboard_button_pressed() -> void:
	get_tree().change_scene_to_file("res://leaderboard.tscn")
