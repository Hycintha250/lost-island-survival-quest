extends CharacterBody3D
class_name IslandPlayer

signal interact_requested
signal attack_requested

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 5.0
@export var look_sensitivity := 0.003

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_touching := false
var last_touch := Vector2.ZERO
var mobile_move := Vector2.ZERO
var mobile_sprint := false

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_E:
			interact_requested.emit()
		elif event.keycode == KEY_F:
			attack_requested.emit()
	elif event is InputEventScreenTouch:
		if event.pressed:
			look_touching = event.position.x > get_viewport().get_visible_rect().size.x * 0.45
			last_touch = event.position
		else:
			look_touching = false
	elif event is InputEventScreenDrag and look_touching:
		_rotate_camera(event.relative)

func _rotate_camera(delta: Vector2) -> void:
	rotate_y(-delta.x * look_sensitivity)
	pivot.rotation.x = clampf(pivot.rotation.x - delta.y * look_sensitivity, -0.75, 0.55)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input += mobile_move
	input = input.limit_length(1.0)
	var direction := (global_transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := sprint_speed if (Input.is_action_pressed("sprint") or mobile_sprint) else walk_speed
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var facing := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, facing, delta * 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 4.0 * delta)
	move_and_slide()

func move_touch(direction: Vector2) -> void:
	mobile_move = direction.limit_length(1.0)

func set_touch_sprint(enabled: bool) -> void:
	mobile_sprint = enabled

func request_interact() -> void:
	interact_requested.emit()

func request_attack() -> void:
	attack_requested.emit()

func take_damage(amount: float) -> void:
	get_tree().call_group("game", "damage_player", amount)
