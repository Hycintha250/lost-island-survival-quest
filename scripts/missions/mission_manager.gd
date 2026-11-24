extends Node

signal mission_changed(index: int, title: String)
signal mission_completed(index: int)

const MISSIONS := [
	{"title":"The Crash","description":"Explore the beach and collect 2 wood.","goal":"wood","required":2,"reward":"Compass"},
	{"title":"First Survival","description":"Collect 5 wood, 3 stone and 2 food.","goal":"mixed","required":1,"reward":"Fishing hook"},
	{"title":"Find Fresh Water","description":"Collect 3 water from the freshwater spring.","goal":"water","required":3,"reward":"Water container"},
	{"title":"Build Shelter","description":"Craft a shelter using the crafting menu.","goal":"build","required":1,"reward":"Resting bonus"},
	{"title":"Into the Forest","description":"Travel inland and discover the deep forest.","goal":"forest","required":1,"reward":"Forest map"},
	{"title":"The Abandoned Camp","description":"Search the abandoned camp in the east.","goal":"camp","required":1,"reward":"Explorer journal"},
	{"title":"The Hidden Cave","description":"Defeat the guardian near the cave.","goal":"enemy","required":1,"reward":"Metal shard"},
	{"title":"Ancient Secrets","description":"Discover the ancient ruins in the west.","goal":"ruins","required":1,"reward":"Ancient key"},
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
	return "" if mission.is_empty() else mission.title

func complete_current() -> bool:
	if current_index >= MISSIONS.size():
		return false
	var completed_index := current_index
	mission_completed.emit(completed_index)
	current_index += 1
	if current_index < MISSIONS.size():
		mission_changed.emit(current_index, MISSIONS[current_index].title)
	return true

func set_progress(index: int) -> void:
	current_index = clampi(index, 0, MISSIONS.size())
	if current_index < MISSIONS.size():
		mission_changed.emit(current_index, MISSIONS[current_index].title)

func get_save_progress() -> int:
	return current_index
