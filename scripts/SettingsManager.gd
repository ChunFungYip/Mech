extends Node
class_name MechSettingsManager

const SETTINGS_FILE_PATH: String = "user://mech_settings.cfg"
const DEFAULT_FIELD_OF_VIEW: float = 76.0
const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_MOUSE_SENSITIVITY_X: float = 0.0025
const DEFAULT_MOUSE_SENSITIVITY_Y: float = 0.0022
const DEFAULT_MOUSE_INVERT_Y: bool = false
const DEFAULT_WINDOW_MODE: int = 0

signal field_of_view_changed(value: float)
signal master_volume_changed(value: float)
signal mouse_sensitivity_changed(value_x: float, value_y: float)
signal mouse_invert_y_changed(enabled: bool)
signal window_mode_changed(mode: int)

var field_of_view: float = DEFAULT_FIELD_OF_VIEW
var master_volume: float = DEFAULT_MASTER_VOLUME
var mouse_sensitivity_x: float = DEFAULT_MOUSE_SENSITIVITY_X
var mouse_sensitivity_y: float = DEFAULT_MOUSE_SENSITIVITY_Y
var mouse_invert_y: bool = DEFAULT_MOUSE_INVERT_Y
var window_mode: int = DEFAULT_WINDOW_MODE

func _ready() -> void:
    load_settings()

func load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_FILE_PATH) != OK:
        _apply_all_settings()
        return

    field_of_view = clampf(float(config.get_value("display", "field_of_view", DEFAULT_FIELD_OF_VIEW)), 60.0, 120.0)
    window_mode = clampi(int(config.get_value("display", "window_mode", DEFAULT_WINDOW_MODE)), 0, 2)
    master_volume = clampf(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
    mouse_sensitivity_x = clampf(float(config.get_value("gameplay", "mouse_sensitivity_x", DEFAULT_MOUSE_SENSITIVITY_X)), 0.0005, 0.01)
    mouse_sensitivity_y = clampf(float(config.get_value("gameplay", "mouse_sensitivity_y", DEFAULT_MOUSE_SENSITIVITY_Y)), 0.0005, 0.01)
    mouse_invert_y = bool(config.get_value("gameplay", "mouse_invert_y", DEFAULT_MOUSE_INVERT_Y))
    _apply_all_settings()

func save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("display", "field_of_view", field_of_view)
    config.set_value("display", "window_mode", window_mode)
    config.set_value("audio", "master_volume", master_volume)
    config.set_value("gameplay", "mouse_sensitivity_x", mouse_sensitivity_x)
    config.set_value("gameplay", "mouse_sensitivity_y", mouse_sensitivity_y)
    config.set_value("gameplay", "mouse_invert_y", mouse_invert_y)
    config.save(SETTINGS_FILE_PATH)

func set_field_of_view(value: float) -> void:
    field_of_view = clampf(value, 60.0, 120.0)
    field_of_view_changed.emit(field_of_view)
    save_settings()

func set_master_volume(value: float) -> void:
    master_volume = clampf(value, 0.0, 1.0)
    _apply_master_volume()
    master_volume_changed.emit(master_volume)
    save_settings()

func set_mouse_sensitivity(value_x: float, value_y: float) -> void:
    mouse_sensitivity_x = clampf(value_x, 0.0005, 0.01)
    mouse_sensitivity_y = clampf(value_y, 0.0005, 0.01)
    mouse_sensitivity_changed.emit(mouse_sensitivity_x, mouse_sensitivity_y)
    save_settings()

func set_mouse_invert_y(enabled: bool) -> void:
    mouse_invert_y = enabled
    mouse_invert_y_changed.emit(mouse_invert_y)
    save_settings()

func set_window_mode(mode: int) -> void:
    window_mode = clampi(mode, 0, 2)
    _apply_window_mode()
    window_mode_changed.emit(window_mode)
    save_settings()

func reset_defaults() -> void:
    field_of_view = DEFAULT_FIELD_OF_VIEW
    master_volume = DEFAULT_MASTER_VOLUME
    mouse_sensitivity_x = DEFAULT_MOUSE_SENSITIVITY_X
    mouse_sensitivity_y = DEFAULT_MOUSE_SENSITIVITY_Y
    mouse_invert_y = DEFAULT_MOUSE_INVERT_Y
    window_mode = DEFAULT_WINDOW_MODE
    _apply_all_settings()
    save_settings()

func _apply_all_settings() -> void:
    _apply_window_mode()
    _apply_master_volume()
    field_of_view_changed.emit(field_of_view)
    master_volume_changed.emit(master_volume)
    mouse_sensitivity_changed.emit(mouse_sensitivity_x, mouse_sensitivity_y)
    mouse_invert_y_changed.emit(mouse_invert_y)
    window_mode_changed.emit(window_mode)

func _apply_master_volume() -> void:
    var volume_db := -80.0 if master_volume <= 0.001 else linear_to_db(master_volume)
    AudioServer.set_bus_volume_db(0, volume_db)

func _apply_window_mode() -> void:
    match window_mode:
        0:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
        1:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
        2:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
