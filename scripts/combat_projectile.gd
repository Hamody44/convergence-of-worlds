class_name CombatProjectile
extends Area3D

var direction: Vector3 = Vector3.FORWARD
var speed: float = 16.0
var damage: float = 10.0
var lifetime: float = 3.0
var tint: Color = Color.WHITE
var mesh_kind: String = "sphere"

func setup(start_position: Vector3, travel_direction: Vector3, projectile_damage: float, projectile_color: Color, projectile_speed: float = 16.0, shape_kind: String = "sphere") -> void:
	global_position = start_position
	direction = travel_direction.normalized()
	damage = projectile_damage
	tint = projectile_color
	speed = projectile_speed
	mesh_kind = shape_kind
	_build_visual()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	monitoring = true

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	look_at(global_position + direction, Vector3.UP)

func _build_visual() -> void:
	var visual := MeshInstance3D.new()
	if mesh_kind == "blade":
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.18, 0.18, 1.8)
		visual.mesh = blade_mesh
	else:
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = 0.28
		sphere_mesh.height = 0.56
		visual.mesh = sphere_mesh
	visual.material_override = _make_emission_material(tint)
	add_child(visual)
	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.32
	collision.shape = sphere_shape
	add_child(collision)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_spawn_hit_flash()
		queue_free()

func _on_area_entered(_area: Area3D) -> void:
	# Reserved for future enemy Area3D targets.
	pass

func _spawn_hit_flash() -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.45
	mesh.height = 0.9
	flash.mesh = mesh
	flash.material_override = _make_emission_material(tint)
	get_parent().add_child(flash)
	flash.global_position = global_position
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 2.0, 0.12)
	tween.tween_callback(flash.queue_free)

func _make_emission_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	material.roughness = 0.3
	return material
