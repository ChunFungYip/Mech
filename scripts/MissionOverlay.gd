extends CanvasLayer
class_name MissionOverlay

var game: Node
var _root: Control
var _title: Label
var _body: Label
var _primary_button: Button
var _secondary_button: Button
var _open: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 60
    _build_ui()
    _root.visible = false

func setup(game_instance: Node) -> void:
    game = game_instance

func _build_ui() -> void:
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_root)

    var overlay := ColorRect.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.005, 0.008, 0.016, 0.88)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _root.add_child(overlay)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(center)

    var panel := ColorRect.new()
    panel.custom_minimum_size = Vector2(700.0, 360.0)
    panel.color = Color(0.025, 0.045, 0.065, 0.98)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    center.add_child(panel)

    var accent := ColorRect.new()
    accent.size = Vector2(8.0, 360.0)
    accent.color = Color(1.0, 0.18, 0.08)
    panel.add_child(accent)

    _title = _label(panel, "MISSION FAILED", Vector2(42.0, 34.0), Vector2(610.0, 42.0), 32, Color(1.0, 0.42, 0.22))
    _body = _label(panel, "COCKPIT LINK LOST", Vector2(42.0, 98.0), Vector2(610.0, 110.0), 17, Color(0.78, 0.86, 0.87))
    _body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    _primary_button = Button.new()
    _primary_button.position = Vector2(42.0, 250.0)
    _primary_button.size = Vector2(290.0, 48.0)
    _primary_button.text = "RESTART CHECKPOINT"
    _primary_button.pressed.connect(_restart_checkpoint)
    panel.add_child(_primary_button)

    _secondary_button = Button.new()
    _secondary_button.position = Vector2(368.0, 250.0)
    _secondary_button.size = Vector2(290.0, 48.0)
    _secondary_button.text = "RETURN TO HOME BASE"
    _secondary_button.pressed.connect(_secondary_action)
    panel.add_child(_secondary_button)

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.size = size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    parent.add_child(label)
    return label

func show_failure(checkpoint_name: String) -> void:
    _open = true
    _root.visible = true
    get_tree().paused = true
    _title.text = "MISSION FAILED"
    _title.add_theme_color_override("font_color", Color(1.0, 0.30, 0.16))
    _body.text = "COCKPIT LINK LOST\n\nCHECKPOINT AVAILABLE // %s\nRestart to resume the sortie from the latest checkpoint, or return to the home base start." % checkpoint_name
    _primary_button.visible = true
    _secondary_button.visible = true
    _primary_button.text = "RESTART CHECKPOINT"
    _secondary_button.text = "RETURN TO HOME BASE"
    _primary_button.grab_focus()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_complete() -> void:
    _open = true
    _root.visible = true
    get_tree().paused = true
    _title.text = "MISSION COMPLETE"
    _title.add_theme_color_override("font_color", Color(0.34, 1.0, 0.72))
    _body.text = "CENTRAL MARKET SECURED\n\nThe HK-05 returned to base with the siege boss destroyed. Credits and upgrades are saved."
    _primary_button.visible = false
    _secondary_button.visible = true
    _secondary_button.text = "CONTINUE FREE ROAM"
    _secondary_button.position = Vector2(205.0, 250.0)
    _secondary_button.grab_focus()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _restart_checkpoint() -> void:
    if game != null and game.has_method("restart_from_checkpoint"):
        game.call("restart_from_checkpoint")

func _restart_mission() -> void:
    if game != null and game.has_method("restart_mission"):
        game.call("restart_mission")

func _secondary_action() -> void:
    if _title.text == "MISSION COMPLETE":
        close_overlay()
    else:
        _restart_mission()

func close_overlay() -> void:
    _open = false
    _root.visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_open() -> bool:
    return _open

func _unhandled_input(event: InputEvent) -> void:
    if _open and event.is_action_pressed("pause_menu"):
        if _title.text == "MISSION COMPLETE":
            close_overlay()
        get_viewport().set_input_as_handled()
