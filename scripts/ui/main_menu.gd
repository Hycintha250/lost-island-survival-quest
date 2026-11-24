extends Control

signal new_game_requested
signal continue_requested
signal settings_requested
signal quit_requested

@onready var title: Label = $Panel/Title
@onready var new_game: Button = $Panel/NewGame
@onready var continue_game: Button = $Panel/Continue
@onready var settings: Button = $Panel/Settings
@onready var quit: Button = $Panel/Quit

func _ready() -> void:
	new_game.pressed.connect(func(): new_game_requested.emit())
	continue_game.pressed.connect(func(): continue_requested.emit())
	settings.pressed.connect(func(): settings_requested.emit())
	quit.pressed.connect(func(): quit_requested.emit())
	continue_game.disabled = not FileAccess.file_exists("user://lost_island_save.json")
	title.text = "LOST ISLAND\nSURVIVAL QUEST"
