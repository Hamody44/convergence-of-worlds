extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const STATS_SCRIPT := preload("res://scripts/player_stats.gd")
const DUMMY_SCRIPT := preload("res://scripts/training_dummy.gd")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss.tscn")
const PORTAL_SCENE := preload("res://scenes/stage_portal.tscn")
const TOUCH_UI_SCRIPT := preload("res://ui/touch_ui.gd")
const PROGRESSION_UI_SCRIPT := preload("res://ui/progression_ui.gd")
const COMBAT_UI_SCRIPT := preload("res://ui/combat_ui.gd")
const SOUND_MANAGER_SCRIPT := preload("res://scripts/sound_manager.gd")
const CHEST_SCENE := preload("res://scenes/loot_chest.tscn")

var player: ActionRPGPlayer
var progression_ui: ProgressionUI
var combat_ui: CombatUI
var boss: AreaBoss
var portal: StagePortal
var environment_resource: Environment
var sun: DirectionalLight3D
var stage: int = 1
var active_chest: LootChest

func _ready() -> void:
	_build_world()
	_build_sound_manager()
	_build_player()
	stage = player.stats.current_stage
	_build_training_dummies()
	_build_enemies()
	_build_boss()
	_build_portal()
	_build_chests()
	_build_touch_ui()
	_build_progression_ui()
	_build_combat_ui()
	_apply_stage_atmosphere()
	if player.stats.chosen_path == PlayerStats.Path.NONE:
		get_tree().paused = true

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment_resource = Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_energy = 0.65
	environment.environment = environment_resource
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
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
	label.text = "ASCENSION — PHASE 6"
	label.position = Vector3(0.0, 4.0, -10.0)
	label.font_size = 48
	label.modulate = Color("#f8fafc")
	label.outline_size = 10
	add_child(label)

func _build_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.stats = STATS_SCRIPT.new()
	player.stats.load_from_disk()
	player.stats.path_selected.connect(_on_path_selected)
	player.position = Vector3(0.0, 0.2, 6.0)
	player.arena_spawn_position = player.position
	add_child(player)

func _build_sound_manager() -> void:
	var manager: SoundManager = SOUND_MANAGER_SCRIPT.new()
	manager.name = "SoundManager"
	manager.add_to_group("sound_manager")
	add_child(manager)

func _build_training_dummies() -> void:
	for data in [["TrainingDummyA", Vector3(-4.0, 0.0, -5.0)], ["TrainingDummyB", Vector3(4.0, 0.0, -5.0)]]:
		var dummy: TrainingDummy = DUMMY_SCRIPT.new()
		dummy.name = data[0]
		dummy.position = data[1]
		add_child(dummy)

func _build_enemies() -> void:
	var spawn_positions := [Vector3(-10.0, 0.2, -7.0), Vector3(10.0, 0.2, -7.0), Vector3(-9.0, 0.2, 7.0), Vector3(9.0, 0.2, 7.0)]
	for index: int in range(spawn_positions.size()):
		var enemy := ENEMY_SCENE.instantiate() as ActionRPGEnemy
		enemy.name = "VoidHunter%d" % (index + 1)
		enemy.maximum_health *= 1.0 + float(stage - 1) * 0.3
		enemy.attack_damage *= 1.0 + float(stage - 1) * 0.22
		enemy.experience_reward += (stage - 1) * 18
		enemy.position = spawn_positions[index]
		enemy.add_to_group("regular_enemy")
		add_child(enemy)

func _build_boss() -> void:
	boss = BOSS_SCENE.instantiate() as AreaBoss
	boss.name = "AreaBossStage%d" % stage
	boss.setup(stage)
	boss.position = Vector3(0.0, 0.0, -13.0)
	add_child(boss)
	boss.detection_started.connect(_on_boss_detection_started)
	boss.health_changed.connect(_on_boss_health_changed)
	boss.defeated.connect(_on_boss_defeated)

func _build_portal() -> void:
	portal = PORTAL_SCENE.instantiate() as StagePortal
	portal.name = "StageTransitionPortal"
	portal.position = Vector3(0.0, 0.0, -13.0)
	portal.set_available(false)
	add_child(portal)
	portal.player_near.connect(_on_portal_near)
	portal.player_left.connect(_on_portal_left)
	portal.activated.connect(_on_portal_activated)

func _build_chests() -> void:
	var positions := [Vector3(-12.0, 0.0, 2.0), Vector3(12.0, 0.0, 2.0), Vector3(0.0, 0.0, 10.0)]
	for index in range(positions.size()):
		var chest := CHEST_SCENE.instantiate() as LootChest
		chest.name = "LootChest%d" % (index + 1)
		chest.setup(stage, false)
		chest.position = positions[index]
		add_child(chest)
		chest.add_to_group("loot_chest")
		chest.player_near.connect(_on_chest_near)
		chest.player_left.connect(_on_chest_left)
		chest.opened.connect(_on_chest_opened)

func _build_touch_ui() -> void:
	var touch_ui: TouchUI = TOUCH_UI_SCRIPT.new()
	touch_ui.name = "TouchUI"
	add_child(touch_ui)
	touch_ui.movement_changed.connect(_on_touch_movement_changed)
	touch_ui.jump_pressed.connect(_on_touch_jump_pressed)
	touch_ui.attack_pressed.connect(_on_touch_attack_pressed)
	touch_ui.camera_dragged.connect(_on_camera_dragged)

func _build_progression_ui() -> void:
	progression_ui = PROGRESSION_UI_SCRIPT.new()
	progression_ui.name = "ProgressionUI"
	progression_ui.player = player
	add_child(progression_ui)

func _build_combat_ui() -> void:
	combat_ui = COMBAT_UI_SCRIPT.new()
	combat_ui.name = "CombatUI"
	combat_ui.player = player
	add_child(combat_ui)
	combat_ui.language_changed.connect(_on_language_changed)
	combat_ui.portal_activate_requested.connect(_on_portal_activated)
	combat_ui.chest_open_requested.connect(_on_chest_open_requested)

func _on_chest_open_requested() -> void:
	if is_instance_valid(active_chest): active_chest.open_chest()

func _on_boss_detection_started() -> void:
	combat_ui.show_boss_bar(_boss_title(), boss.health, boss.maximum_health)

func _on_boss_health_changed(current: float, maximum: float) -> void:
	if is_instance_valid(combat_ui) and boss.is_active:
		combat_ui.show_boss_bar(_boss_title(), current, maximum)

func _on_boss_defeated() -> void:
	combat_ui.hide_boss_bar()
	portal.set_available(true)
	combat_ui.show_portal_prompt(false)
	var chest := CHEST_SCENE.instantiate() as LootChest
	chest.name = "BonusBossChest"
	chest.setup(stage, true)
	chest.position = Vector3(3.0, 0.0, -13.0)
	add_child(chest)
	chest.add_to_group("loot_chest")
	chest.player_near.connect(_on_chest_near)
	chest.player_left.connect(_on_chest_left)
	chest.opened.connect(_on_chest_opened)

func _on_portal_near(_portal: StagePortal) -> void:
	combat_ui.show_portal_prompt(true)

func _on_portal_left() -> void:
	combat_ui.show_portal_prompt(false)

func _on_chest_near(chest: LootChest) -> void:
	active_chest = chest
	combat_ui.show_chest_prompt(true)

func _on_chest_left() -> void:
	active_chest = null
	combat_ui.show_chest_prompt(false)

func _on_chest_opened(item: Dictionary) -> void:
	player.stats.add_gear(item)
	combat_ui.show_chest_prompt(false)
	combat_ui.show_loot_message(item)
	var manager := get_tree().get_first_node_in_group("sound_manager")
	if manager != null: manager.play_chest_open()

func _on_portal_activated() -> void:
	if not portal.is_available or not portal.player_inside: return
	combat_ui.show_portal_prompt(false)
	combat_ui.fade_transition()
	stage += 1
	player.stats.set_stage(stage)
	player.global_position = Vector3(0.0, 0.2, 6.0)
	player.arena_spawn_position = player.global_position
	_apply_stage_atmosphere()
	portal.set_available(false)
	for chest in get_tree().get_nodes_in_group("loot_chest"):
		if is_instance_valid(chest): chest.queue_free()
	for enemy in get_tree().get_nodes_in_group("regular_enemy"):
		if is_instance_valid(enemy): enemy.queue_free()
	if is_instance_valid(boss): boss.queue_free()
	await get_tree().create_timer(0.55).timeout
	_build_enemies()
	_build_boss()
	_build_chests()
	combat_ui.set_stage(stage)

func _apply_stage_atmosphere() -> void:
	var backgrounds := [Color("#0b1730"), Color("#320d18"), Color("#120b38")]
	var ambients := [Color("#9bb9e8"), Color("#e87979"), Color("#b5a5ff")]
	var grounds := [Color("#26384a"), Color("#4b1d2a"), Color("#272052")]
	var index := mini(stage - 1, backgrounds.size() - 1)
	environment_resource.background_color = backgrounds[index]
	environment_resource.ambient_light_color = ambients[index]
	sun.light_color = ambients[index].lightened(0.35)
	var ground := get_node_or_null("ArenaGround/MeshInstance3D")
	if ground is MeshInstance3D:
		ground.material_override = _make_material(grounds[index])
	if is_instance_valid(combat_ui): combat_ui.set_stage(stage)

func _boss_title() -> String:
	return "ABYSSAL DEVOURER — وحش الهاوية"

func _on_language_changed(arabic: bool) -> void:
	if is_instance_valid(progression_ui): progression_ui.set_language(arabic)

func _on_path_selected(_path_value: PlayerStats.Path) -> void:
	get_tree().paused = false

func _on_touch_movement_changed(value: Vector2) -> void:
	if is_instance_valid(player): player.touch_move = value

func _on_touch_jump_pressed() -> void:
	if is_instance_valid(player) and player.is_on_floor(): player.velocity.y = player.current_jump_velocity

func _on_touch_attack_pressed() -> void:
	if is_instance_valid(player): player.basic_attack()

func _on_camera_dragged(delta_pixels: Vector2) -> void:
	if is_instance_valid(player): player.rotate_camera_by(delta_pixels)

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
