extends Control

@onready var title_label: Label = $Panel/Header/Title
@onready var list: VBoxContainer = $Panel/Scroll/List

var mission_manager: Node

func configure(manager: Node) -> void:
	mission_manager = manager
	_refresh()

func _ready() -> void:
	visible = false

func open() -> void:
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _refresh() -> void:
	if not is_instance_valid(list):
		return
	for child in list.get_children():
		child.queue_free()
	if not is_instance_valid(mission_manager):
		return
	for i in range(mission_manager.MISSIONS.size()):
		var mission: Dictionary = mission_manager.MISSIONS[i]
		var row := Label.new()
		if i < mission_manager.current_index:
			row.text = "✓ %02d  %s — Complete" % [i + 1, mission.title]
		elif i == mission_manager.current_index:
			row.text = "▶ %02d  %s — %s" % [i + 1, mission.title, mission.description]
		else:
			row.text = "○ %02d  %s — Locked" % [i + 1, mission.title]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(row)
	var mission: Dictionary = mission_manager.get_mission()
	title_label.text = "MISSIONS" if mission.is_empty() else "MISSION %d / 10" % (mission_manager.current_index + 1)
