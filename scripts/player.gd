class_name ActionRPGPlayer
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float, energy_name: String)
signal skill_state_changed(slot: int, skill_name: String, unlocked: bool, cooldown_ratio: float, enough_energy: bool)

@export var stats: PlayerStats = PlayerStats.new()

const CAMERA_DISTANCE: float = 7.5
const CAMERA_HEIGHT: float = 2.4
const CAMERA_SENSITIVITY: float = 0.012
const BASE_JUMP_VELOCITY: float = 7.0
const PROJECTILE_SCRIPT := preload("res://scripts/combat_projectile.gd")

var touch_move: Vector2 = Vector2.ZERO
var camera_yaw: float = 0.0
var camera_pitch: float = -0.20
var attack_cooldown: float = 0.0
var attack_flash_time: float = 0.0
var current_jump_velocity: float = BASE_JUMP_VELOCITY
var attack_interval: float = 0.42
var max_health: float = 100.0
var health: float = 100.0
var max_path_energy: float = 60.0
var path_energy: float = 60.0
var energy_regeneration: float = 4.0
var iron_body_time: float = 0.0
var qi_boost_time: float = 0.0
var second_circle_time: float = 0.0
var arcane_shield_time: float = 0.0
var arcane_shield_strength: float = 0.0
var golden_aura_time: float = 0.0
var golden_aura_bonus: float = 1.0
var skill_cooldowns: Dictionary = {}

var visual: MeshInstance3D
var camera_rig: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var attack_marker: MeshInstance3D
var basic_hitbox: Area3D

func _ready() -> void:
	_build_player_nodes()
	_build_basic_hitbox()
	_apply_camera_rotation()
	if stats != null:
		stats.stat_changed.connect(_on_stat_changed)
		stats.path_selected.connect(_on_path_selected)
		_sync_derived_stats()
		_reset_energy()

func _build_player_nodes() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.48
	capsule_shape.height = 1.9
	collision.shape = capsule_shape
	collision.position.y = 0.95
	add_child(collision)
	
	visual = MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.48
	capsule_mesh.height = 1.9
	capsule_mesh.radial_segments = 16
	capsule_mesh.rings = 8
	visual.mesh = capsule_mesh
	visual.position.y = 0.95
	visual.material_override = _make_material(Color("#3b82f6"), 0.15)
	add_child(visual)
	
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.34
	head_mesh.height = 0.68
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.05, 0.0)
	head.material_override = _make_material(Color("#f2c6a0"), 0.0)
	add_child(head)
	
	camera_rig = Node3D.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(0.0, CAMERA_HEIGHT, 0.0)
	add_child(camera_rig)
	
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = CAMERA_DISTANCE
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	camera_rig.add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 68.0
	spring_arm.add_child(camera)
	
	attack_marker = MeshInstance3D.new()
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.18, 0.18, 1.35)
	attack_marker.mesh = marker_mesh
	attack_marker.position = Vector3(0.0, 1.0, -0.85)
	attack_marker.material_override = _make_emission_material(Color("#facc15"))
	attack_marker.visible = false
	add_child(attack_marker)

func _build_basic_hitbox() -> void:
	basic_hitbox = Area3D.new()
	basic_hitbox.name = "BasicAttackHitbox"
	basic_hitbox.collision_layer = 0
	basic_hitbox.collision_mask = 4
	basic_hitbox.monitoring = false
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.6, 2.2)
	shape_node.shape = shape
	shape_node.position = Vector3(0.0, 1.0, -1.25)
	basic_hitbox.add_child(shape_node)
	add_child(basic_hitbox)

func _physics_process(delta: float) -> void:
	_update_combat_timers(delta)
	var input_vector := _get_movement_input()
	# Use the player's local axes for deterministic controls.
	# W/Up = local -Z, S/Down = local +Z, A/Left = local -X, D/Right = local +X.
	var local_movement := Vector3(input_vector.x, 0.0, -input_vector.y)
	var movement := global_transform.basis * local_movement
	movement.y = 0.0
	if movement.length_squared() > 0.001:
		movement = movement.normalized()
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	var target_speed := stats.get_move_speed() * golden_aura_bonus
	velocity.x = move_toward(velocity.x, movement.x * target_speed, 30.0 * delta)
	velocity.z = move_toward(velocity.z, movement.z * target_speed, 30.0 * delta)
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = current_jump_velocity
	else:
		velocity.y -= get_gravity().length() * delta
	if Input.is_action_just_pressed("attack"):
		basic_attack()
	if Input.is_action_just_pressed("skill_1"):
		use_skill(1)
	if Input.is_action_just_pressed("skill_2"):
		use_skill(2)
	if Input.is_action_just_pressed("skill_3"):
		use_skill(3)
	move_and_slide()
	if attack_flash_time > 0.0:
		attack_marker.rotation.y = sin(attack_flash_time * 24.0) * 0.8

func _process(_delta: float) -> void:
	_emit_skill_states()

func _get_movement_input() -> Vector2:
	# Use explicit signs: W/Up = forward, S/Down = backward.
	var keyboard := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		keyboard.x -= 1.0
	if Input.is_action_pressed("move_right"):
		keyboard.x += 1.0
	if Input.is_action_pressed("move_forward"):
		keyboard.y += 1.0
	if Input.is_action_pressed("move_backward"):
		keyboard.y -= 1.0
	# The touch D-pad uses Vector2.UP for its visual up button, so invert only its Y axis.
	var touch_input := Vector2(touch_move.x, -touch_move.y)
	return (keyboard + touch_input).limit_length(1.0)

func basic_attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = attack_interval
	attack_flash_time = 0.22
	var damage := (12.0 + float(stats.strength) * 5.0) * golden_aura_bonus
	basic_hitbox.monitoring = true
	for body: Node3D in basic_hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
	var timer := get_tree().create_timer(0.12)
	timer.timeout.connect(func() -> void: basic_hitbox.monitoring = false)
	_spawn_box_effect(global_position - global_transform.basis.z * 1.3 + Vector3.UP, Vector3(2.0, 0.16, 0.55), Color("#fde047"), 0.18)
	stats.advance_path_progress(0.15)

func use_skill(slot: int) -> void:
	if stats.chosen_path == PlayerStats.Path.NONE or slot < 1 or slot > 3:
		return
	var definitions := stats.get_skill_definitions()
	if definitions.size() < slot:
		return
	var definition: Dictionary = definitions[slot - 1]
	var skill_id := String(definition.get("id", ""))
	if not stats.is_skill_unlocked(skill_id):
		return
	var cooldown_left: float = float(skill_cooldowns.get(skill_id, 0.0))
	if cooldown_left > 0.0:
		return
	var cost := _skill_energy_cost(skill_id)
	if path_energy < cost:
		return
	path_energy -= cost
	_sync_energy_to_stats()
	skill_cooldowns[skill_id] = _skill_cooldown(skill_id)
	_execute_skill(skill_id)
	energy_changed.emit(path_energy, max_path_energy, _energy_name())

func _execute_skill(skill_id: String) -> void:
	var damage_scale := 1.0 + float(stats.wisdom) * 0.08 if stats.chosen_path == PlayerStats.Path.MAGIC else 1.0
	if qi_boost_time > 0.0:
		damage_scale *= 1.5
	match skill_id:
		"iron_body":
			iron_body_time = 5.0
			visual.material_override = _make_emission_material(Color("#d1d5db"))
			_spawn_ring_effect(Color("#e5e7eb"), 1.1, 1.0)
		"soul_palm":
			_spawn_shockwave(4.0, (25.0 + stats.strength * 4.0) * damage_scale, Color("#fbbf24"))
		"will_breaker":
			_damage_in_front((50.0 + stats.strength * 8.0 + stats.willpower * 6.0) * damage_scale, 3.0)
			_spawn_box_effect(global_position - global_transform.basis.z * 1.5 + Vector3.UP, Vector3(3.0, 0.35, 1.2), Color("#f59e0b"), 0.25)
		"qi_gathering":
			path_energy = minf(path_energy + 28.0, max_path_energy)
			qi_boost_time = 6.0
			_sync_energy_to_stats()
			_spawn_ring_effect(Color("#22d3ee"), 1.5, 1.4)
		"spirit_step":
			var old_position := global_position
			global_position += -global_transform.basis.z * 5.5
			_spawn_trail(old_position, global_position, Color("#22d3ee"))
		"immortal_sword_qi":
			_spawn_projectile((35.0 + stats.wisdom * 5.0) * damage_scale, Color("#67e8f9"), 21.0, "blade")
		"mana_bolt":
			_spawn_projectile((24.0 + stats.wisdom * 7.0) * damage_scale, Color("#a78bfa"), 19.0, "sphere")
		"second_circle":
			second_circle_time = 8.0
			_spawn_ring_effect(Color("#c084fc"), 2.0, 2.5)
		"arcane_shield":
			arcane_shield_time = 7.0
			arcane_shield_strength = 70.0 + stats.willpower * 8.0
			_spawn_shield_effect()
		"aura_slash":
			_spawn_projectile((32.0 + stats.strength * 6.0) * damage_scale, Color("#fb923c"), 17.0, "blade")
		"knight_dash":
			var dash_start := global_position
			global_position += -global_transform.basis.z * 6.0
			_damage_in_front(38.0 + stats.strength * 7.0, 3.0)
			_spawn_trail(dash_start, global_position, Color("#fbbf24"))
		"golden_aura":
			golden_aura_time = 8.0
			golden_aura_bonus = 1.3
			_spawn_ring_effect(Color("#facc15"), 2.2, 2.0)
	stats.advance_path_progress(1.0)

func take_damage(amount: float) -> void:
	var reduced := amount
	if iron_body_time > 0.0:
		reduced *= 0.45
	if arcane_shield_time > 0.0 and arcane_shield_strength > 0.0:
		var absorbed := minf(arcane_shield_strength, reduced)
		arcane_shield_strength -= absorbed
		reduced -= absorbed
	if reduced <= 0.0:
		return
	health = maxf(health - reduced, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		health = max_health
		health_changed.emit(health, max_health)

func rotate_camera_by(delta_pixels: Vector2) -> void:
	camera_yaw -= delta_pixels.x * CAMERA_SENSITIVITY
	camera_pitch = clampf(camera_pitch - delta_pixels.y * CAMERA_SENSITIVITY, -0.95, 0.35)
	_apply_camera_rotation()

func _update_combat_timers(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	attack_flash_time = maxf(attack_flash_time - delta, 0.0)
	iron_body_time = maxf(iron_body_time - delta, 0.0)
	qi_boost_time = maxf(qi_boost_time - delta, 0.0)
	second_circle_time = maxf(second_circle_time - delta, 0.0)
	arcane_shield_time = maxf(arcane_shield_time - delta, 0.0)
	golden_aura_time = maxf(golden_aura_time - delta, 0.0)
	if golden_aura_time <= 0.0:
		golden_aura_bonus = 1.0
	if iron_body_time <= 0.0 and visual != null:
		visual.material_override = _make_material(Color("#3b82f6"), 0.15)
	for skill_id: String in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = maxf(float(skill_cooldowns[skill_id]) - delta, 0.0)
	if stats.chosen_path != PlayerStats.Path.NONE:
		path_energy = minf(path_energy + energy_regeneration * delta, max_path_energy)
		_sync_energy_to_stats()
		energy_changed.emit(path_energy, max_path_energy, _energy_name())

func _sync_derived_stats() -> void:
	if stats == null:
		return
	current_jump_velocity = BASE_JUMP_VELOCITY + float(maxi(stats.agility - 1, 0)) * 0.4
	attack_interval = maxf(0.16, 0.42 - float(maxi(stats.agility - 1, 0)) * 0.025)
	max_health = 70.0 + stats.strength * 12.0 + stats.willpower * 10.0
	health = minf(health if health > 0.0 else max_health, max_health)
	max_path_energy = 45.0 + stats.wisdom * 8.0
	energy_regeneration = 2.5 + stats.wisdom * 0.55
	_sync_energy_to_stats()
	health_changed.emit(health, max_health)
	energy_changed.emit(path_energy, max_path_energy, _energy_name())

func _on_stat_changed(_stat_name: String, _new_value: int) -> void:
	_sync_derived_stats()

func _on_path_selected(_path_value: PlayerStats.Path) -> void:
	_reset_energy()

func _reset_energy() -> void:
	path_energy = max_path_energy
	_sync_energy_to_stats()
	health = max_health
	health_changed.emit(health, max_health)
	energy_changed.emit(path_energy, max_path_energy, _energy_name())

func _sync_energy_to_stats() -> void:
	match stats.chosen_path:
		PlayerStats.Path.CULTIVATION:
			stats.qi = path_energy
		PlayerStats.Path.MAGIC:
			stats.mana = path_energy
		PlayerStats.Path.KNIGHTHOOD:
			stats.aura = path_energy
		PlayerStats.Path.MARTIAL_ARTS:
			stats.body_soul_will_sync = minf(path_energy, 100.0)

func _energy_name() -> String:
	match stats.chosen_path:
		PlayerStats.Path.MARTIAL_ARTS:
			return "Will Energy"
		PlayerStats.Path.CULTIVATION:
			return "Inner Qi"
		PlayerStats.Path.MAGIC:
			return "Mana"
		PlayerStats.Path.KNIGHTHOOD:
			return "Aura"
	return "Path Energy"

func _skill_energy_cost(skill_id: String) -> float:
	if skill_id in ["iron_body", "mana_bolt", "aura_slash", "qi_gathering"]:
		return 12.0
	if skill_id in ["soul_palm", "spirit_step", "second_circle", "knight_dash"]:
		return 18.0
	return 28.0

func _skill_cooldown(skill_id: String) -> float:
	if skill_id in ["iron_body", "second_circle", "arcane_shield", "golden_aura", "qi_gathering"]:
		return 8.0
	if skill_id in ["will_breaker", "immortal_sword_qi", "knight_dash"]:
		return 4.5
	return 2.0

func _emit_skill_states() -> void:
	if stats == null or stats.chosen_path == PlayerStats.Path.NONE:
		return
	var definitions := stats.get_skill_definitions()
	for index: int in range(3):
		var definition: Dictionary = definitions[index]
		var skill_id := String(definition.get("id", ""))
		var cooldown := float(skill_cooldowns.get(skill_id, 0.0))
		var ratio := clampf(cooldown / _skill_cooldown(skill_id), 0.0, 1.0)
		skill_state_changed.emit(index + 1, String(definition.get("name", "Skill")), stats.is_skill_unlocked(skill_id), ratio, path_energy >= _skill_energy_cost(skill_id))

func _damage_in_front(damage: float, distance: float) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.4, distance)
	query.shape = box
	query.transform = Transform3D(Basis.looking_at(-global_transform.basis.z, Vector3.UP), global_position - global_transform.basis.z * (distance * 0.5) + Vector3.UP)
	query.collision_mask = 4
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query):
		var body: Node = result.get("collider")
		if body != null and body.has_method("take_damage"):
			body.take_damage(damage)

func _spawn_projectile(damage: float, color: Color, projectile_speed: float, kind: String) -> void:
	var projectile: CombatProjectile = PROJECTILE_SCRIPT.new()
	get_parent().add_child(projectile)
	projectile.setup(global_position + Vector3.UP * 1.2 - global_transform.basis.z * 1.3, -global_transform.basis.z, damage, color, projectile_speed, kind)

func _spawn_shockwave(radius: float, damage: float, color: Color) -> void:
	var effect := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.45
	mesh.height = 0.9
	effect.mesh = mesh
	effect.material_override = _make_emission_material(color)
	get_parent().add_child(effect)
	effect.global_position = global_position - global_transform.basis.z * 2.0 + Vector3.UP
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", Vector3.ONE * radius, 0.28)
	tween.tween_callback(func() -> void:
		_damage_in_front(damage, radius)
		effect.queue_free()
	)

func _spawn_ring_effect(color: Color, radius: float, duration: float) -> void:
	var ring := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.08
	ring.mesh = mesh
	ring.material_override = _make_emission_material(color)
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3.UP * 0.05
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * 1.35, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(ring.queue_free)

func _spawn_shield_effect() -> void:
	var shield := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.5
	mesh.height = 3.0
	shield.mesh = mesh
	shield.material_override = _make_emission_material(Color("#93c5fd"))
	get_parent().add_child(shield)
	shield.global_position = global_position + Vector3.UP * 1.0
	var timer := get_tree().create_timer(7.0)
	timer.timeout.connect(shield.queue_free)

func _spawn_trail(from_position: Vector3, to_position: Vector3, color: Color) -> void:
	var trail := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.35, 0.35, from_position.distance_to(to_position))
	trail.mesh = mesh
	trail.material_override = _make_emission_material(color)
	get_parent().add_child(trail)
	trail.global_position = (from_position + to_position) * 0.5
	trail.look_at(to_position, Vector3.UP)
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.45)
	tween.tween_callback(trail.queue_free)

func _spawn_box_effect(effect_position: Vector3, effect_size: Vector3, color: Color, duration: float) -> void:
	var effect := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = effect_size
	effect.mesh = mesh
	effect.material_override = _make_emission_material(color)
	get_parent().add_child(effect)
	effect.global_position = effect_position
	effect.global_rotation = global_rotation
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector3(1.2, 1.2, 1.2), duration)
	tween.tween_property(effect, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(effect.queue_free)

func _apply_camera_rotation() -> void:
	if camera_rig == null:
		return
	camera_rig.rotation = Vector3(camera_pitch, camera_yaw, 0.0)

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
