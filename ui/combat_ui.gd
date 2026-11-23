class_name CombatUI
extends CanvasLayer

var player: ActionRPGPlayer
var health_bar: ProgressBar
var energy_bar: ProgressBar
var energy_name_label: Label
var path_label: Label
var skill_buttons: Dictionary = {}
var skill_state: Dictionary = {}

func _ready() -> void:
	_build_hud()
	player.health_changed.connect(_on_health_changed)
	player.energy_changed.connect(_on_energy_changed)
	player.skill_state_changed.connect(_on_skill_state_changed)
	player.stats.path_selected.connect(_on_path_selected)
	_on_health_changed(player.health, player.max_health)
	_on_energy_changed(player.path_energy, player.max_path_energy, player._energy_name())
	for slot: int in range(1, 4):
		_add_skill_button(slot)
	_update_path_visibility(player.stats.chosen_path != PlayerStats.Path.NONE)

func _build_hud() -> void:
	var root := Control.new()
	root.name = "CombatHUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	
	var panel := PanelContainer.new()
	panel.position = Vector2(24.0, 70.0)
	panel.size = Vector2(330.0, 140.0)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.08, 0.14, 0.9), Color("#45658f")))
	root.add_child(panel)
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
	var hp_label := Label.new()
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
	add_child(button)
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
	energy_name_label.text = "%s  %.0f / %.0f" % [energy_name.to_upper(), current, maximum]

func _on_skill_state_changed(slot: int, skill_name: String, unlocked: bool, cooldown_ratio: float, enough_energy: bool) -> void:
	skill_state[slot] = {"name": skill_name, "unlocked": unlocked, "cooldown": cooldown_ratio, "enough": enough_energy}
	_refresh_skill_button(slot)

func _refresh_skill_button(slot: int) -> void:
	if not skill_buttons.has(slot):
		return
	var button: Button = skill_buttons[slot]
	var state: Dictionary = skill_state.get(slot, {})
	var skill_name := String(state.get("name", "Skill %d" % slot))
	var unlocked := bool(state.get("unlocked", false))
	var enough_energy := bool(state.get("enough", false))
	var cooldown_ratio := float(state.get("cooldown", 0.0))
	if not unlocked:
		button.text = "SKILL %d\nLOCKED" % slot
		button.disabled = true
	elif cooldown_ratio > 0.0:
		button.text = "%s\nCOOLDOWN" % skill_name
		button.disabled = true
	else:
		button.text = "%s\n[%d]" % [skill_name, slot]
		button.disabled = not enough_energy
	button.tooltip_text = "Skill %d" % slot

func _on_path_selected(_path_value: PlayerStats.Path) -> void:
	_update_path_visibility(true)
	path_label.text = player.stats.get_path_name().to_upper()

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
