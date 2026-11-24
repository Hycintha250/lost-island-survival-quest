extends Control

func _ready() -> void:
	visible = false
	$Panel/NewGame.pressed.connect(get_tree().quit)

func show_victory() -> void:
	visible = true
	$Panel/Title.text = "VICTORY"

func show_game_over() -> void:
	visible = true
	$Panel/Title.text = "YOU HAVE FALLEN"
