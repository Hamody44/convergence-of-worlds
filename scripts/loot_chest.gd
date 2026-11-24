class_name LootChest
extends Area3D

signal player_near(chest: LootChest)
signal player_left
signal opened(item: Dictionary)

var stage := 1
var bonus_boss_chest := false
var is_opened := false
var player_inside := false
var lid: MeshInstance3D
var glow: MeshInstance3D

func setup(stage_number: int, bonus: bool = false) -> void:
	stage = maxi(stage_number, 1)
	bonus_boss_chest = bonus

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_build_chest()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_chest() -> void:
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.5, 0.8, 1.1)
	base.mesh = base_mesh
	base.position.y = 0.45
	base.material_override = _material(Color("#6b3f24"))
	add_child(base)
	lid = MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(1.58, 0.3, 1.16)
	lid.mesh = lid_mesh
	lid.position = Vector3(0.0, 0.98, 0.0)
	lid.material_override = _emission(Color("#eab308"))
	add_child(lid)
	var trim := MeshInstance3D.new()
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(0.18, 0.9, 1.22)
	trim.mesh = trim_mesh
	trim.position = Vector3(0.0, 0.5, 0.0)
	trim.material_override = _emission(Color("#facc15"))
	add_child(trim)
	glow = MeshInstance3D.new()
	var aura := SphereMesh.new()
	aura.radius = 0.9
	aura.height = 1.8
	glow.mesh = aura
	glow.material_override = _emission(Color("#fde68a"))
	glow.scale = Vector3(1.4, 0.6, 1.0)
	glow.position.y = 0.8
	add_child(glow)
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.5
	shape_node.shape = shape
	shape_node.position.y = 0.8
	add_child(shape_node)
	var label := Label3D.new()
	label.text = "BONUS CHEST" if bonus_boss_chest else "LOOT CHEST"
	label.position = Vector3(0.0, 2.0, 0.0)
	label.font_size = 20
	label.outline_size = 5
	label.modulate = Color("#fef08a")
	add_child(label)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_opened:
		player_inside = true
		player_near.emit(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_left.emit()

func _unhandled_input(event: InputEvent) -> void:
	if player_inside and not is_opened and (event.is_action_pressed("use_portal") or event.is_action_pressed("open_chest")):
		open_chest()

func open_chest() -> void:
	if is_opened or not player_inside: return
	is_opened = true
	var path: PlayerStats.Path = get_tree().get_first_node_in_group("player").stats.chosen_path
	var rarity := 2 if bonus_boss_chest else (stage - 1) % 3
	var slot := "Weapon" if (Time.get_ticks_msec() + stage) % 2 == 0 else "Armor"
	var item := EquipmentData.make_item(path, slot, stage, rarity)
	var tween := create_tween()
	tween.tween_property(lid, "rotation:x", -1.15, 0.45)
	tween.parallel().tween_property(glow, "scale", Vector3.ONE * 2.0, 0.45)
	opened.emit(item)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	return material

func _emission(color: Color) -> StandardMaterial3D:
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	return material
