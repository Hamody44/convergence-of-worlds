class_name AreaBoss
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal detection_started
signal defeated

const PROJECTILE_SCRIPT := preload("res://scripts/combat_projectile.gd")

var stage: int = 1
var maximum_health: float = 900.0
var health: float = 900.0
var attack_timer := 1.8
var warning_timer := 0.0
var warning_kind := ""
var is_active := false
var is_defeated := false
var visual_root: Node3D
var body_visual: MeshInstance3D
var detection_zone: Area3D
var warning_ring: MeshInstance3D

func setup(stage_number: int) -> void:
	stage = maxi(stage_number, 1)
	maximum_health = (850.0 + float(stage) * 420.0) * (1.0 + float(stage - 1) * 0.18)
	health = maximum_health

func _ready() -> void:
	add_to_group("area_boss")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.3
	_build_boss_nodes()
	_build_detection_zone()
	health_changed.emit(health, maximum_health)

func _build_boss_nodes() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 1.15
	shape.height = 4.8
	collision.shape = shape
	collision.position.y = 2.4
	add_child(collision)
	visual_root = Node3D.new()
	visual_root.name = "ObsidianArmor"
	add_child(visual_root)
	body_visual = _mesh(CapsuleMesh.new(), Vector3(0.0, 2.35, 0.0), Vector3.ONE, Color("#171521"), true)
	(body_visual.mesh as CapsuleMesh).radius = 1.12
	(body_visual.mesh as CapsuleMesh).height = 4.7
	visual_root.add_child(body_visual)
	var chest := _mesh(BoxMesh.new(), Vector3(0.0, 2.55, -0.55), Vector3(2.5, 1.65, 0.7), Color("#351522"), true)
	visual_root.add_child(chest)
	for side in [-1.0, 1.0]:
		var shoulder := _mesh(CapsuleMesh.new(), Vector3(side * 1.42, 3.25, 0.0), Vector3.ONE, Color("#241827"), true)
		(shoulder.mesh as CapsuleMesh).radius = 0.45
		(shoulder.mesh as CapsuleMesh).height = 1.55
		shoulder.rotation.z = side * 0.32
		visual_root.add_child(shoulder)
		var spike_mesh := CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.5
		spike_mesh.height = 1.45
		var spike := _mesh(spike_mesh, Vector3(side * 1.75, 3.45, -0.1), Vector3(0.55, 1.0, 0.55), Color("#a52c3c"), true)
		spike.rotation.z = side * 0.8
		visual_root.add_child(spike)
	var head := _mesh(SphereMesh.new(), Vector3(0.0, 5.05, 0.0), Vector3.ONE, Color("#0e0b16"), true)
	(head.mesh as SphereMesh).radius = 0.8
	(head.mesh as SphereMesh).height = 1.6
	visual_root.add_child(head)
	for side in [-1.0, 1.0]:
		var eye := _mesh(SphereMesh.new(), Vector3(side * 0.3, 5.08, -0.7), Vector3.ONE, Color("#ef3340"), true)
		(eye.mesh as SphereMesh).radius = 0.13
		(eye.mesh as SphereMesh).height = 0.26
		visual_root.add_child(eye)
	var label := Label3D.new()
	label.text = "ABYSSAL DEVOURER  |  وحش الهاوية"
	label.position = Vector3(0.0, 6.3, 0.0)
	label.font_size = 28
	label.outline_size = 8
	label.modulate = Color("#fecaca")
	add_child(label)

func _build_detection_zone() -> void:
	detection_zone = Area3D.new()
	detection_zone.name = "BossDetectionZone"
	detection_zone.collision_layer = 0
	detection_zone.collision_mask = 2
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 11.0
	shape_node.shape = sphere
	detection_zone.add_child(shape_node)
	add_child(detection_zone)
	detection_zone.body_entered.connect(_on_detection_body_entered)

func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_active and not is_defeated:
		is_active = true
		detection_started.emit()

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	var player := _get_player()
	if player == null or not is_active:
		return
	if warning_timer > 0.0:
		warning_timer -= delta
		if warning_timer <= 0.0:
			_execute_warning(player)
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	var distance := global_position.distance_to(player.global_position)
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		look_at(global_position + direction.normalized(), Vector3.UP)
	if distance > 3.0:
		velocity.x = move_toward(velocity.x, direction.normalized().x * 2.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, direction.normalized().z * 2.0, 8.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
	if not is_on_floor(): velocity.y -= get_gravity().length() * delta
	else: velocity.y = 0.0
	move_and_slide()
	if attack_timer <= 0.0:
		_choose_attack(player, distance)

func _choose_attack(player: ActionRPGPlayer, distance: float) -> void:
	if distance > 7.0:
		_begin_warning("orb", 0.55)
	elif fmod(Time.get_ticks_msec() / 1000.0 + float(stage), 3.0) < 1.0:
		_begin_warning("shockwave", 1.2)
	else:
		_begin_warning("slam", 0.72)
	attack_timer = maxf(1.45 - float(stage) * 0.035, 0.65)

func _begin_warning(kind: String, duration: float) -> void:
	warning_kind = kind
	warning_timer = duration
	if kind == "slam":
		body_visual.material_override = _emission(Color("#d71939"))
	elif kind == "shockwave":
		warning_ring = _mesh(TorusMesh.new(), Vector3(0.0, 0.08, 0.0), Vector3.ONE, Color("#ef233c"), true)
		(warning_ring.mesh as TorusMesh).inner_radius = 0.6
		(warning_ring.mesh as TorusMesh).outer_radius = 1.1
		add_child(warning_ring)
		var tween := warning_ring.create_tween()
		tween.tween_property(warning_ring, "scale", Vector3.ONE * 3.2, duration)

func _execute_warning(player: ActionRPGPlayer) -> void:
	if warning_kind == "slam":
		if global_position.distance_to(player.global_position) < 3.8:
			player.take_damage(28.0 + float(stage) * 8.0)
		_spawn_burst(Color("#ef3340"), 1.5)
	elif warning_kind == "shockwave":
		var ring := _mesh(TorusMesh.new(), Vector3(0.0, 0.1, 0.0), Vector3.ONE, Color("#dc143c"), true)
		(ring.mesh as TorusMesh).inner_radius = 0.2
		(ring.mesh as TorusMesh).outer_radius = 0.8
		add_child(ring)
		var tween := ring.create_tween()
		tween.tween_property(ring, "scale", Vector3.ONE * 5.0, 0.35)
		tween.tween_callback(func() -> void:
			if is_instance_valid(ring): ring.queue_free()
		)
		if player.is_on_floor() and global_position.distance_to(player.global_position) < 7.0:
			player.take_damage(34.0 + float(stage) * 10.0)
	elif warning_kind == "orb":
		var direction := (player.global_position + Vector3.UP * 1.0 - global_position).normalized()
		var projectile: CombatProjectile = PROJECTILE_SCRIPT.new()
		get_parent().add_child(projectile)
		projectile.setup(global_position + Vector3.UP * 3.0 + direction * 1.5, direction, 24.0 + float(stage) * 8.0, Color("#7e22ce"), 5.0, "sphere")
	body_visual.material_override = _make_material(Color("#171521"), 0.9)
	warning_kind = ""

func take_damage(amount: float) -> void:
	if is_defeated: return
	health = maxf(health - maxf(amount, 0.0), 0.0)
	if not is_active: is_active = true
	health_changed.emit(health, maximum_health)
	_spawn_burst(Color("#fbbf24"), 0.45)
	if health <= 0.0: _defeat()

func _defeat() -> void:
	is_defeated = true
	is_active = false
	velocity = Vector3.ZERO
	var player := _get_player()
	if player != null and player.stats != null:
		player.stats.add_experience(900 + stage * 350)
		player.stats.soul_points += 5
		player.stats.soul_points_changed.emit(player.stats.soul_points)
		player.stats.advance_path_progress(50.0)
		player.stats.save_to_disk()
	_spawn_burst(Color("#f43f5e"), 3.8)
	defeated.emit()
	queue_free()

func _spawn_burst(color: Color, scale_value: float) -> void:
	var burst := _mesh(SphereMesh.new(), global_position + Vector3.UP * 2.0, Vector3.ONE * 0.35, color, true)
	(burst.mesh as SphereMesh).radius = 0.5
	(burst.mesh as SphereMesh).height = 1.0
	get_parent().add_child(burst)
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector3.ONE * scale_value, 0.65)
	tween.tween_property(burst, "modulate", Color(1, 1, 1, 0), 0.65)
	tween.chain().tween_callback(burst.queue_free)

func _get_player() -> ActionRPGPlayer:
	var node := get_tree().get_first_node_in_group("player")
	return node as ActionRPGPlayer

func _mesh(mesh: Mesh, at: Vector3, mesh_scale: Vector3, color: Color, emission: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = mesh_scale
	instance.material_override = _emission(color) if emission else _make_material(color, 0.8)
	return instance

func _make_material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.5
	return material

func _emission(color: Color) -> StandardMaterial3D:
	var material := _make_material(color, 0.25)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.5
	return material
