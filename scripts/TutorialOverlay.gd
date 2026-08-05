extends CanvasLayer
class_name TutorialOverlay

var _root: Control
var _open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 70
	_build_ui()
	_root.visible = false

func setup(_game_instance: Node) -> void:
	if not SettingsManager.tutorial_seen:
		call_deferred("show_tutorial")

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.005, 0.010, 0.020, 0.90)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := ColorRect.new()
	panel.custom_minimum_size = Vector2(760.0, 420.0)
	panel.color = Color(0.020, 0.050, 0.070, 0.98)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var accent := ColorRect.new()
	accent.size = Vector2(8.0, 420.0)
	accent.color = Color(0.12, 0.84, 0.92)
	panel.add_child(accent)

	_label(panel, "HK-05 TITAN // FIRST SORTIE", Vector2(42.0, 32.0), Vector2(650.0, 38.0), 28, Color(0.45, 0.96, 0.92))
	_label(panel, "NEON HARBOUR FIELD GUIDE", Vector2(44.0, 72.0), Vector2(650.0, 24.0), 13, Color(1.0, 0.70, 0.28))
	var body := _label(panel, "WASD  MOVE THE MECH\nSHIFT  SPRINT UNTIL THE HEAT LIMIT\nMOUSE  AIM AND ROTATE THE COCKPIT\nLMB / RMB  FIRE THE EQUIPPED HAND WEAPONS\n1 / 2  RETURN TO DUAL HANDS\n3  OPEN THE MISSILE PORT\nQ  RELEASE AN EMP PULSE\nV  SWITCH FIRST AND THIRD PERSON\nE  TALK TO THE REPAIR BOT INSIDE HOME BASE", Vector2(46.0, 120.0), Vector2(660.0, 220.0), 16, Color(0.80, 0.88, 0.88))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var objective := _label(panel, "SORTIE OBJECTIVE // EXIT THE HANGAR, REACH CENTRAL MARKET, DESTROY THE SIEGE BOSS, RETURN HOME", Vector2(46.0, 316.0), Vector2(660.0, 42.0), 12, Color(1.0, 0.42, 0.20))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var button := Button.new()
	button.text = "BEGIN SORTIE"
	button.position = Vector2(46.0, 366.0)
	button.size = Vector2(240.0, 38.0)
	button.pressed.connect(_dismiss)
	panel.add_child(button)

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func show_tutorial() -> void:
	_open = true
	_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var button := _root.find_child("Button", true, false) as Button
	if button != null:
		button.grab_focus()

func _dismiss() -> void:
	SettingsManager.mark_tutorial_seen()
	_open = false
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("pause_menu"):
		_dismiss()
		get_viewport().set_input_as_handled()
