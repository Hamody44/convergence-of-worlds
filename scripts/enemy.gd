class_name ActionRPGEnemy
extends CharacterBody3D

@export var maximum_health: float = 90.0
@export var detection_range: float = 11.0
@export var melee_range: float = 2.1
@export var attack_damage: float = 12.0
@export var attack_interval: float = 1.6
@export var experience_reward: int = 35
@export var respawn_delay: float = 4.0

var health: float
var spawn_position: Vector3
var attack_timer: float = 0.0
var respawn_timer: float = 0.0
var is_defeated: bool = false
var body_visual: MeshInstance3D
var eye_left: MeshInstance3D
var eye_right: MeshInstance3D
var health_label: Label3D
var name_label: Label3D
var status_label: Label3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.3
	spawn_position = global_position
	health = maximum_health
	_build_enemy()
	_update_health_display()

func _physics_process(delta: float) -> void:
	if is_defeated:
		velocity = Vector3.ZERO
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	var player := _get_player()
	if player == null:
		_patrol_idle(delta)
		return

	var distance := global_position.distance_to(player.global_position)
	if distance <= detection_range:
		_chase_or_attack(player, distance, delta)
	else:
		_patrol_idle(delta)

	if not is_on_floor():
		velocity.y -= get_gravity().length() * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _build_enemy() -> void:
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.58
	capsule_shape.height = 2.2
	collision.shape = capsule_shape
	collision.position.y = 1.1
	add_child(collision)

	body_visual = MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.58
	body_mesh.height = 2.2
	body_mesh.radial_segments = 16
	body_mesh.rings = 8
	body_visual.mesh = body_mesh
	body_visual.position.y = 1.1
	body_visual.material_override = _make_material(Color("#641b2b"), 0.05)
	add_child(body_visual)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.48
	head_mesh.height = 0.96
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.25, 0.0)
	head.material_override = _make_material(Color("#3f1020"), 0.0)
	add_child(head)

	eye_left = _make_eye(Vector3(-0.18, 2.32, -0.42))
	eye_right = _make_eye(Vector3(0.18, 2.32, -0.42))

	name_label = Label3D.new()
	name_label.text = "VOID HUNTER"
	name_label.position = Vector3(0.0, 3.55, 0.0)
	name_label.font_size = 25
	name_label.outline_size = 7
	name_label.modulate = Color("#fecaca")
	add_child(name_label)

	health_label = Label3D.new()
	health_label.position = Vector3(0.0, 3.18, 0.0)
	health_label.font_size = 24
	health_label.outline_size = 6
	health_label.modulate = Color("#fca5a5")
	add_child(health_label)

func _make_eye(eye_position: Vector3) -> MeshInstance3D:
	var eye := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.09
	eye_mesh.height = 0.18
	eye.mesh = eye_mesh
	eye.position = eye_position
	eye.material_override = _make_emission_material(Color("#fbbf24"))
	add_child(eye)
	return eye

func _chase_or_attack(player: ActionRPGPlayer, distance: float, delta: float) -> void:
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		return
	direction = direction.normalized()
	look_at(global_position + direction, Vector3.UP)
	if distance > melee_range:
		velocity.x = move_toward(velocity.x, direction.x * 2.8, 12.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * 2.8, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			player.take_damage(attack_damage)
			_spawn_attack_flash()

func _patrol_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)

func take_damage(amount: float) -> void:
	if is_defeated:
		return
	var applied_damage := maxf(amount, 0.0)
	health = maxf(health - applied_damage, 0.0)
	_show_damage_number(applied_damage)
	_update_health_display()
	if health <= 0.0:
		_defeat()

func _defeat() -> void:
	is_defeated = true
	respawn_timer = respawn_delay
	velocity = Vector3.ZERO
	var player := _get_player()
	if player != null and player.stats != null:
		player.stats.add_experience(experience_reward)
		player.stats.advance_path_progress(0.5)
	_spawn_death_effect()
	body_visual.visible = false
	eye_left.visible = false
	eye_right.visible = false
	name_label.visible = false
	health_label.visible = false
	status_label = Label3D.new()
	status_label.text = "+%d XP\nRESPAWNING..." % experience_reward
	status_label.position = Vector3(0.0, 2.1, 0.0)
	status_label.font_size = 28
	status_label.outline_size = 7
	status_label.modulate = Color("#fde68a")
	add_child(status_label)

func _respawn() -> void:
	is_defeated = false
	global_position = spawn_position
	health = maximum_health
	attack_timer = 0.0
	body_visual.visible = true
	eye_left.visible = true
	eye_right.visible = true
	name_label.visible = true
	health_label.visible = true
	if is_instance_valid(status_label):
		status_label.queue_free()
	_update_health_display()

func _get_player() -> ActionRPGPlayer:
	var node := get_tree().get_first_node_in_group("player")
	if node is ActionRPGPlayer:
		return node as ActionRPGPlayer
	return null

func _update_health_display() -> void:
	if not is_instance_valid(health_label):
		return
	var filled := clampi(ceili((health / maximum_health) * 10.0), 0, 10)
	health_label.text = "HP [%s%s] %d/%d" % ["|".repeat(filled), ".".repeat(10 - filled), roundi(health), roundi(maximum_health)]

func _show_damage_number(amount: float) -> void:
	var damage_label := Label3D.new()
	damage_label.text = "-%d" % roundi(amount)
	damage_label.position = Vector3(0.0, 2.8, 0.0)
	damage_label.font_size = 32
	damage_label.modulate = Color("#fca5a5")
	damage_label.outline_size = 7
	add_child(damage_label)
	var tween := damage_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position", Vector3(0.0, 4.1, 0.0), 0.65)
	tween.tween_property(damage_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.65)
	tween.chain().tween_callback(damage_label.queue_free)

func _spawn_attack_flash() -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.24
	mesh.height = 0.48
	flash.mesh = mesh
	flash.position = Vector3(0.0, 1.25, -1.0)
	flash.material_override = _make_emission_material(Color("#ef4444"))
	add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 1.8, 0.16)
	tween.tween_property(flash, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.16)
	tween.tween_callback(flash.queue_free)

func _spawn_death_effect() -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.35
	mesh.outer_radius = 1.1
	ring.mesh = mesh
	ring.position.y = 0.12
	ring.material_override = _make_emission_material(Color("#ef4444"))
	add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * 2.2, 0.55)
	tween.tween_property(ring, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.55)
	tween.chain().tween_callback(ring.queue_free)

func _make_material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.72
	return material

func _make_emission_material(color: Color) -> StandardMaterial3D:
	var material := _make_material(color, 0.0)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	return material
