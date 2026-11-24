extends Control

var inventory: Dictionary = {}

func _ready() -> void:
	visible = false

func open(items: Dictionary) -> void:
	inventory = items
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _refresh() -> void:
	$Panel/Items.text = "CRAFTING\n\nStone Axe — 3 Wood, 2 Stone\nWooden Spear — 3 Wood, 1 Stone\nShelter — 8 Wood, 5 Leaves\nCampfire — 4 Wood, 3 Stone\nWater Container — 2 Leaves, 2 Rope"
