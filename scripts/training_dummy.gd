class_name TrainingDummy
extends StaticBody3D

@export var maximum_health: float = 120.0
var health: float
var health_label: Label3D
var status_label: Label3D
var body_visual: MeshInstance3D
var respawn_timer: float = 0.0
var is_defeated: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	health = maximum_health
	_build_dummy()
	_update_health_display()

func _process(delta: float) -> void:
	if is_defeated:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()

func _build_dummy() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	add_child(collision)
	
	body_visual = MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.55
	body_mesh.height = 2.7
	body_visual.mesh = body_mesh
	body_visual.position.y = 1.35
	body_visual.material_override = _make_material(Color("#b45309"))
	add_child(body_visual)
	
	var target := MeshInstance3D.new()
	var target_mesh := SphereMesh.new()
	target_mesh.radius = 0.78
	target_mesh.height = 1.56
	target.mesh = target_mesh
	target.position = Vector3(0.0, 2.55, 0.0)
	target.material_override = _make_emission_material(Color("#ef4444"))
	add_child(target)
	
	var name_label := Label3D.new()
	name_label.text = "TRAINING DUMMY"
	name_label.position = Vector3(0.0, 3.65, 0.0)
	name_label.font_size = 28
	name_label.outline_size = 8
	add_child(name_label)
	
	health_label = Label3D.new()
	health_label.position = Vector3(0.0, 3.25, 0.0)
	health_label.font_size = 26
	health_label.modulate = Color("#86efac")
	health_label.outline_size = 6
	add_child(health_label)

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
	respawn_timer = 3.0
	body_visual.visible = false
	status_label = Label3D.new()
	status_label.text = "RESPAWNING..."
	status_label.position = Vector3(0.0, 2.0, 0.0)
	status_label.font_size = 30
	status_label.modulate = Color("#facc15")
	add_child(status_label)

func _respawn() -> void:
	is_defeated = false
	health = maximum_health
	body_visual.visible = true
	if is_instance_valid(status_label):
		status_label.queue_free()
	_update_health_display()

func _update_health_display() -> void:
	if is_instance_valid(health_label):
		health_label.text = "HP: %d / %d" % [roundi(health), roundi(maximum_health)]

func _show_damage_number(amount: float) -> void:
	var damage_label := Label3D.new()
	damage_label.text = "-%d" % roundi(amount)
	damage_label.position = Vector3(0.0, 2.8, 0.0)
	damage_label.font_size = 34
	damage_label.modulate = Color("#fca5a5")
	damage_label.outline_size = 7
	add_child(damage_label)
	var tween := damage_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position", Vector3(0.0, 4.0, 0.0), 0.7)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(damage_label.queue_free)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material

func _make_emission_material(color: Color) -> StandardMaterial3D:
	var material := _make_material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.5
	return material
