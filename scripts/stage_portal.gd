class_name StagePortal
extends Area3D

signal player_near(portal: StagePortal)
signal player_left
signal activated

var is_available := false
var player_inside := false
var ring: MeshInstance3D
var disc: MeshInstance3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_build_portal()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_portal() -> void:
	ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.8
	torus.outer_radius = 2.05
	ring.mesh = torus
	ring.material_override = _emission(Color("#22d3ee"))
	add_child(ring)
	disc = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.8
	cylinder.bottom_radius = 1.8
	cylinder.height = 0.08
	disc.mesh = cylinder
	disc.material_override = _portal_material()
	disc.rotation_degrees.x = 90.0
	add_child(disc)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.5
	shape.height = 3.0
	collision.shape = shape
	collision.position.y = 1.5
	add_child(collision)
	var label := Label3D.new()
	label.text = "STAGE PORTAL  |  بوابة المرحلة"
	label.position = Vector3(0.0, 3.6, 0.0)
	label.font_size = 22
	label.outline_size = 6
	label.modulate = Color("#a5f3fc")
	add_child(label)
	var tween := create_tween().set_loops()
	tween.tween_property(ring, "rotation:y", TAU, 5.0)

func set_available(value: bool) -> void:
	is_available = value
	visible = value
	monitoring = value
	if not value:
		player_inside = false

func _on_body_entered(body: Node3D) -> void:
	if is_available and body.is_in_group("player"):
		player_inside = true
		player_near.emit(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_left.emit()

func _unhandled_input(event: InputEvent) -> void:
	if is_available and player_inside and event.is_action_pressed("use_portal"):
		activated.emit()

func activate_from_touch() -> void:
	if is_available and player_inside:
		activated.emit()

func _portal_material() -> StandardMaterial3D:
	var material := _emission(Color("#fbbf24"))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.32
	return material

func _emission(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 4.0
	return material
