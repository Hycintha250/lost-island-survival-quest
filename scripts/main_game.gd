extends Node3D

const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const MISSION_PANEL_SCENE := preload("res://scenes/ui/mission_panel.tscn")
const INVENTORY_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const CRAFTING_SCENE := preload("res://scenes/ui/crafting_panel.tscn")
const MAP_SCENE := preload("res://scenes/ui/map_panel.tscn")
const MISSION_MANAGER_SCRIPT := preload("res://scripts/missions/mission_manager.gd")
const SAVE_PATH := "user://lost_island_save.json"

var mission_manager: Node
var inventory: Dictionary = {"wood": 0, "stone": 0, "food": 0, "water": 0}
var discovered_locations: Dictionary = {"Crash Beach": true}
var menu: Control
var hud: Control
var pause_menu: Control
var panels: Dictionary = {}
var mission_label: Label
var status_label: Label
var objective_button: Button
var run_started := false

func _ready() -> void:
	mission_manager = Node.new()
	mission_manager.set_script(MISSION_MANAGER_SCRIPT)
	add_child(mission_manager)
	mission_manager.mission_changed.connect(_on_mission_changed)
	mission_manager.mission_completed.connect(_on_mission_completed)

	var canvas := CanvasLayer.new()
	canvas.name = "GameUI"
	add_child(canvas)

	menu = MENU_SCENE.instantiate()
	canvas.add_child(menu)
	menu.new_game_requested.connect(_start_new_game)
	menu.continue_requested.connect(_continue_game)
	menu.quit_requested.connect(_quit_game)
	menu.settings_requested.connect(_show_settings_message)

	_create_hud(canvas)
	_create_panels(canvas)
	_create_pause_menu(canvas)
	_refresh_hud()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK:
		if run_started:
			_toggle_pause()
	elif run_started and not get_tree().paused:
		match event.keycode:
			KEY_J: _show_panel("missions")
			KEY_I: _show_panel("inventory")
			KEY_C: _show_panel("crafting")
			KEY_M: _show_panel("map")

func _create_hud(canvas: CanvasLayer) -> void:
	hud = Control.new()
	hud.name = "HUD"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.offset_left = 24
	hud.offset_top = 18
	hud.offset_right = -24
	hud.offset_bottom = -18
	hud.visible = false
	canvas.add_child(hud)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 12)
	hud.add_child(layout)

	status_label = Label.new()
	status_label.text = "Health 100  |  Hunger 100  |  Thirst 100"
	layout.add_child(status_label)

	mission_label = Label.new()
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(mission_label)

	var actions := HBoxContainer.new()
	layout.add_child(actions)
	_add_button(actions, "Missions [J]", func(): _show_panel("missions"))
	_add_button(actions, "Inventory [I]", func(): _show_panel("inventory"))
	_add_button(actions, "Crafting [C]", func(): _show_panel("crafting"))
	_add_button(actions, "Map [M]", func(): _show_panel("map"))
	_add_button(actions, "Save", _save_game)
	_add_button(actions, "Pause [Esc]", _toggle_pause)

	objective_button = Button.new()
	objective_button.text = "Complete objective"
	objective_button.pressed.connect(_complete_objective)
	layout.add_child(objective_button)

func _create_panels(canvas: CanvasLayer) -> void:
	panels["missions"] = MISSION_PANEL_SCENE.instantiate()
	panels["inventory"] = INVENTORY_SCENE.instantiate()
	panels["crafting"] = CRAFTING_SCENE.instantiate()
	panels["map"] = MAP_SCENE.instantiate()
	for panel in panels.values():
		canvas.add_child(panel)
	panels["missions"].configure(mission_manager)

func _create_pause_menu(canvas: CanvasLayer) -> void:
	pause_menu = PAUSE_SCENE.instantiate()
	canvas.add_child(pause_menu)
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.return_to_menu_requested.connect(_return_to_menu)

func _add_button(parent: Container, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _start_new_game() -> void:
	inventory = {"wood": 0, "stone": 0, "food": 0, "water": 0}
	discovered_locations = {"Crash Beach": true}
	mission_manager.set_progress(0)
	_start_run()

func _continue_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		inventory = data.get("inventory", inventory)
		discovered_locations = data.get("locations", discovered_locations)
		mission_manager.set_progress(int(data.get("mission_index", 0)))
	_start_run()

func _start_run() -> void:
	run_started = true
	get_tree().paused = false
	menu.visible = false
	hud.visible = true
	_close_panels()
	_refresh_hud()

func _toggle_pause() -> void:
	if not run_started:
		return
	if get_tree().paused:
		_resume_game()
	else:
		_close_panels()
		pause_menu.open()
		get_tree().paused = true

func _resume_game() -> void:
	get_tree().paused = false
	pause_menu.close()

func _return_to_menu() -> void:
	get_tree().paused = false
	pause_menu.close()
	hud.visible = false
	_close_panels()
	menu.visible = true
	run_started = false

func _show_panel(panel_name: String) -> void:
	if not run_started or get_tree().paused or not panels.has(panel_name):
		return
	_close_panels()
	match panel_name:
		"missions": panels[panel_name].open()
		"inventory": panels[panel_name].open(inventory)
		"crafting": panels[panel_name].open(inventory)
		"map": panels[panel_name].open(discovered_locations)

func _close_panels() -> void:
	for panel in panels.values():
		panel.close()

func _complete_objective() -> void:
	if not run_started or get_tree().paused:
		return
	var mission: Dictionary = mission_manager.get_mission()
	if mission.is_empty():
		objective_button.disabled = true
		objective_button.text = "All missions complete!"
		return
	_apply_objective_reward(mission)
	mission_manager.complete_current()
	_save_game()
	_refresh_hud()

func _apply_objective_reward(mission: Dictionary) -> void:
	match str(mission.get("goal", "")):
		"wood": inventory["wood"] = int(inventory.get("wood", 0)) + 2
		"mixed":
			inventory["wood"] = int(inventory.get("wood", 0)) + 5
			inventory["stone"] = int(inventory.get("stone", 0)) + 3
			inventory["food"] = int(inventory.get("food", 0)) + 2
		"water": inventory["water"] = int(inventory.get("water", 0)) + 3
		"forest": discovered_locations["Deep Forest"] = true
		"camp": discovered_locations["Abandoned Camp"] = true
		"enemy": inventory["stone"] = int(inventory.get("stone", 0)) + 1
		"ruins": discovered_locations["Ancient Ruins"] = true
		"gear": inventory["wood"] = int(inventory.get("wood", 0)) + 3
		"boss": discovered_locations["Signal Ridge"] = true
	if mission_manager.current_index == 2:
		discovered_locations["Freshwater Spring"] = true
	if mission_manager.current_index == 6:
		discovered_locations["Hidden Cave"] = true

func _on_mission_changed(_index: int, _title: String) -> void:
	_refresh_hud()

func _on_mission_completed(_index: int) -> void:
	_refresh_hud()

func _refresh_hud() -> void:
	if not is_instance_valid(mission_label):
		return
	var mission: Dictionary = mission_manager.get_mission()
	if mission.is_empty():
		mission_label.text = "All 10 missions complete — you escaped the island!"
		if is_instance_valid(objective_button):
			objective_button.disabled = true
			objective_button.text = "All missions complete!"
	else:
		mission_label.text = "Mission %d/10: %s\n%s" % [mission_manager.current_index + 1, mission.title, mission.description]
		if is_instance_valid(objective_button):
			objective_button.disabled = false
			objective_button.text = "Complete objective: %s" % mission.title

func _save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"mission_index": mission_manager.get_save_progress(),
		"inventory": inventory,
		"locations": discovered_locations
	}
	file.store_string(JSON.stringify(data))
	file.close()
	if is_instance_valid(status_label):
		status_label.text = "Progress saved  |  Health 100  |  Hunger 100  |  Thirst 100"

func _show_settings_message() -> void:
	menu.title.text = "SETTINGS\nComing soon — use the in-game controls to explore."

func _quit_game() -> void:
	get_tree().quit()
