class_name TouchUI
extends CanvasLayer

signal movement_changed(value: Vector2)
signal jump_pressed
signal attack_pressed
signal camera_dragged(delta_pixels: Vector2)

var direction_state := Vector2.ZERO
var drag_active := false
var last_drag_position := Vector2.ZERO

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.name = "TouchRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	
	var hint := Label.new()
	hint.text = "WASD / Touch   •   Space / Jump   •   J / Attack"
	hint.position = Vector2(24.0, 20.0)
	hint.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0, 0.8))
	hint.add_theme_font_size_override("font_size", 18)
	root.add_child(hint)
	
	var dpad := Control.new()
	dpad.name = "DirectionalPad"
	dpad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dpad.position = Vector2(32.0, -250.0)
	dpad.size = Vector2(230.0, 210.0)
	root.add_child(dpad)
	_make_direction_button(dpad, "▲", Vector2(75.0, 0.0), Vector2(80.0, 65.0), Vector2.UP)
	_make_direction_button(dpad, "◀", Vector2(0.0, 72.0), Vector2(80.0, 65.0), Vector2.LEFT)
	_make_direction_button(dpad, "●", Vector2(75.0, 72.0), Vector2(80.0, 65.0), Vector2.ZERO)
	_make_direction_button(dpad, "▶", Vector2(150.0, 72.0), Vector2(80.0, 65.0), Vector2.RIGHT)
	_make_direction_button(dpad, "▼", Vector2(75.0, 144.0), Vector2(80.0, 65.0), Vector2.DOWN)
	
	var action_panel := Control.new()
	action_panel.name = "ActionButtons"
	action_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_panel.position = Vector2(-285.0, -225.0)
	action_panel.size = Vector2(250.0, 190.0)
	root.add_child(action_panel)
	var jump_button := _make_action_button(action_panel, "JUMP", Vector2(0.0, 70.0), Color("#38bdf8"))
	jump_button.button_down.connect(func() -> void: jump_pressed.emit())
	var attack_button := _make_action_button(action_panel, "ATTACK", Vector2(125.0, 30.0), Color("#f59e0b"))
	attack_button.button_down.connect(func() -> void: attack_pressed.emit())
	
	var camera_area := Control.new()
	camera_area.name = "CameraDragArea"
	camera_area.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	camera_area.position = Vector2(-390.0, -260.0)
	camera_area.size = Vector2(350.0, 500.0)
	camera_area.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(camera_area)
	camera_area.gui_input.connect(_on_camera_area_input)
	
	var camera_hint := Label.new()
	camera_hint.text = "DRAG TO LOOK"
	camera_hint.position = Vector2(82.0, 460.0)
	camera_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.35))
	camera_area.add_child(camera_hint)

func _make_direction_button(parent: Control, text_value: String, button_position: Vector2, button_size: Vector2, direction: Vector2) -> void:
	var button := Button.new()
	button.text = text_value
	button.position = button_position
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 28)
	button.modulate = Color(1.0, 1.0, 1.0, 0.82)
	parent.add_child(button)
	if direction == Vector2.ZERO:
		return
	button.button_down.connect(func() -> void:
		direction_state += direction
		direction_state = direction_state.limit_length(1.0)
		movement_changed.emit(direction_state)
	)
	button.button_up.connect(func() -> void:
		direction_state -= direction
		direction_state = direction_state.limit_length(1.0)
		movement_changed.emit(direction_state)
	)

func _make_action_button(parent: Control, text_value: String, button_position: Vector2, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = button_position
	button.size = Vector2(115.0, 115.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.modulate = color
	parent.add_child(button)
	return button

func _on_camera_area_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		drag_active = event.pressed
		last_drag_position = event.position
	elif event is InputEventScreenDrag and drag_active:
		camera_dragged.emit(event.position - last_drag_position)
		last_drag_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag_active = event.pressed
		last_drag_position = event.position
	elif event is InputEventMouseMotion and drag_active:
		camera_dragged.emit(event.position - last_drag_position)
		last_drag_position = event.position
