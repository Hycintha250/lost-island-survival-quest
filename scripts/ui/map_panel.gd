extends Control

var discovered: Dictionary = {"Crash Beach": true}

func _ready() -> void:
	visible = false

func open(locations: Dictionary) -> void:
	discovered = locations
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _refresh() -> void:
	var text := "ISLAND MAP\n\n"
	var locations := ["Crash Beach", "Freshwater Spring", "Deep Forest", "Abandoned Camp", "Hidden Cave", "Ancient Ruins", "Signal Ridge"]
	for location in locations:
		text += ("● " if discovered.get(location, false) else "? ") + location + "\n"
	$Panel/Locations.text = text
