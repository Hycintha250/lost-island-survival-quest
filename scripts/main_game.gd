extends Node3D

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const SAVE_PATH := "user://lost_island_save.json"

var inventory := {"Wood": 0, "Stone": 0, "Leaves": 0, "Food": 0, "Water": 0, "Rope": 0, "Metal": 0}
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var day_time := 0.25
var mission_index := 0
var collected_total := 0
var discovered := {"Crash Beach": true}
var built_count := 0
var player: CharacterBody3D
var hud: Label
var mission_label: Label
var status_label: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var enemy_count := 0
var paused := false

const MISSIONS := [
	{"title":"1 · The Crash", "goal":"Explore the beach and collect 2 wood.", "kind":"Wood", "amount":2},
	{"title":"2 · First Survival", "goal":"Collect 5 wood, 3 stones and 2 food.", "kind":"mixed", "amount":0},
	{"title":"3 · Find Fresh Water", "goal":"Collect 3 water from the freshwater spring.", "kind":"Water", "amount":3},
	{"title":"4 · Build Shelter", "goal":"Craft a shelter from the crafting menu.", "kind":"build", "amount":1},
	{"title":"5 · Into the Forest", "goal":"Discover the forest by traveling inland.", "kind":"forest", "amount":1},
	{"title":"6 · The Abandoned Camp", "goal":"Reach and search the old camp in the east.", "kind":"camp", "amount":1},
	{"title":"7 · The Hidden Cave", "goal":"Defeat the cave guardian near the northern rocks.", "kind":"enemy", "amount":1},
	{"title":"8 · Ancient Secrets", "goal":"Find the ancient ruins in the west.", "kind":"ruins", "amount":1},
	{"title":"9 · The Final Preparation", "goal":"Craft a stone axe and wooden spear.", "kind":"gear", "amount":1},
	{"title":"10 · Escape the Island", "goal":"Defeat the island beast near the signal ridge.", "kind":"boss", "amount":1}
]

func _ready() -> void:
	add_to_group("game")
	_setup_input()
	_build_world()
	_spawn_player()
	_build_ui()
	_spawn_enemies()
	_load_game()
	_update_ui()
	set_process(true)

func _process(delta: float) -> void:
	if paused:
		return
	day_time = fposmod(day_time + delta / 420.0, 1.0)
	hunger = maxf(0.0, hunger - delta * 0.035)
	thirst = maxf(0.0, thirst - delta * 0.055)
	if hunger <= 0.0 or thirst <= 0.0:
		health = maxf(0.0, health - delta * 2.0)
	if health <= 0.0:
		status_label.text = "You have fallen. Tap RESTORE to recover at the beach."
		player.set_physics_process(false)
	if is_instance_valid(player):
		if player.global_position.distance_to(Vector3(0, 0, 0)) > 28.0 and mission_index == 4:
			discovered["Deep Forest"] = true
			_complete_mission_if("forest")
		if player.global_position.distance_to(Vector3(18, 0, -16)) < 9.0:
			discovered["Abandoned Camp"] = true
			_complete_mission_if("camp")
		if player.global_position.distance_to(Vector3(-20, 0, -18)) < 10.0:
			discovered["Ancient Ruins"] = true
			_complete_mission_if("ruins")
	_update_ui()

func _setup_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("jump", KEY_SPACE)
	_add_key_action("sprint", KEY_SHIFT)
	_add_key_action("interact", KEY_E)

func _add_key_action(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.68, 0.76)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.1
	add_child(sun)
	_add_static_box("Island ground", Vector3(0, -1.2, 0), Vector3(105, 2, 105), Color(0.73, 0.62, 0.39))
	_add_static_box("Ocean", Vector3(0, -2.35, 0), Vector3(260, 0.2, 260), Color(0.05, 0.38, 0.53))
	_add_static_box("Freshwater spring", Vector3(-12, -0.05, -8), Vector3(5, 0.15, 5), Color(0.18, 0.72, 0.75), false)
	_add_landmark("Abandoned Camp", Vector3(18, 0, -16), Color(0.55, 0.31, 0.15))
	_add_landmark("Ancient Ruins", Vector3(-20, 0, -18), Color(0.63, 0.64, 0.53))
	_add_landmark("Cave Entrance", Vector3(0, 0, -34), Color(0.13, 0.15, 0.17))
	_add_landmark("Signal Ridge", Vector3(28, 0, 28), Color(0.7, 0.5, 0.22))
	for i in range(48):
		var angle := float(i) * 2.399
		var radius := 10.0 + fmod(float(i) * 13.7, 37.0)
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		if pos.distance_to(Vector3(18, 0, -16)) < 8 or pos.distance_to(Vector3(-20, 0, -18)) < 8:
			continue
		_add_tree(pos, 0.75 + fmod(float(i) * 0.11, 0.7))
	for i in range(22):
		var pos := Vector3(cos(float(i) * 2.1) * (8 + i % 6 * 5), 0, sin(float(i) * 2.1) * (8 + i % 6 * 5))
		_add_resource(pos, "Wood" if i % 2 == 0 else "Stone")
	_add_resource(Vector3(-12, 0, -8), "Water")
	_add_resource(Vector3(4, 0, 3), "Food")
	_add_resource(Vector3(25, 0, 5), "Food")

func _add_static_box(title: String, pos: Vector3, size: Vector3, color: Color, collide := true) -> void:
	var body := StaticBody3D.new() if collide else Node3D.new()
	body.name = title
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material_override = mat
	body.add_child(mesh)
	if collide:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)

func _add_tree(pos: Vector3, scale_value: float) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	add_child(tree)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.34
	trunk_mesh.height = 3.2
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.6
	trunk.material_override = _material(Color(0.35, 0.19, 0.09))
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.5
	crown_mesh.height = 2.5
	crown.mesh = crown_mesh
	crown.position.y = 3.3
	crown.material_override = _material(Color(0.12, 0.38, 0.17))
	tree.add_child(crown)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	return mat

func _add_landmark(title: String, pos: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	marker.name = title
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.7
	mesh.bottom_radius = 1.4
	mesh.height = 1.8
	marker.mesh = mesh
	marker.position = pos + Vector3.UP * 0.9
	marker.material_override = _material(color)
	add_child(marker)

func _add_resource(pos: Vector3, kind: String) -> void:
	var item := Area3D.new()
	item.name = kind + "Pickup"
	item.set_meta("resource_kind", kind)
	item.collision_layer = 2
	item.collision_mask = 0
	item.position = pos + Vector3.UP * 0.65
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.1
	shape_node.shape = shape
	item.add_child(shape_node)
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.45
	mesh.height = 0.9
	visual.mesh = mesh
	var color := Color(0.46, 0.27, 0.12)
	match kind:
		"Stone": color = Color(0.48, 0.51, 0.52)
		"Food": color = Color(0.91, 0.27, 0.16)
		"Water": color = Color(0.14, 0.69, 0.92)
	visual.material_override = _material(color)
	item.add_child(visual)
	add_child(item)

func _spawn_player() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	player = packed.instantiate() as CharacterBody3D
	player.position = Vector3(0, 0.2, 8)
	add_child(player)
	player.interact_requested.connect(_interact)
	player.attack_requested.connect(_attack)

func _spawn_enemies() -> void:
	for position in [Vector3(5, 0.5, -24), Vector3(24, 0.5, 12), Vector3(-25, 0.5, 24)]:
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.position = position
		enemy.name = "Island Beast"
		var mesh_node := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.8
		mesh.height = 1.5
		mesh_node.mesh = mesh
		mesh_node.position.y = 0.75
		mesh_node.material_override = _material(Color(0.36, 0.17, 0.13))
		enemy.add_child(mesh_node)
		var shape_node := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.55
		shape.height = 1.6
		shape_node.shape = shape
		enemy.add_child(shape_node)
		add_child(enemy)
		enemy_count += 1

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	hud = Label.new()
	hud.position = Vector2(18, 16)
	hud.add_theme_font_size_override("font_size", 19)
	hud.add_theme_color_override("font_color", Color(0.93, 0.97, 0.88))
	root.add_child(hud)
	mission_label = Label.new()
	mission_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	mission_label.position.y = 16
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_size_override("font_size", 18)
	mission_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.53))
	root.add_child(mission_label)
	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status_label.position.y = -44
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	root.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-18, -95)
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	_add_action_button(actions, "INTERACT", "interact")
	_add_action_button(actions, "ATTACK", "attack")
	_add_action_button(actions, "JUMP", "jump")
	_add_action_button(actions, "SPRINT", "sprint")
	_add_action_button(actions, "BAG", "inventory")
	_add_action_button(actions, "CRAFT", "craft")
	_add_action_button(actions, "SAVE", "save")
	var mobile_pad := HBoxContainer.new()
	mobile_pad.position = Vector2(18, -115)
	mobile_pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	root.add_child(mobile_pad)
	_add_move_button(mobile_pad, "◀", Vector2(-1, 0))
	_add_move_button(mobile_pad, "▲", Vector2(0, -1))
	_add_move_button(mobile_pad, "▼", Vector2(0, 1))
	_add_move_button(mobile_pad, "▶", Vector2(1, 0))
	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(24, 120)
	inventory_panel.custom_minimum_size = Vector2(340, 250)
	inventory_panel.visible = false
	root.add_child(inventory_panel)
	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 17)
	inventory_panel.add_child(inventory_label)
	var restore := Button.new()
	restore.text = "RESTORE"
	restore.position = Vector2(16, 62)
	restore.pressed.connect(_restore)
	root.add_child(restore)

func _add_action_button(parent: HBoxContainer, title: String, action: String) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(80, 56)
	button.add_theme_font_size_override("font_size", 14)
	parent.add_child(button)
	match action:
		"interact": button.pressed.connect(_interact)
		"attack": button.pressed.connect(_attack)
		"jump": button.pressed.connect(func(): Input.action_press("jump"); await get_tree().create_timer(0.12).timeout; Input.action_release("jump"))
		"sprint":
			button.button_down.connect(func(): player.set_touch_sprint(true))
			button.button_up.connect(func(): player.set_touch_sprint(false))
		"inventory": button.pressed.connect(_toggle_inventory)
		"craft": button.pressed.connect(_show_crafting)
		"save": button.pressed.connect(_save_game)

func _add_move_button(parent: HBoxContainer, title: String, direction: Vector2) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(58, 58)
	parent.add_child(button)
	button.button_down.connect(func(): player.move_touch(direction))
	button.button_up.connect(func(): player.move_touch(Vector2.ZERO))

func _update_ui() -> void:
	if not is_instance_valid(hud):
		return
	hud.text = "♥ %.0f   FOOD %.0f   WATER %.0f\nDay %d · %s" % [health, hunger, thirst, int(day_time * 4) + 1, _time_name()]
	if mission_index < MISSIONS.size():
		var mission: Dictionary = MISSIONS[mission_index]
		mission_label.text = "%s\n%s" % [mission.title, mission.goal]
	else:
		mission_label.text = "ESCAPE COMPLETE · The island's signal is active!"
	if inventory_panel.visible:
		inventory_label.text = "BACKPACK\n" + _inventory_text()

func _time_name() -> String:
	return "Morning" if day_time < 0.25 else ("Day" if day_time < 0.5 else ("Evening" if day_time < 0.75 else "Night"))

func _inventory_text() -> String:
	var text := ""
	for key in inventory:
		text += "%s: %d\n" % [key, inventory[key]]
	return text

func _interact() -> void:
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.2, player.global_position + Vector3.UP * 1.2 + -player.global_transform.basis.z * 4.0, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		status_label.text = "Nothing in reach. Look toward a resource or landmark."
		return
	var target: Object = hit.collider
	if target is Area3D and target.has_meta("resource_kind"):
		var kind: String = target.get_meta("resource_kind")
		inventory[kind] = int(inventory.get(kind, 0)) + (2 if kind == "Water" else 1)
		collected_total += 1
		target.queue_free()
		status_label.text = "Collected %s" % kind
		if mission_index == 0 and kind == "Wood" and inventory.Wood >= 2:
			_complete_mission_if("Wood")
		elif mission_index == 1 and inventory.Wood >= 5 and inventory.Stone >= 3 and inventory.Food >= 2:
			_complete_mission_if("mixed")
		elif mission_index == 2 and inventory.Water >= 3:
			_complete_mission_if("Water")
	elif target is CharacterBody3D and target.has_method("take_hit"):
		target.take_hit(30.0)
	else:
		status_label.text = "You found a clue at %s." % target.name
		if target.name.contains("Camp"):
			discovered["Abandoned Camp"] = true
			_complete_mission_if("camp")
		elif target.name.contains("Ruins"):
			discovered["Ancient Ruins"] = true
			_complete_mission_if("ruins")
	_update_ui()

func _attack() -> void:
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, player.global_position + Vector3.UP + -player.global_transform.basis.z * 3.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("take_hit"):
		hit.collider.take_hit(20.0)
		status_label.text = "You strike the beast!"
	else:
		status_label.text = "Attack missed. Get closer to a creature."

func enemy_defeated(enemy: Node) -> void:
	var was_boss := enemy.global_position.distance_to(Vector3(28, 0, 28)) < 15.0
	enemy.queue_free()
	enemy_count = maxi(0, enemy_count - 1)
	inventory.Meat = int(inventory.get("Meat", 0)) + 1
	status_label.text = "Creature defeated · collected meat"
	if mission_index == 6 or (mission_index == 9 and was_boss):
		_complete_mission_if("boss" if mission_index == 9 else "enemy")

func damage_player(amount: float) -> void:
	health = maxf(0.0, health - amount)
	status_label.text = "Attacked! Health -%d" % int(amount)

func _complete_mission_if(kind: String) -> void:
	if mission_index >= MISSIONS.size() or MISSIONS[mission_index].kind != kind:
		return
	status_label.text = "MISSION COMPLETE · Supplies recovered"
	mission_index += 1
	if mission_index >= MISSIONS.size():
		status_label.text = "VICTORY · The rescue signal reaches the mainland!"
	_update_ui()
	_save_game()

func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	_update_ui()

func _show_crafting() -> void:
	var popup := AcceptDialog.new()
	popup.title = "Crafting · costs in parentheses"
	popup.dialog_text = "Stone Axe (3 wood, 2 stone)\nWooden Spear (3 wood, 1 stone)\nShelter (8 wood, 5 leaves)\nCampfire (4 wood, 3 stone)\n\nUse these buttons to craft:"
	for recipe in ["Stone Axe", "Wooden Spear", "Shelter", "Campfire"]:
		var button := Button.new()
		button.text = "Craft " + recipe
		button.pressed.connect(_craft.bind(recipe, popup))
		popup.add_child(button)
	add_child(popup)
	popup.popup_centered()

func _craft(recipe: String, popup: AcceptDialog) -> void:
	var costs: Dictionary = {"Stone Axe":{"Wood":3,"Stone":2}, "Wooden Spear":{"Wood":3,"Stone":1}, "Shelter":{"Wood":8,"Leaves":5}, "Campfire":{"Wood":4,"Stone":3}}
	var cost: Dictionary = costs[recipe]
	for key in cost:
		if int(inventory.get(key, 0)) < cost[key]:
			status_label.text = "Not enough %s to craft %s." % [key, recipe]
			return
	for key in cost:
		inventory[key] -= cost[key]
	if recipe == "Shelter" or recipe == "Campfire":
		built_count += 1
		var visual := MeshInstance3D.new()
		visual.mesh = BoxMesh.new()
		visual.position = player.global_position + -player.global_transform.basis.z * 3.0 + Vector3.UP * 0.6
		visual.scale = Vector3(2.2, 1.2, 1.6) if recipe == "Shelter" else Vector3(0.8, 0.3, 0.8)
		visual.material_override = _material(Color(0.48, 0.28, 0.12) if recipe == "Shelter" else Color(0.95, 0.31, 0.08))
		add_child(visual)
		if mission_index == 3:
			_complete_mission_if("build")
	if recipe == "Stone Axe": inventory["Stone Axe"] = 1
	if recipe == "Wooden Spear": inventory["Wooden Spear"] = 1
	status_label.text = "Crafted %s" % recipe
	popup.queue_free()
	_update_ui()

func _restore() -> void:
	health = 100.0
	hunger = 75.0
	thirst = 75.0
	player.set_physics_process(true)
	player.global_position = Vector3(0, 0.2, 8)
	status_label.text = "You wake on the beach, ready to try again."

func _save_game() -> void:
	var data := {"position": [player.global_position.x, player.global_position.y, player.global_position.z], "health": health, "hunger": hunger, "thirst": thirst, "inventory": inventory, "mission_index": mission_index, "discovered": discovered, "built_count": built_count, "day_time": day_time}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		status_label.text = "Progress saved on this device."

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	var coords: Array = data.get("position", [0, 0.2, 8])
	player.global_position = Vector3(float(coords[0]), float(coords[1]), float(coords[2]))
	health = float(data.get("health", 100.0))
	hunger = float(data.get("hunger", 100.0))
	thirst = float(data.get("thirst", 100.0))
	mission_index = clampi(int(data.get("mission_index", 0)), 0, MISSIONS.size())
	inventory = data.get("inventory", inventory)
	discovered = data.get("discovered", discovered)
	built_count = int(data.get("built_count", 0))
	day_time = float(data.get("day_time", 0.25))
	status_label.text = "Saved island journey restored."
