extends Node

signal mission_changed(index: int, title: String)
signal mission_completed(index: int)

const MISSIONS := [
	{"title":"The Crash","description":"Gather at least 2 wood.","goal":"wood","required":2,"reward":"Compass"},
	{"title":"First Survival","description":"Gather 5 wood, 3 stone and 2 food.","goal":"mixed","required":1,"reward":"Fishing hook"},
	{"title":"Find Fresh Water","description":"Discover the spring and gather 3 water.","goal":"water","required":3,"reward":"Water container"},
	{"title":"Build Shelter","description":"Craft a shelter.","goal":"build","required":1,"reward":"Resting bonus"},
	{"title":"Into the Forest","description":"Discover the deep forest.","goal":"forest","required":1,"reward":"Forest map"},
	{"title":"The Abandoned Camp","description":"Discover the abandoned camp.","goal":"camp","required":1,"reward":"Explorer journal"},
	{"title":"The Hidden Cave","description":"Craft a wooden spear and defeat the guardian.","goal":"enemy","required":1,"reward":"Metal shard"},
	{"title":"Ancient Secrets","description":"Discover the ancient ruins.","goal":"ruins","required":1,"reward":"Ancient key"},
	{"title":"The Final Preparation","description":"Craft a stone axe and wooden spear.","goal":"gear","required":1,"reward":"Boss key"},
	{"title":"Escape the Island","description":"Defeat the island beast and activate the signal.","goal":"boss","required":1,"reward":"Victory"}
]

var current_index := 0

func get_mission(index: int = current_index) -> Dictionary:
	if index < 0 or index >= MISSIONS.size():
		return {}
	return MISSIONS[index]

func get_title() -> String:
	var mission := get_mission()
	return "" if mission.is_empty() else str(mission.get("title", ""))

func is_current_complete(inventory: Dictionary, locations: Dictionary, crafted: Dictionary, defeated: Dictionary, signal_active: bool) -> bool:
	var mission := get_mission()
	if mission.is_empty():
		return false
	match str(mission.get("goal", "")):
		"wood": return int(inventory.get("wood", 0)) >= 2
		"mixed": return int(inventory.get("wood", 0)) >= 5 and int(inventory.get("stone", 0)) >= 3 and int(inventory.get("food", 0)) >= 2
		"water": return bool(locations.get("Freshwater Spring", false)) and int(inventory.get("water", 0)) >= 3
		"build": return int(crafted.get("Shelter", 0)) >= 1
		"forest": return bool(locations.get("Deep Forest", false))
		"camp": return bool(locations.get("Abandoned Camp", false))
		"enemy": return int(crafted.get("Wooden Spear", 0)) >= 1 and bool(defeated.get("guardian", false))
		"ruins": return bool(locations.get("Ancient Ruins", false))
		"gear": return int(crafted.get("Stone Axe", 0)) >= 1 and int(crafted.get("Wooden Spear", 0)) >= 1
		"boss": return bool(defeated.get("island_beast", false)) and signal_active
	return false

func complete_current(inventory: Dictionary = {}, locations: Dictionary = {}, crafted: Dictionary = {}, defeated: Dictionary = {}, signal_active: bool = false) -> bool:
	if not is_current_complete(inventory, locations, crafted, defeated, signal_active):
		return false
	var completed_index := current_index
	mission_completed.emit(completed_index)
	current_index += 1
	if current_index < MISSIONS.size():
		mission_changed.emit(current_index, str(MISSIONS[current_index].get("title", "")))
	return true

func set_progress(index: int) -> void:
	current_index = clampi(index, 0, MISSIONS.size())
	if current_index < MISSIONS.size():
		mission_changed.emit(current_index, str(MISSIONS[current_index].get("title", "")))

func get_save_progress() -> int:
	return current_index
