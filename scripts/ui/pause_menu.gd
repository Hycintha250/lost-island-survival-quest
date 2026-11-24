extends Control

signal resume_requested
signal return_to_menu_requested

func _ready() -> void:
	$Panel/Resume.pressed.connect(func(): resume_requested.emit())
	$Panel/Menu.pressed.connect(func(): return_to_menu_requested.emit())
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false
