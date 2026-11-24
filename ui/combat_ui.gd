class_name CombatUI
extends CanvasLayer

signal language_changed(arabic: bool)

var player: ActionRPGPlayer
var ui_root: Control
var health_bar: ProgressBar
var energy_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var hp_label: Label
var energy_name_label: Label
var path_label: Label
var skill_buttons: Dictionary = {}
var skill_state: Dictionary = {}
var level_up_banner: Label
var respawn_overlay: PanelContainer
var language_button: Button
var respawn_title: Label
var respawn_subtitle: Label
var respawn_button: Button
var is_arabic: bool = false

func _ready() -> void:
	layer = 10
	_build_hud()
	player.health_changed.connect(_on_health_changed)
	player.energy_changed.connect(_on_energy_changed)
	player.skill_state_changed.connect(_on_skill_state_changed)
	player.defeated.connect(_on_player_defeated)
	player.respawned.connect(_on_player_respawned)
	player.level_up.connect(_on_player_level_up)
	player.breakthrough_completed.connect(_on_breakthrough_completed)
	player.stats.path_selected.connect(_on_path_selected)
	player.stats.experience_changed.connect(_on_experience_changed)
	_on_health_changed(player.health, player.max_health)
	_on_energy_changed(player.path_energy, player.max_path_energy, player._energy_name())
	_on_experience_changed(player.stats.experience, player.stats.experience_to_next_level)
	level_label.text = "LEVEL %d" % player.stats.level
	for slot: int in range(1, 4):
		_add_skill_button(slot)
	_update_path_visibility(player.stats.chosen_path != PlayerStats.Path.NONE)

func _build_hud() -> void:
	ui_root = Control.new()
	ui_root.name = "CombatHUDRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_root.theme = _make_theme()
	add_child(ui_root)

	language_button = Button.new()
	language_button.name = "LanguageToggle"
	language_button.text = "عربي / EN"
	language_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	language_button.position = Vector2(-390.0, 24.0)
	language_button.size = Vector2(145.0, 64.0)
	language_button.custom_minimum_size = Vector2(145.0, 64.0)
	language_button.add_theme_font_size_override("font_size", 19)
	language_button.focus_mode = Control.FOCUS_NONE
	language_button.pressed.connect(_on_language_pressed)
	ui_root.add_child(language_button)

	var panel := PanelContainer.new()
	panel.position = Vector2(24.0, 70.0)
	panel.size = Vector2(350.0, 224.0)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.08, 0.14, 0.9), Color("#45658f")))
	ui_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	margin.add_child(bars)
	path_label = Label.new()
	path_label.text = "PATH"
	path_label.add_theme_font_size_override("font_size", 18)
	bars.add_child(path_label)
	hp_label = Label.new()
	hp_label.text = "HEALTH"
	hp_label.add_theme_font_size_override("font_size", 15)
	bars.add_child(hp_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(0.0, 28.0)
	health_bar.show_percentage = true
	health_bar.add_theme_font_size_override("font_size", 16)
	bars.add_child(health_bar)
	energy_name_label = Label.new()
	energy_name_label.text = "PATH ENERGY"
	energy_name_label.add_theme_font_size_override("font_size", 15)
	bars.add_child(energy_name_label)
	energy_bar = ProgressBar.new()
	energy_bar.custom_minimum_size = Vector2(0.0, 28.0)
	energy_bar.show_percentage = true
	energy_bar.add_theme_font_size_override("font_size", 16)
	bars.add_child(energy_bar)
	level_label = Label.new()
	level_label.text = "LEVEL 1"
	level_label.add_theme_font_size_override("font_size", 15)
	bars.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0.0, 24.0)
	xp_bar.show_percentage = true
	xp_bar.add_theme_font_size_override("font_size", 14)
	bars.add_child(xp_bar)

	level_up_banner = Label.new()
	level_up_banner.text = "LEVEL UP!"
	level_up_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_up_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_up_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	level_up_banner.position = Vector2(-180.0, 30.0)
	level_up_banner.size = Vector2(360.0, 80.0)
	level_up_banner.add_theme_color_override("font_color", Color("#fde68a"))
	level_up_banner.add_theme_font_size_override("font_size", 38)
	level_up_banner.visible = false
	ui_root.add_child(level_up_banner)
	_build_respawn_overlay()

func _build_respawn_overlay() -> void:
	respawn_overlay = PanelContainer.new()
	respawn_overlay.name = "RespawnOverlay"
	respawn_overlay.set_anchors_preset(Control.PRESET_CENTER)
	respawn_overlay.position = Vector2(-230.0, -150.0)
	respawn_overlay.size = Vector2(460.0, 300.0)
	respawn_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	respawn_overlay.add_theme_stylebox_override("panel", _make_style(Color(0.05, 0.02, 0.04, 0.96), Color("#ef4444")))
	respawn_overlay.visible = false
	ui_root.add_child(respawn_overlay)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	respawn_overlay.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	respawn_title = Label.new()
	respawn_title.text = "YOU FELL"
	respawn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	respawn_title.add_theme_color_override("font_color", Color("#fecaca"))
	respawn_title.add_theme_font_size_override("font_size", 32)
	content.add_child(respawn_title)
	respawn_subtitle = Label.new()
	respawn_subtitle.text = "Your journey is not over."
	respawn_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	respawn_subtitle.add_theme_font_size_override("font_size", 18)
	content.add_child(respawn_subtitle)
	respawn_button = Button.new()
	respawn_button.text = "RESPAWN"
	respawn_button.custom_minimum_size = Vector2(0.0, 78.0)
	respawn_button.add_theme_font_size_override("font_size", 25)
	respawn_button.focus_mode = Control.FOCUS_NONE
	respawn_button.pressed.connect(_on_respawn_pressed)
	content.add_child(respawn_button)

func _add_skill_button(slot: int) -> void:
	var button := Button.new()
	button.name = "SkillButton%d" % slot
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = Vector2(-470.0 + float(slot - 1) * 125.0, -180.0)
	button.size = Vector2(115.0, 92.0)
	button.custom_minimum_size = Vector2(115.0, 92.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(func() -> void: player.use_skill(slot))
	ui_root.add_child(button)
	skill_buttons[slot] = button
	_refresh_skill_button(slot)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar == null:
		return
	health_bar.max_value = maximum
	health_bar.value = current

func _on_energy_changed(current: float, maximum: float, energy_name: String) -> void:
	if energy_bar == null:
		return
	energy_bar.max_value = maximum
	energy_bar.value = current
	var localized_name := energy_name.to_upper()
	if is_arabic:
		var names := {"WILL ENERGY": "طاقة الإرادة", "INNER QI": "الـ Qi الداخلي", "MANA": "الـ Mana", "AURA": "الـ Aura", "PATH ENERGY": "طاقة المسار"}
		localized_name = String(names.get(localized_name, localized_name))
	energy_name_label.text = "%s  %.0f / %.0f" % [localized_name, current, maximum]

func _on_experience_changed(current: int, maximum: int) -> void:
	if xp_bar == null:
		return
	xp_bar.max_value = maximum
	xp_bar.value = current
	level_label.text = _tr("LEVEL %d  |  XP %d / %d" % [player.stats.level, current, maximum], "المستوى %d  |  XP %d / %d" % [player.stats.level, current, maximum])

func _on_player_level_up(new_level: int) -> void:
	level_label.text = _tr("LEVEL %d  |  XP %d / %d" % [new_level, player.stats.experience, player.stats.experience_to_next_level], "المستوى %d  |  XP %d / %d" % [new_level, player.stats.experience, player.stats.experience_to_next_level])
	level_up_banner.text = _tr("LEVEL %d UP!" % new_level, "ارتفع المستوى إلى %d!" % new_level)
	level_up_banner.visible = true
	var tween := level_up_banner.create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(level_up_banner, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.45)
	tween.tween_callback(func() -> void:
		if is_instance_valid(level_up_banner):
			level_up_banner.visible = false
			level_up_banner.modulate = Color.WHITE
	)

func _on_breakthrough_completed(new_rank: int) -> void:
	level_up_banner.text = _tr("BREAKTHROUGH! Rank %d" % new_rank, "اختراق! الرتبة %d" % new_rank)
	level_up_banner.visible = true
	var tween := level_up_banner.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(level_up_banner, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
	tween.tween_callback(func() -> void:
		if is_instance_valid(level_up_banner):
			level_up_banner.visible = false
			level_up_banner.modulate = Color.WHITE
	)

func _on_player_defeated() -> void:
	respawn_overlay.visible = true

func _on_player_respawned() -> void:
	respawn_overlay.visible = false

func _on_respawn_pressed() -> void:
	player.respawn_at(player.arena_spawn_position)

func _on_language_pressed() -> void:
	set_language(not is_arabic)
	language_changed.emit(is_arabic)

func set_language(arabic: bool) -> void:
	is_arabic = arabic
	language_button.text = "EN / عربي" if is_arabic else "عربي / EN"
	hp_label.text = "الصحة" if is_arabic else "HEALTH"
	path_label.text = player.stats.get_path_name(is_arabic).to_upper()
	respawn_title.text = "لقد سقطت" if is_arabic else "YOU FELL"
	respawn_subtitle.text = "رحلتك لم تنتهِ بعد." if is_arabic else "Your journey is not over."
	respawn_button.text = "إحياء" if is_arabic else "RESPAWN"
	_on_energy_changed(player.path_energy, player.max_path_energy, player._energy_name())
	_on_experience_changed(player.stats.experience, player.stats.experience_to_next_level)
	for slot: int in skill_buttons:
		_refresh_skill_button(slot)

func _tr(english: String, arabic: String) -> String:
	return arabic if is_arabic else english

func _on_skill_state_changed(slot: int, skill_name: String, unlocked: bool, cooldown_ratio: float, enough_energy: bool) -> void:
	skill_state[slot] = {"name": skill_name, "unlocked": unlocked, "cooldown": cooldown_ratio, "enough": enough_energy}
	_refresh_skill_button(slot)

func _refresh_skill_button(slot: int) -> void:
	if not skill_buttons.has(slot):
		return
	var button: Button = skill_buttons[slot]
	var state: Dictionary = skill_state.get(slot, {})
	var skill_name := String(state.get("name", "Skill %d" % slot))
	var definitions := player.stats.get_skill_definitions(is_arabic)
	if definitions.size() >= slot:
		skill_name = String(definitions[slot - 1].get("name", skill_name))
	var unlocked := bool(state.get("unlocked", false))
	var enough_energy := bool(state.get("enough", false))
	var cooldown_ratio := float(state.get("cooldown", 0.0))
	if not unlocked:
		button.text = _tr("SKILL %d\nLOCKED" % slot, "المهارة %d\nمغلقة" % slot)
		button.disabled = true
	elif cooldown_ratio > 0.0:
		button.text = "%s\n%s" % [skill_name, _tr("COOLDOWN", "وقت انتظار")]
		button.disabled = true
	else:
		button.text = "%s\n[%d]" % [skill_name, slot]
		button.disabled = not enough_energy
	button.tooltip_text = _tr("Skill %d" % slot, "المهارة %d" % slot)

func _on_path_selected(_path_value: PlayerStats.Path) -> void:
	_update_path_visibility(player.stats.chosen_path != PlayerStats.Path.NONE)
	path_label.text = player.stats.get_path_name(is_arabic).to_upper()

func _update_path_visibility(visible_value: bool) -> void:
	path_label.visible = visible_value
	health_bar.visible = visible_value
	energy_bar.visible = visible_value
	energy_name_label.visible = visible_value
	for slot: int in skill_buttons:
		skill_buttons[slot].visible = visible_value

func _make_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _make_theme() -> Theme:
	var theme := Theme.new()
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Noto Sans Arabic", "Droid Sans Arabic", "Roboto", "Sans-Serif"])
	theme.default_font = system_font
	theme.default_font_size = 18
	return theme
