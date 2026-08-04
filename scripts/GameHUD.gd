extends CanvasLayer
class_name GameHUD

var player: Node
var game: Node
var _stats_label: Label
var _weapon_status_label: Label
var _missile_lock_label: Label
var _wave_label: Label
var _view_label: Label
var _message_label: Label
var _message_timer: float = 0.0

func _ready() -> void:
    _build_ui()

func setup(player_instance: Node, game_instance: Node) -> void:
    player = player_instance
    game = game_instance
    if player != null and player.has_signal("announcement"):
        player.connect("announcement", Callable(self, "_on_announcement"))

func _panel(parent: Control, position: Vector2, size: Vector2, color: Color) -> ColorRect:
    var panel := ColorRect.new()
    panel.position = position
    panel.size = size
    panel.color = color
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(panel)
    return panel

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.size = size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _build_ui() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _panel(root, Vector2(24.0, 24.0), Vector2(370.0, 164.0), Color(0.018, 0.035, 0.05, 0.90))
    _label(root, "HONGONG MECH // NEON HARBOUR", Vector2(42.0, 38.0), Vector2(340.0, 24.0), 16, Color(0.45, 0.92, 0.92))
    _label(root, "HK-05 TITAN // COCKPIT LINK ACTIVE", Vector2(42.0, 63.0), Vector2(340.0, 20.0), 12, Color(0.70, 0.75, 0.76))
    _stats_label = _label(root, "SPEED  000 m/s\nHEALTH / ARMOR  500 / 500\nMACHINE GUN  60 / 240\nROCKET POD  06 / 12", Vector2(42.0, 88.0), Vector2(340.0, 82.0), 15, Color(1.0, 0.78, 0.35))

    _panel(root, Vector2(24.0, 196.0), Vector2(370.0, 42.0), Color(0.018, 0.035, 0.05, 0.86))
    _weapon_status_label = _label(root, "WEAPON // DUAL HANDS // L ROCKET // R MG", Vector2(42.0, 208.0), Vector2(340.0, 20.0), 12, Color(0.42, 0.92, 0.86))

    _panel(root, Vector2(420.0, 24.0), Vector2(440.0, 68.0), Color(0.018, 0.035, 0.05, 0.82))
    _label(root, "OPERATION // HOLD THE MARKET APPROACH", Vector2(442.0, 36.0), Vector2(400.0, 22.0), 14, Color(1.0, 0.40, 0.20))
    _wave_label = _label(root, "WAVE 01 // CONTACTS 00", Vector2(442.0, 61.0), Vector2(400.0, 20.0), 12, Color(0.72, 0.82, 0.82))

    _panel(root, Vector2(1022.0, 24.0), Vector2(234.0, 68.0), Color(0.018, 0.035, 0.05, 0.82))
    _view_label = _label(root, "VIEW // FIRST PERSON", Vector2(1040.0, 38.0), Vector2(200.0, 22.0), 14, Color(0.46, 0.92, 0.86))
    _label(root, "V  CAMERA LINK", Vector2(1040.0, 63.0), Vector2(200.0, 18.0), 11, Color(0.68, 0.72, 0.74))

    var crosshair := _label(root, "+", Vector2.ZERO, Vector2(40.0, 40.0), 30, Color(0.88, 1.0, 0.82))
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.offset_left = -20.0
    crosshair.offset_top = -24.0
    crosshair.offset_right = 20.0
    crosshair.offset_bottom = 16.0
    crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    _missile_lock_label = _label(root, "MISSILE LOCK // NO TARGET // AIM POINT FIRE", Vector2.ZERO, Vector2(540.0, 26.0), 13, Color(1.0, 0.36, 0.14))
    _missile_lock_label.set_anchors_preset(Control.PRESET_CENTER)
    _missile_lock_label.offset_left = -270.0
    _missile_lock_label.offset_top = 28.0
    _missile_lock_label.offset_right = 270.0
    _missile_lock_label.offset_bottom = 54.0
    _missile_lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _missile_lock_label.visible = false

    _panel(root, Vector2(24.0, 642.0), Vector2(580.0, 52.0), Color(0.018, 0.035, 0.05, 0.78))
    _label(root, "WASD MOVE   SHIFT BOOST   LMB L-WEAPON   RMB R-WEAPON   E TALK   3 MISSILES", Vector2(42.0, 658.0), Vector2(550.0, 24.0), 9, Color(0.72, 0.78, 0.78))

    _panel(root, Vector2(690.0, 642.0), Vector2(566.0, 52.0), Color(0.018, 0.035, 0.05, 0.78))
    _label(root, "MONG KOK DISTRICT // 5 M PLATFORM // HOSTILES ARE LIVE", Vector2(708.0, 658.0), Vector2(530.0, 24.0), 11, Color(0.92, 0.52, 0.35))

    _message_label = _label(root, "SECTOR LIVE // CLEAR THE APPROACH", Vector2(410.0, 585.0), Vector2(460.0, 34.0), 16, Color(1.0, 0.84, 0.43))
    _message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(delta: float) -> void:
    if player == null or game == null:
        return
    var health := int(player.get("health"))
    var health_max := int(player.get("health_max"))
    var speed := float(player.call("get_speed_mps"))
    var machinegun_ammo := int(player.get("machinegun_ammo"))
    var machinegun_reserve := int(player.get("machinegun_reserve"))
    var rocket_ammo := int(player.get("rocket_ammo"))
    var rocket_reserve := int(player.get("rocket_reserve"))
    var boost_suffix := "  BOOST" if bool(player.call("is_boosting")) else ""
    _stats_label.text = "SPEED  %03d m/s%s\nHEALTH / ARMOR  %03d / %03d\nMACHINE GUN  %02d / %03d\nROCKET POD  %02d / %02d" % [int(round(speed)), boost_suffix, health, health_max, machinegun_ammo, machinegun_reserve, rocket_ammo, rocket_reserve]
    _weapon_status_label.text = "WEAPON // " + str(player.call("get_weapon_display_name")) + " // " + str(player.call("get_weapon_status"))
    var missile_selected := bool(player.call("is_missile_pod_selected"))
    _missile_lock_label.visible = missile_selected
    if missile_selected:
        _missile_lock_label.text = str(player.call("get_missile_lock_ui"))
    var wave := int(game.get("wave"))
    var contacts := int(game.call("get_enemy_count"))
    var kills := int(game.get("kills"))
    _wave_label.text = "WAVE %02d // CONTACTS %02d // CONFIRMED %02d" % [wave, contacts, kills]
    _view_label.text = "VIEW // " + ("FIRST PERSON" if bool(player.get("first_person")) else "THIRD PERSON")
    if _message_timer > 0.0:
        _message_timer = maxf(_message_timer - delta, 0.0)
    elif _message_label.text != "SECTOR LIVE // CLEAR THE APPROACH":
        _message_label.text = "SECTOR LIVE // CLEAR THE APPROACH"

func _on_announcement(text: String) -> void:
    _message_label.text = text
    _message_timer = 2.2
