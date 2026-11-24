extends CharacterBody3D

@export var health := 35.0
@export var move_speed := 2.4
@export var attack_range := 1.8
var attack_cooldown := 0.0
var player: CharacterBody3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var offset: Vector3 = player.global_position - global_position
	var distance := offset.length()
	if distance < 18.0 and distance > attack_range:
		var direction := offset.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if distance <= attack_range and attack_cooldown <= 0.0:
		player.take_damage(7.0)
		attack_cooldown = 1.7

func take_hit(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		get_tree().call_group("game", "enemy_defeated", self)
