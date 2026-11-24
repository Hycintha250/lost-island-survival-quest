extends Control

signal craft_requested(recipe_name: String)
signal close_requested

const RECIPES := {
	"Stone Axe": {"cost": {"wood": 3, "stone": 2}},
	"Wooden Spear": {"cost": {"wood": 3, "stone": 1}},
	"Shelter": {"cost": {"wood": 8, "leaves": 5}},
	"Campfire": {"cost": {"wood": 4, "stone": 3}},
	"Water Container": {"cost": {"leaves": 2, "rope": 2}}
}

var inventory: Dictionary = {}
var crafted: Dictionary = {}

@onready var recipe_list: VBoxContainer = $Panel/Content/RecipeList
@onready var status_label: Label = $Panel/Content/Status

func _ready() -> void:
	visible = false
	$Panel/Content/Header/Close.pressed.connect(func(): close_requested.emit())
	_refresh()

func open(items: Dictionary, items_crafted: Dictionary = {}) -> void:
	inventory = items
	crafted = items_crafted
	_refresh()
	visible = true

func set_inventory(items: Dictionary, items_crafted: Dictionary) -> void:
	inventory = items
	crafted = items_crafted
	_refresh()

func close() -> void:
	visible = false

func _refresh() -> void:
	if not is_instance_valid(recipe_list):
		return
	for child in recipe_list.get_children():
		child.queue_free()
	for recipe_name in RECIPES:
		var cost: Dictionary = RECIPES[recipe_name]["cost"]
		var parts: Array[String] = []
		var can_craft := true
		for item in cost:
			var amount := int(cost[item])
			parts.append("%d %s" % [amount, str(item).capitalize()])
			if int(inventory.get(item, 0)) < amount:
				can_craft = false
		var button := Button.new()
		button.text = "%s — %s (owned: %d)" % [recipe_name, ", ".join(parts), int(crafted.get(recipe_name, 0))]
		button.disabled = not can_craft
		button.pressed.connect(func(): craft_requested.emit(recipe_name))
		recipe_list.add_child(button)
	status_label.text = "Materials: %s" % _inventory_summary()

func _inventory_summary() -> String:
	var parts: Array[String] = []
	for item in inventory:
		if int(inventory[item]) > 0:
			parts.append("%s %d" % [str(item).capitalize(), int(inventory[item])])
	return ", ".join(parts) if not parts.is_empty() else "none"
