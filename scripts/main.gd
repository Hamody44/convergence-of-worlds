extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const STATS_SCRIPT := preload("res://scripts/player_stats.gd")
const TOUCH_UI_SCRIPT := preload("res://ui/touch_ui.gd")

var player: ActionRPGPlayer

func _ready() -> void:
	_build_world()
	_build_player()
	_build_touch_ui()

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color("#0b1730")
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("#9bb9e8")
	environment_resource.ambient_light_energy = 0.65
	environment.environment = environment_resource
	add_child(environment)
	
	var sun := DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_color = Color("#fff1cf")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	
	_make_box("ArenaGround", Vector3(0.0, -0.3, 0.0), Vector3(36.0, 0.6, 36.0), Color("#26384a"))
	_make_box("NorthWall", Vector3(0.0, 1.5, -17.5), Vector3(36.0, 3.0, 1.0), Color("#334155"))
	_make_box("SouthWall", Vector3(0.0, 1.5, 17.5), Vector3(36.0, 3.0, 1.0), Color("#334155"))
	_make_box("EastWall", Vector3(17.5, 1.5, 0.0), Vector3(1.0, 3.0, 36.0), Color("#334155"))
	_make_box("WestWall", Vector3(-17.5, 1.5, 0.0), Vector3(1.0, 3.0, 36.0), Color("#334155"))
	_make_box("ObstacleA", Vector3(-5.0, 1.0, -3.5), Vector3(3.0, 2.0, 3.0), Color("#7c3aed"))
	_make_box("ObstacleB", Vector3(5.0, 0.75, -1.0), Vector3(2.0, 1.5, 4.0), Color("#0e7490"))
	_make_box("ObstacleC", Vector3(0.0, 0.6, 7.0), Vector3(5.0, 1.2, 2.0), Color("#b45309"))
	
	var label := Label3D.new()
	label.text = "ASCENSION — PHASE 1"
	label.position = Vector3(0.0, 4.0, -10.0)
	label.font_size = 48
	label.modulate = Color("#f8fafc")
	label.outline_size = 10
	add_child(label)

func _build_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.stats = STATS_SCRIPT.new()
	player.position = Vector3(0.0, 0.2, 6.0)
	add_child(player)

func _build_touch_ui() -> void:
	var touch_ui: TouchUI = TOUCH_UI_SCRIPT.new()
	touch_ui.name = "TouchUI"
	add_child(touch_ui)
	touch_ui.movement_changed.connect(_on_touch_movement_changed)
	touch_ui.jump_pressed.connect(_on_touch_jump_pressed)
	touch_ui.attack_pressed.connect(_on_touch_attack_pressed)
	touch_ui.camera_dragged.connect(_on_camera_dragged)

func _on_touch_movement_changed(value: Vector2) -> void:
	if is_instance_valid(player):
		player.touch_move = value

func _on_touch_jump_pressed() -> void:
	if is_instance_valid(player) and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY

func _on_touch_attack_pressed() -> void:
	if is_instance_valid(player):
		player.basic_attack()

func _on_camera_dragged(delta_pixels: Vector2) -> void:
	if is_instance_valid(player):
		player.rotate_camera_by(delta_pixels)

func _make_box(node_name: String, box_position: Vector3, box_size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color)
	body.add_child(mesh_instance)
	
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	return body

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
