extends CanvasLayer
class_name MechSettingsMenu

var _menu_root: Control
var _content: Control
var _pages: Array[Control] = []
var _tab_buttons: Array[Button] = []
var _active_page: int = 0
var _fov_slider: HSlider
var _fov_value: Label
var _volume_slider: HSlider
var _volume_value: Label
var _sensitivity_x_slider: HSlider
var _sensitivity_x_value: Label
var _sensitivity_y_slider: HSlider
var _sensitivity_y_value: Label
var _invert_y_button: CheckButton
var _window_mode_option: OptionButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 30
    _build_ui()
    _menu_root.visible = false

func _build_ui() -> void:
    _menu_root = Control.new()
    _menu_root.name = "SettingsOverlay"
    _menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_menu_root)

    var overlay := ColorRect.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.005, 0.012, 0.025, 0.86)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _menu_root.add_child(overlay)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _menu_root.add_child(center)

    var panel := ColorRect.new()
    panel.custom_minimum_size = Vector2(760.0, 570.0)
    panel.color = Color(0.018, 0.040, 0.060, 0.98)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    center.add_child(panel)

    var accent := ColorRect.new()
    accent.position = Vector2(0.0, 0.0)
    accent.size = Vector2(7.0, 570.0)
    accent.color = Color(1.0, 0.30, 0.10)
    panel.add_child(accent)

    _add_label(panel, "SYSTEM SETTINGS", Vector2(34.0, 24.0), Vector2(500.0, 34.0), 26, Color(1.0, 0.84, 0.42))
    _add_label(panel, "HK-05 TITAN // PILOT LINK CONFIGURATION", Vector2(36.0, 58.0), Vector2(600.0, 22.0), 12, Color(0.45, 0.86, 0.86))

    var tabs := HBoxContainer.new()
    tabs.position = Vector2(34.0, 96.0)
    tabs.size = Vector2(692.0, 38.0)
    tabs.add_theme_constant_override("separation", 8)
    panel.add_child(tabs)
    for tab_name in ["DISPLAY", "AUDIO", "CONTROLS", "GAMEPLAY"]:
        var tab := Button.new()
        tab.text = tab_name
        tab.custom_minimum_size = Vector2(150.0, 34.0)
        tab.focus_mode = Control.FOCUS_ALL
        tab.pressed.connect(_on_tab_pressed.bind(_tab_buttons.size()))
        tabs.add_child(tab)
        _tab_buttons.append(tab)

    _content = Control.new()
    _content.position = Vector2(36.0, 148.0)
    _content.size = Vector2(688.0, 330.0)
    panel.add_child(_content)
    _build_display_page()
    _build_audio_page()
    _build_controls_page()
    _build_gameplay_page()
    _show_page(0)

    var footer := HBoxContainer.new()
    footer.position = Vector2(36.0, 500.0)
    footer.size = Vector2(688.0, 42.0)
    footer.alignment = BoxContainer.ALIGNMENT_END
    footer.add_theme_constant_override("separation", 12)
    panel.add_child(footer)

    var reset_button := Button.new()
    reset_button.text = "RESET DEFAULTS"
    reset_button.custom_minimum_size = Vector2(170.0, 38.0)
    reset_button.pressed.connect(_reset_defaults)
    footer.add_child(reset_button)

    var resume_button := Button.new()
    resume_button.text = "RESUME // ESC"
    resume_button.custom_minimum_size = Vector2(170.0, 38.0)
    resume_button.pressed.connect(close_menu)
    footer.add_child(resume_button)

    _add_label(panel, "Changes save automatically to user://mech_settings.cfg", Vector2(36.0, 548.0), Vector2(430.0, 18.0), 11, Color(0.46, 0.56, 0.58))

func _build_display_page() -> void:
    var page := _new_page()
    _fov_slider = _make_slider_row(page, "Field of View", 60.0, 120.0, 1.0, SettingsManager.field_of_view, "deg")
    _fov_value = _value_label_for(_fov_slider)
    _fov_slider.value_changed.connect(_on_fov_changed)
    _window_mode_option = OptionButton.new()
    _window_mode_option.add_item("Windowed", 0)
    _window_mode_option.add_item("Borderless", 1)
    _window_mode_option.add_item("Fullscreen", 2)
    _window_mode_option.select(SettingsManager.window_mode)
    _window_mode_option.item_selected.connect(_on_window_mode_changed)
    _add_control_row(page, "Window Mode", _window_mode_option)
    _add_hint(page, "Display changes are applied immediately.")

func _build_audio_page() -> void:
    var page := _new_page()
    _volume_slider = _make_slider_row(page, "Master Volume", 0.0, 1.0, 0.01, SettingsManager.master_volume, "%")
    _volume_value = _value_label_for(_volume_slider)
    _volume_slider.value_changed.connect(_on_volume_changed)
    _add_hint(page, "The master bus is ready for the prototype's future audio layer.")

func _build_controls_page() -> void:
    var page := _new_page()
    _add_info_row(page, "W A S D", "Move mech")
    _add_info_row(page, "SHIFT", "Heat-limited sprint")
    _add_info_row(page, "MOUSE", "Aim and rotate camera")
    _add_info_row(page, "LMB / RMB", "Left rocket / right machine gun")
    _add_info_row(page, "R", "Reload machine gun")
    _add_info_row(page, "1 / 2", "Return to dual-hand weapons")
    _add_info_row(page, "3", "Missile port: LMB lock / RMB direct")
    _add_info_row(page, "E", "Talk to repair bot in home base")
    _add_info_row(page, "V", "Switch first / third person")
    _add_info_row(page, "ESC", "Open or close settings")
    _add_hint(page, "Key rebinding can be added here as the control set grows.")

func _build_gameplay_page() -> void:
    var page := _new_page()
    _sensitivity_x_slider = _make_slider_row(page, "Mouse Sensitivity X", 0.0005, 0.01, 0.0001, SettingsManager.mouse_sensitivity_x, "")
    _sensitivity_x_value = _value_label_for(_sensitivity_x_slider)
    _sensitivity_x_slider.value_changed.connect(_on_sensitivity_x_changed)
    _sensitivity_y_slider = _make_slider_row(page, "Mouse Sensitivity Y", 0.0005, 0.01, 0.0001, SettingsManager.mouse_sensitivity_y, "")
    _sensitivity_y_value = _value_label_for(_sensitivity_y_slider)
    _sensitivity_y_slider.value_changed.connect(_on_sensitivity_y_changed)
    _invert_y_button = CheckButton.new()
    _invert_y_button.text = "Invert vertical mouse axis"
    _invert_y_button.button_pressed = SettingsManager.mouse_invert_y
    _invert_y_button.toggled.connect(_on_invert_y_changed)
    _add_control_row(page, "Aim", _invert_y_button)
    _add_hint(page, "Sensitivity and aim direction apply to both camera modes.")

func _new_page() -> Control:
    var page := VBoxContainer.new()
    page.position = Vector2.ZERO
    page.size = _content.size
    page.add_theme_constant_override("separation", 10)
    _content.add_child(page)
    _pages.append(page)
    return page

func _make_slider_row(parent: Control, title: String, minimum: float, maximum: float, step: float, value: float, suffix: String) -> HSlider:
    var slider := HSlider.new()
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = step
    slider.value = value
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.custom_minimum_size = Vector2(280.0, 30.0)
    slider.set_meta("setting_suffix", suffix)
    _add_control_row(parent, title, slider)
    var value_label := Label.new()
    value_label.name = "Value"
    value_label.custom_minimum_size = Vector2(74.0, 30.0)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value_label.add_theme_font_size_override("font_size", 14)
    value_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.92))
    slider.get_parent().add_child(value_label)
    _update_slider_label(slider, value_label)
    return slider

func _value_label_for(slider: HSlider) -> Label:
    return slider.get_parent().get_node("Value") as Label

func _update_slider_label(slider: HSlider, label: Label) -> void:
    var suffix: String = slider.get_meta("setting_suffix", "")
    if suffix == "%":
        label.text = "%d%%" % int(round(slider.value * 100.0))
    elif suffix == "deg":
        label.text = "%d deg" % int(round(slider.value))
    else:
        label.text = "%.4f" % slider.value

func _add_control_row(parent: Control, title: String, control: Control) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0.0, 38.0)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 16)
    parent.add_child(row)
    var label := Label.new()
    label.text = title
    label.custom_minimum_size = Vector2(220.0, 34.0)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.88))
    row.add_child(label)
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(control)
    return row

func _add_info_row(parent: Control, key_text: String, description: String) -> void:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0.0, 30.0)
    row.add_theme_constant_override("separation", 18)
    parent.add_child(row)
    var key_label := Label.new()
    key_label.text = key_text
    key_label.custom_minimum_size = Vector2(220.0, 28.0)
    key_label.add_theme_font_size_override("font_size", 15)
    key_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.32))
    row.add_child(key_label)
    var description_label := Label.new()
    description_label.text = description
    description_label.add_theme_font_size_override("font_size", 14)
    description_label.add_theme_color_override("font_color", Color(0.74, 0.80, 0.80))
    row.add_child(description_label)

func _add_hint(parent: Control, text: String) -> void:
    var hint := Label.new()
    hint.text = text
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.custom_minimum_size = Vector2(0.0, 38.0)
    hint.add_theme_font_size_override("font_size", 12)
    hint.add_theme_color_override("font_color", Color(0.46, 0.58, 0.60))
    parent.add_child(hint)

func _add_label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.size = size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    parent.add_child(label)
    return label

func _show_page(index: int) -> void:
    _active_page = index
    for page_index in _pages.size():
        _pages[page_index].visible = page_index == index
    for tab_index in _tab_buttons.size():
        _tab_buttons[tab_index].disabled = tab_index == index

func _on_tab_pressed(index: int) -> void:
    _show_page(index)

func _on_fov_changed(value: float) -> void:
    _update_slider_label(_fov_slider, _fov_value)
    SettingsManager.set_field_of_view(value)

func _on_volume_changed(value: float) -> void:
    _update_slider_label(_volume_slider, _volume_value)
    SettingsManager.set_master_volume(value)

func _on_sensitivity_x_changed(value: float) -> void:
    _update_slider_label(_sensitivity_x_slider, _sensitivity_x_value)
    SettingsManager.set_mouse_sensitivity(value, SettingsManager.mouse_sensitivity_y)

func _on_sensitivity_y_changed(value: float) -> void:
    _update_slider_label(_sensitivity_y_slider, _sensitivity_y_value)
    SettingsManager.set_mouse_sensitivity(SettingsManager.mouse_sensitivity_x, value)

func _on_invert_y_changed(enabled: bool) -> void:
    SettingsManager.set_mouse_invert_y(enabled)

func _on_window_mode_changed(index: int) -> void:
    SettingsManager.set_window_mode(index)

func _reset_defaults() -> void:
    SettingsManager.reset_defaults()
    _fov_slider.value = SettingsManager.field_of_view
    _volume_slider.value = SettingsManager.master_volume
    _sensitivity_x_slider.value = SettingsManager.mouse_sensitivity_x
    _sensitivity_y_slider.value = SettingsManager.mouse_sensitivity_y
    _invert_y_button.button_pressed = SettingsManager.mouse_invert_y
    _window_mode_option.select(SettingsManager.window_mode)
    _update_slider_label(_fov_slider, _fov_value)
    _update_slider_label(_volume_slider, _volume_value)
    _update_slider_label(_sensitivity_x_slider, _sensitivity_x_value)
    _update_slider_label(_sensitivity_y_slider, _sensitivity_y_value)

func open_menu() -> void:
    if _menu_root.visible:
        return
    _menu_root.visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _tab_buttons[_active_page].grab_focus()

func close_menu() -> void:
    if not _menu_root.visible:
        return
    _menu_root.visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_menu() -> void:
    if _menu_root.visible:
        close_menu()
    else:
        open_menu()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause_menu"):
        for repair_menu in get_tree().get_nodes_in_group("repair_bot_menu"):
            if repair_menu.has_method("is_open") and bool(repair_menu.call("is_open")):
                repair_menu.call("close_menu")
                get_viewport().set_input_as_handled()
                return
        toggle_menu()
        get_viewport().set_input_as_handled()
