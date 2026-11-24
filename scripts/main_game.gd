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
var inventory: Dictionary = {"wood": 0, "stone": 0, "food": 0, "water": 0, "leaves": 0, "rope": 0}
var crafted: Dictionary = {}
var discovered_locations: Dictionary = {"Crash Beach": true}
var defeated: Dictionary = {"guardian": false, "island_beast": false}
var signal_active := false
var guardian_health := 3
var beast_health := 6
var menu: Control
var hud: Control
var pause_menu: Control
var panels: Dictionary = {}
var mission_label: Label
var status_label: Label
var objective_button: Button
var encounter_button: Button
var signal_button: Button
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
	layout.add_theme_constant_override("separation", 8)
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
	var gather := HBoxContainer.new()
	layout.add_child(gather)
	for item in ["wood", "stone", "food", "leaves", "rope"]:
		_add_button(gather, "Gather " + str(item).capitalize(), func(): _gather(item))
	_add_button(gather, "Gather Water", func(): _gather("water"))
	_add_button(gather, "Explore", _explore_next_location)
	objective_button = Button.new()
	objective_button.text = "Claim objective"
	objective_button.pressed.connect(_complete_objective)
	layout.add_child(objective_button)
	encounter_button = Button.new()
	encounter_button.pressed.connect(_attack_encounter)
	layout.add_child(encounter_button)
	signal_button = Button.new()
	signal_button.text = "Activate signal"
	signal_button.pressed.connect(_activate_signal)
	layout.add_child(signal_button)

func _create_panels(canvas: CanvasLayer) -> void:
	panels["missions"] = MISSION_PANEL_SCENE.instantiate()
	panels["inventory"] = INVENTORY_SCENE.instantiate()
	panels["crafting"] = CRAFTING_SCENE.instantiate()
	panels["map"] = MAP_SCENE.instantiate()
	for panel in panels.values():
		canvas.add_child(panel)
	panels["missions"].configure(mission_manager)
	panels["crafting"].craft_requested.connect(_craft_item)
	panels["crafting"].close_requested.connect(func(): panels["crafting"].close())

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
	inventory = {"wood": 0, "stone": 0, "food": 0, "water": 0, "leaves": 0, "rope": 0}
	crafted = {}
	discovered_locations = {"Crash Beach": true}
	defeated = {"guardian": false, "island_beast": false}
	signal_active = false
	guardian_health = 3
	beast_health = 6
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
	if not data is Dictionary:
		return
	inventory = data.get("inventory", inventory)
	crafted = data.get("crafted", {})
	discovered_locations = data.get("locations", discovered_locations)
	defeated = data.get("defeated", defeated)
	signal_active = bool(data.get("signal_active", false))
	guardian_health = int(data.get("guardian_health", 3))
	beast_health = int(data.get("beast_health", 6))
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
		"crafting": panels[panel_name].open(inventory, crafted)
		"map": panels[panel_name].open(discovered_locations)

func _close_panels() -> void:
	for panel in panels.values():
		panel.close()

func _gather(item: String) -> void:
	if not run_started or get_tree().paused:
		return
	if item == "water" and not discovered_locations.get("Freshwater Spring", false):
		status_label.text = "Discover the freshwater spring before gathering water."
		return
	inventory[item] = int(inventory.get(item, 0)) + 1
	_refresh_hud()
	_save_game()

func _explore_next_location() -> void:
	if not run_started or get_tree().paused:
		return
	var mission: Dictionary = mission_manager.get_mission()
	var location := ""
	match str(mission.get("goal", "")):
		"water": location = "Freshwater Spring"
		"forest": location = "Deep Forest"
		"camp": location = "Abandoned Camp"
		"ruins": location = "Ancient Ruins"
		"enemy": location = "Hidden Cave"
		"boss": location = "Signal Ridge"
	if location.is_empty():
		status_label.text = "Follow the current mission before exploring farther."
		return
	discovered_locations[location] = true
	status_label.text = "Discovered: %s" % location
	_refresh_hud()
	_save_game()

func _craft_item(recipe_name: String) -> void:
	var recipe_costs := {
		"Stone Axe": {"wood": 3, "stone": 2},
		"Wooden Spear": {"wood": 3, "stone": 1},
		"Shelter": {"wood": 8, "leaves": 5},
		"Campfire": {"wood": 4, "stone": 3},
		"Water Container": {"leaves": 2, "rope": 2}
	}
	if not recipe_costs.has(recipe_name):
		return
	var costs: Dictionary = recipe_costs[recipe_name]
	for item in costs:
		if int(inventory.get(item, 0)) < int(costs[item]):
			status_label.text = "Not enough materials to craft %s." % recipe_name
			return
	for item in costs:
		inventory[item] = int(inventory.get(item, 0)) - int(costs[item])
	crafted[recipe_name] = int(crafted.get(recipe_name, 0)) + 1
	status_label.text = "Crafted %s." % recipe_name
	panels["crafting"].set_inventory(inventory, crafted)
	_refresh_hud()
	_save_game()

func _attack_encounter() -> void:
	if not run_started or get_tree().paused:
		return
	var goal := str(mission_manager.get_mission().get("goal", ""))
	if goal == "enemy":
		if int(crafted.get("Wooden Spear", 0)) < 1:
			status_label.text = "Craft a wooden spear before entering the cave."
			return
		guardian_health -= 1
		if guardian_health <= 0:
			defeated["guardian"] = true
			encounter_button.text = "Guardian defeated"
		else:
			encounter_button.text = "Attack guardian (%d health left)" % guardian_health
	elif goal == "boss":
		if int(crafted.get("Stone Axe", 0)) < 1 or int(crafted.get("Wooden Spear", 0)) < 1:
			status_label.text = "Craft a stone axe and wooden spear first."
			return
		beast_health -= 1
		if beast_health <= 0:
			defeated["island_beast"] = true
			encounter_button.text = "Island beast defeated"
		else:
			encounter_button.text = "Attack island beast (%d health left)" % beast_health
	else:
		return
	_refresh_hud()
	_save_game()

func _activate_signal() -> void:
	if not bool(defeated.get("island_beast", false)):
		status_label.text = "Defeat the island beast before activating the signal."
		return
	signal_active = true
	status_label.text = "The rescue signal is active!"
	_refresh_hud()
	_save_game()

func _complete_objective() -> void:
	if not run_started or get_tree().paused:
		return
	if mission_manager.complete_current(inventory, discovered_locations, crafted, defeated, signal_active):
		status_label.text = "Mission complete!"
		_save_game()
	_refresh_hud()

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
		objective_button.disabled = true
		objective_button.text = "All missions complete!"
		encounter_button.visible = false
		signal_button.visible = false
		return
	mission_label.text = "Mission %d/10: %s\n%s" % [mission_manager.current_index + 1, mission.title, mission.description]
	var ready_to_claim := mission_manager.is_current_complete(inventory, discovered_locations, crafted, defeated, signal_active)
	objective_button.disabled = not ready_to_claim
	objective_button.text = "Claim objective" if ready_to_claim else "Objective in progress"
	var goal := str(mission.get("goal", ""))
	encounter_button.visible = goal == "enemy" or goal == "boss"
	if goal == "enemy":
		encounter_button.text = "Attack guardian (%d health left)" % maxi(guardian_health, 0) if not defeated.get("guardian", false) else "Guardian defeated"
	elif goal == "boss":
		encounter_button.text = "Attack island beast (%d health left)" % maxi(beast_health, 0) if not defeated.get("island_beast", false) else "Island beast defeated"
	signal_button.visible = goal == "boss" and bool(defeated.get("island_beast", false)) and not signal_active

func _save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"mission_index": mission_manager.get_save_progress(),
		"inventory": inventory,
		"crafted": crafted,
		"locations": discovered_locations,
		"defeated": defeated,
		"signal_active": signal_active,
		"guardian_health": guardian_health,
		"beast_health": beast_health
	}
	file.store_string(JSON.stringify(data))
	file.close()

func _show_settings_message() -> void:
	menu.title.text = "SETTINGS\nComing soon — use the in-game controls to explore."

func _quit_game() -> void:
	get_tree().quit()
