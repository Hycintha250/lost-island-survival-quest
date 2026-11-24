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
	var text := "INVENTORY\n\n"
	for key in inventory:
		var amount: int = int(inventory[key])
		text += "%s  ×%d\n" % [key, amount]
	$Panel/Items.text = text
