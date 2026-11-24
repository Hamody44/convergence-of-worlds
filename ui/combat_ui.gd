class_name CombatUI
extends CanvasLayer

signal language_changed(arabic: bool)
signal portal_activate_requested
signal chest_open_requested

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
var stage_label: Label
var boss_panel: PanelContainer
var boss_title: Label
var boss_bar: ProgressBar
var portal_button: Button
var fade_rect: ColorRect
var current_stage: int = 1
var sound_button: Button
var gear_button: Button
var chest_button: Button
var gear_panel: PanelContainer
var gear_content: VBoxContainer
var respawn_title: Label
var respawn_subtitle: Label
var respawn_button: Button
var is_arabic: bool = false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	player.stats.equipment_changed.connect(_refresh_gear_panel)
	_on_health_changed(player.health, player.max_health)
	_on_energy_changed(player.path_energy, player.max_path_energy, player._energy_name())
	_on_experience_changed(player.stats.experience, player.stats.experience_to_next_level)
	level_label.text = "LEVEL %d" % player.stats.level
	for slot: int in range(1, 4):
		_add_skill_button(slot)
	_update_path_visibility(player.stats.chosen_path != PlayerStats.Path.NONE)
	set_stage(player.stats.current_stage)
	_refresh_gear_panel()

func _build_hud() -> void:
	ui_root = Control.new()
	ui_root.name = "CombatHUDRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
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
	sound_button = Button.new()
	sound_button.text = "🔊"
	sound_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sound_button.position = Vector2(-555.0, 24.0)
	sound_button.size = Vector2(64.0, 64.0)
	sound_button.focus_mode = Control.FOCUS_NONE
	sound_button.pressed.connect(_on_sound_pressed)
	ui_root.add_child(sound_button)
	gear_button = Button.new()
	gear_button.text = "GEAR / العتاد"
	gear_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear_button.position = Vector2(-375.0, 96.0)
	gear_button.size = Vector2(190.0, 58.0)
	gear_button.focus_mode = Control.FOCUS_NONE
	gear_button.pressed.connect(_toggle_gear_panel)
	ui_root.add_child(gear_button)
	_build_stage_label()
	_build_boss_bar()
	_build_portal_prompt()
	_build_gear_panel()

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

func _build_stage_label() -> void:
	stage_label = Label.new()
	stage_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stage_label.position = Vector2(0.0, 22.0)
	stage_label.size = Vector2(1280.0, 42.0)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_color_override("font_color", Color("#bae6fd"))
	stage_label.add_theme_font_size_override("font_size", 22)
	ui_root.add_child(stage_label)

func _build_boss_bar() -> void:
	boss_panel = PanelContainer.new()
	boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_panel.position = Vector2(280.0, 78.0)
	boss_panel.size = Vector2(720.0, 92.0)
	boss_panel.add_theme_stylebox_override("panel", _make_style(Color(0.12, 0.02, 0.05, 0.94), Color("#ef4444")))
	boss_panel.visible = false
	ui_root.add_child(boss_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	boss_panel.add_child(content)
	boss_title = Label.new()
	boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title.add_theme_font_size_override("font_size", 20)
	content.add_child(boss_title)
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(0.0, 34.0)
	boss_bar.show_percentage = true
	boss_bar.add_theme_font_size_override("font_size", 17)
	content.add_child(boss_bar)

func _build_portal_prompt() -> void:
	portal_button = Button.new()
	portal_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	portal_button.position = Vector2(-240.0, -145.0)
	portal_button.size = Vector2(480.0, 82.0)
	portal_button.custom_minimum_size = Vector2(480.0, 82.0)
	portal_button.add_theme_font_size_override("font_size", 23)
	portal_button.focus_mode = Control.FOCUS_NONE
	portal_button.visible = false
	portal_button.pressed.connect(func() -> void: portal_activate_requested.emit())
	ui_root.add_child(portal_button)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.0, 0.0, 0.04, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade_rect)

func _build_gear_panel() -> void:
	gear_panel = PanelContainer.new()
	gear_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear_panel.position = Vector2(-520.0, 165.0)
	gear_panel.size = Vector2(490.0, 470.0)
	gear_panel.visible = false
	gear_panel.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.06, 0.12, 0.96), Color("#facc15")))
	ui_root.add_child(gear_panel)
	gear_content = VBoxContainer.new()
	gear_content.add_theme_constant_override("separation", 7)
	gear_panel.add_child(gear_content)

func _on_sound_pressed() -> void:
	var manager := get_tree().get_first_node_in_group("sound_manager")
	if manager != null:
		sound_button.text = "🔇" if not manager.toggle() else "🔊"

func _toggle_gear_panel() -> void:
	gear_panel.visible = not gear_panel.visible
	if gear_panel.visible: _refresh_gear_panel()

func _refresh_gear_panel() -> void:
	if gear_content == null: return
	for child in gear_content.get_children(): child.queue_free()
	var title := Label.new(); title.text = _tr("GEAR / INVENTORY  [I]", "العتاد / الحقيبة  [I]"); title.add_theme_font_size_override("font_size", 22); gear_content.add_child(title)
	var weapon := Label.new(); weapon.text = _gear_line("Weapon", player.stats.equipped_weapon); gear_content.add_child(weapon)
	var armor := Label.new(); armor.text = _gear_line("Armor", player.stats.equipped_armor); gear_content.add_child(armor)
	var separator := HSeparator.new(); gear_content.add_child(separator)
	var inventory: Array = player.stats.inventory
	if inventory.is_empty():
		var empty := Label.new(); empty.text = _tr("No collected gear yet.", "لا يوجد عتاد ملتقط بعد."); gear_content.add_child(empty)
	else:
		for index in range(inventory.size()):
			var item: Dictionary = inventory[index]
			var row := HBoxContainer.new(); row.custom_minimum_size = Vector2(0.0, 58.0)
			var label := Label.new(); label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.text = "%s | %s" % [EquipmentData.localized_name(item, is_arabic), EquipmentData.rarity_name(item, is_arabic)]; row.add_child(label)
			var equip := Button.new(); equip.text = _tr("EQUIP", "تجهيز"); equip.custom_minimum_size = Vector2(100.0, 52.0); equip.pressed.connect(func() -> void: player.stats.equip_gear(index)); row.add_child(equip)
			var salvage := Button.new(); salvage.text = _tr("SALVAGE", "تفكيك"); salvage.custom_minimum_size = Vector2(105.0, 52.0); salvage.pressed.connect(func() -> void: player.stats.salvage_gear(index)); row.add_child(salvage)
			gear_content.add_child(row)

func _gear_line(slot: String, item: Dictionary) -> String:
	if item.is_empty(): return "%s: %s" % [slot, _tr("Empty", "فارغ")]
	return "%s: %s | %s | Power %s" % [slot, EquipmentData.localized_name(item, is_arabic), EquipmentData.rarity_name(item, is_arabic), item.get("power", 0)]

func show_chest_prompt(value: bool) -> void:
	if chest_button == null:
		chest_button = Button.new()
		chest_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		chest_button.position = Vector2(-240.0, -240.0)
		chest_button.size = Vector2(480.0, 82.0)
		chest_button.add_theme_font_size_override("font_size", 23)
		chest_button.focus_mode = Control.FOCUS_NONE
		chest_button.pressed.connect(func() -> void: chest_open_requested.emit())
		ui_root.add_child(chest_button)
	chest_button.text = _tr("OPEN CHEST  [E / F]", "فتح الصندوق  [E / F]")
	chest_button.visible = value

func show_loot_message(item: Dictionary) -> void:
	level_up_banner.text = _tr("LOOT: %s" % EquipmentData.localized_name(item, false), "غنيمة: %s" % EquipmentData.localized_name(item, true))
	level_up_banner.visible = true
	var tween := level_up_banner.create_tween(); tween.tween_interval(2.0); tween.tween_property(level_up_banner, "modulate", Color(1, 1, 1, 0), 0.45)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gear"): _toggle_gear_panel()

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
	respawn_button.gui_input.connect(_on_respawn_button_input)
	respawn_button.process_mode = Node.PROCESS_MODE_ALWAYS
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
	if not player.is_defeated:
		return
	player.respawn_at(player.arena_spawn_position)

func _on_respawn_button_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_respawn_pressed()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and respawn_overlay != null and respawn_overlay.visible:
		if respawn_button != null and respawn_button.get_global_rect().has_point(event.position):
			_on_respawn_pressed()
			get_viewport().set_input_as_handled()

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
	set_stage(current_stage)
	if boss_panel.visible:
		boss_title.text = _tr("ABYSSAL DEVOURER", "وحش الهاوية")
	if portal_button.visible:
		portal_button.text = _tr("ENTER NEXT STAGE  [E]", "دخول المرحلة التالية  [E]")

func set_stage(stage_number: int) -> void:
	current_stage = maxi(stage_number, 1)
	var names := ["Ruined Village", "Crimson Highlands", "Astral Peak"]
	var arabic_names := ["القرية المدمرة", "المرتفعات القرمزية", "القمة النجمية"]
	var index := mini(current_stage - 1, names.size() - 1)
	stage_label.text = _tr("STAGE %d  —  %s" % [current_stage, names[index]], "المرحلة %d  —  %s" % [current_stage, arabic_names[index]])

func show_boss_bar(title: String, current: float, maximum: float) -> void:
	boss_panel.visible = true
	boss_title.text = title
	boss_bar.max_value = maximum
	boss_bar.value = current

func update_boss_bar(current: float, maximum: float) -> void:
	if boss_bar == null: return
	boss_bar.max_value = maximum
	boss_bar.value = current

func hide_boss_bar() -> void:
	if boss_panel != null: boss_panel.visible = false

func show_portal_prompt(value: bool) -> void:
	portal_button.visible = value
	if value:
		portal_button.text = _tr("ENTER NEXT STAGE  [E]", "دخول المرحلة التالية  [E]")

func fade_transition() -> void:
	if fade_rect == null: return
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := fade_rect.create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.35)
	tween.tween_interval(0.25)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.45)
	tween.tween_callback(func() -> void: fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)

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
