class_name ProgressionUI
extends CanvasLayer

var player: ActionRPGPlayer
var stats: PlayerStats
var path_panel: PanelContainer
var soul_panel: PanelContainer
var soul_tree_button: Button
var header_label: Label
var soul_points_label: Label
var stats_container: VBoxContainer
var skills_container: VBoxContainer
var toast_label: Label
var stat_value_labels: Dictionary = {}
var stat_plus_buttons: Dictionary = {}
var skill_buttons: Dictionary = {}
var stat_action_in_progress: bool = false

const PANEL_COLOR := Color("#101b2d")
const CARD_COLOR := Color("#1c2d47")
const ACCENT_COLOR := Color("#f4c95d")

func _ready() -> void:
	# Keep progression screens above TouchUI and CombatUI so Android touch events reach them.
	layer = 20
	stats = player.stats
	stats.path_selected.connect(_on_path_selected)
	stats.stat_changed.connect(_on_stat_changed)
	stats.soul_points_changed.connect(_on_soul_points_changed)
	stats.skill_changed.connect(_on_skill_changed)
	_build_hud_button()
	_build_path_panel()
	_build_soul_panel()
	if stats.chosen_path == PlayerStats.Path.NONE:
		path_panel.visible = true
		soul_tree_button.visible = false
	else:
		path_panel.visible = false
		soul_tree_button.visible = true
		_refresh_soul_panel()

func _build_hud_button() -> void:
	soul_tree_button = Button.new()
	soul_tree_button.name = "SoulTreeButton"
	soul_tree_button.text = "SOUL TREE  [K]"
	soul_tree_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	soul_tree_button.position = Vector2(-230.0, 24.0)
	soul_tree_button.size = Vector2(205.0, 64.0)
	soul_tree_button.custom_minimum_size = Vector2(205.0, 64.0)
	soul_tree_button.add_theme_font_size_override("font_size", 20)
	soul_tree_button.focus_mode = Control.FOCUS_NONE
	soul_tree_button.pressed.connect(_toggle_soul_panel)
	add_child(soul_tree_button)

func _build_path_panel() -> void:
	path_panel = PanelContainer.new()
	path_panel.name = "PathSelectionPanel"
	path_panel.set_anchors_preset(Control.PRESET_CENTER)
	path_panel.position = Vector2(-390.0, -300.0)
	path_panel.size = Vector2(780.0, 600.0)
	path_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	path_panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_COLOR, 18))
	add_child(path_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	path_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "CHOOSE YOUR ASCENSION PATH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "The village is gone. Your journey begins from nothing."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	content.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cards)
	_add_path_card(cards, PlayerStats.Path.MARTIAL_ARTS, "MARTIAL ARTS", "Unite Body, Soul, and Will.")
	_add_path_card(cards, PlayerStats.Path.CULTIVATION, "CULTIVATION", "Build inner Qi and advance toward immortality.")
	_add_path_card(cards, PlayerStats.Path.MAGIC, "MAGIC", "Expand Magic Circles and fill them with Mana.")
	_add_path_card(cards, PlayerStats.Path.KNIGHTHOOD, "KNIGHTHOOD", "Master Sword skills and strengthen Aura.")

func _add_path_card(parent: VBoxContainer, path_value: PlayerStats.Path, title_text: String, description: String) -> void:
	var card := Button.new()
	card.text = "%s\n%s" % [title_text, description]
	card.custom_minimum_size = Vector2(0.0, 92.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_theme_font_size_override("font_size", 19)
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(func() -> void: _select_path(path_value))
	card.gui_input.connect(func(event: InputEvent) -> void: _on_path_card_input(event, path_value))
	parent.add_child(card)

func _on_path_card_input(event: InputEvent, path_value: PlayerStats.Path) -> void:
	# Explicit screen-touch fallback for Android devices where Button.pressed may not fire.
	if event is InputEventScreenTouch and event.pressed:
		_select_path(path_value)
		get_viewport().set_input_as_handled()

func _build_soul_panel() -> void:
	soul_panel = PanelContainer.new()
	soul_panel.name = "SoulTreePanel"
	soul_panel.set_anchors_preset(Control.PRESET_CENTER)
	soul_panel.position = Vector2(-470.0, -330.0)
	soul_panel.size = Vector2(940.0, 660.0)
	soul_panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_COLOR, 18))
	soul_panel.visible = false
	add_child(soul_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	soul_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	header_label = Label.new()
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.add_theme_color_override("font_color", ACCENT_COLOR)
	header_label.add_theme_font_size_override("font_size", 23)
	title_row.add_child(header_label)
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(110.0, 52.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void: soul_panel.visible = false)
	title_row.add_child(close_button)
	
	soul_points_label = Label.new()
	soul_points_label.add_theme_font_size_override("font_size", 21)
	content.add_child(soul_points_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_theme_constant_override("separation", 8)
	scroll.add_child(scroll_content)
	var stats_title := Label.new()
	stats_title.text = "CORE SOUL TREE STATS"
	stats_title.add_theme_color_override("font_color", ACCENT_COLOR)
	stats_title.add_theme_font_size_override("font_size", 19)
	scroll_content.add_child(stats_title)
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 6)
	scroll_content.add_child(stats_container)
	for stat_name: String in ["strength", "wisdom", "agility", "speed", "willpower"]:
		_add_stat_row(stat_name)
	var skills_title := Label.new()
	skills_title.text = "PATH-SPECIFIC SKILLS"
	skills_title.add_theme_color_override("font_color", ACCENT_COLOR)
	skills_title.add_theme_font_size_override("font_size", 19)
	scroll_content.add_child(skills_title)
	skills_container = VBoxContainer.new()
	skills_container.add_theme_constant_override("separation", 6)
	scroll_content.add_child(skills_container)
	var test_button := Button.new()
	test_button.text = "+1 SOUL POINT (TEST)"
	test_button.custom_minimum_size = Vector2(0.0, 54.0)
	test_button.focus_mode = Control.FOCUS_NONE
	test_button.pressed.connect(_on_test_soul_point_pressed)
	content.add_child(test_button)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color("#a7f3d0"))
	content.add_child(toast_label)

func _add_stat_row(stat_name: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 58.0)
	var label := Label.new()
	label.text = stat_name.capitalize()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = "1"
	value_label.custom_minimum_size = Vector2(60.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 21)
	row.add_child(value_label)
	stat_value_labels[stat_name] = value_label
	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(64.0, 54.0)
	plus_button.add_theme_font_size_override("font_size", 28)
	plus_button.focus_mode = Control.FOCUS_NONE
	plus_button.pressed.connect(_on_stat_button_pressed.bind(stat_name))
	row.add_child(plus_button)
	stat_plus_buttons[stat_name] = plus_button
	stats_container.add_child(row)

func _select_path(path_value: PlayerStats.Path) -> void:
	if stats.choose_path(path_value):
		path_panel.visible = false
		soul_tree_button.visible = true
		_show_toast("Path chosen. Your Soul Tree is now unlocked.")

func _on_path_selected(_path_value: PlayerStats.Path) -> void:
	_refresh_soul_panel()

func _toggle_soul_panel() -> void:
	if stats.chosen_path == PlayerStats.Path.NONE:
		return
	soul_panel.visible = not soul_panel.visible
	if soul_panel.visible:
		_refresh_soul_panel()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_soul_tree"):
		_toggle_soul_panel()

func _spend_stat(stat_name: String) -> void:
	if stat_action_in_progress:
		return
	stat_action_in_progress = true
	if stats.spend_soul_point(stat_name):
		_show_toast("%s increased." % stat_name.capitalize())
	else:
		_show_toast("Not enough Soul Points.")
	_refresh_soul_panel()
	stat_action_in_progress = false

func _on_stat_button_pressed(stat_name: String) -> void:
	_spend_stat(stat_name)

func _on_test_soul_point_pressed() -> void:
	# This action changes only Available Soul Points; it never changes a core stat.
	stats.add_test_soul_point()
	_show_toast("+1 Soul Point added.")

func _unlock_skill(skill_id: String) -> void:
	if stats.unlock_skill(skill_id):
		_show_toast("Skill unlocked.")
	else:
		_show_toast("Need more Soul Points or skill is already unlocked.")
	_refresh_soul_panel()

func _refresh_soul_panel() -> void:
	if stats == null or header_label == null:
		return
	header_label.text = "%s  |  %s" % [stats.get_path_name(), stats.get_path_metric()]
	soul_points_label.text = "Level: %d    |    Available Soul Points: %d" % [stats.level, stats.soul_points]
	for stat_name: String in stat_value_labels:
		stat_value_labels[stat_name].text = str(int(stats.get(stat_name)))
		stat_plus_buttons[stat_name].disabled = stats.soul_points <= 0
	for child: Node in skills_container.get_children():
		child.queue_free()
	skill_buttons.clear()
	for definition: Dictionary in stats.get_skill_definitions():
		var skill_id: String = String(definition.get("id", ""))
		var unlocked := stats.is_skill_unlocked(skill_id)
		var button := Button.new()
		var state := "UNLOCKED" if unlocked else "LOCKED"
		var cost: int = int(definition.get("cost", 1))
		button.text = "%s  |  %s  |  Cost: %d\n%s" % [String(definition.get("name", "Skill")), state, cost, String(definition.get("description", ""))]
		button.custom_minimum_size = Vector2(0.0, 72.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = unlocked
		button.pressed.connect(func() -> void: _unlock_skill(skill_id))
		skills_container.add_child(button)
		skill_buttons[skill_id] = button

func _on_stat_changed(stat_name: String, new_value: int) -> void:
	if stat_value_labels.has(stat_name):
		stat_value_labels[stat_name].text = str(new_value)
	_refresh_soul_panel()

func _on_soul_points_changed(_new_value: int) -> void:
	_refresh_soul_panel()

func _on_skill_changed(_skill_id: String, _unlocked: bool) -> void:
	_refresh_soul_panel()

func _show_toast(message: String) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(toast_label):
			toast_label.text = ""
	)

func _make_panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#45658f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
