extends CanvasLayer
class_name GameHUD

var player: Node
var game: Node
var _stats_label: Label
var _weapon_status_label: Label
var _missile_lock_label: Label
var _target_part_panel: ColorRect
var _target_part_title: Label
var _target_part_rows: Dictionary = {}
var _boss_panel: ColorRect
var _boss_title: Label
var _boss_health_bar: ProgressBar
var _boss_value: Label
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

    _panel(root, Vector2(24.0, 24.0), Vector2(370.0, 190.0), Color(0.018, 0.035, 0.05, 0.90))
    _label(root, "HONGONG MECH // NEON HARBOUR", Vector2(42.0, 38.0), Vector2(340.0, 24.0), 16, Color(0.45, 0.92, 0.92))
    _label(root, "HK-05 TITAN // COCKPIT LINK ACTIVE", Vector2(42.0, 63.0), Vector2(340.0, 20.0), 12, Color(0.70, 0.75, 0.76))
    _stats_label = _label(root, "SPEED  000 m/s\nSPRINT  READY // SAFE 10 S\nHEALTH / ARMOR  500 / 500\nMACHINE GUN  60 / 240\nROCKET POD  06 / 12", Vector2(42.0, 88.0), Vector2(340.0, 108.0), 15, Color(1.0, 0.78, 0.35))

    _panel(root, Vector2(24.0, 222.0), Vector2(370.0, 42.0), Color(0.018, 0.035, 0.05, 0.86))
    _weapon_status_label = _label(root, "WEAPON // DUAL HANDS // L ROCKET // R MG", Vector2(42.0, 234.0), Vector2(340.0, 20.0), 12, Color(0.42, 0.92, 0.86))

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
    _build_target_part_panel(root)
    _build_boss_panel(root)

    _panel(root, Vector2(24.0, 642.0), Vector2(580.0, 52.0), Color(0.018, 0.035, 0.05, 0.78))
    _label(root, "WASD MOVE   SHIFT SPRINT   LMB L-WEAPON   RMB R-WEAPON   E TALK   3 MISSILES", Vector2(42.0, 658.0), Vector2(550.0, 24.0), 9, Color(0.72, 0.78, 0.78))

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
    var sprint_status := str(player.call("get_sprint_status"))
    _stats_label.text = "SPEED  %03d m/s\nSPRINT  %s\nHEALTH / ARMOR  %03d / %03d\nMACHINE GUN  %02d / %03d\nROCKET POD  %02d / %02d" % [int(round(speed)), sprint_status, health, health_max, machinegun_ammo, machinegun_reserve, rocket_ammo, rocket_reserve]
    _weapon_status_label.text = "WEAPON // " + str(player.call("get_weapon_display_name")) + " // " + str(player.call("get_weapon_status"))
    var missile_selected := bool(player.call("is_missile_pod_selected"))
    _missile_lock_label.visible = missile_selected
    if missile_selected:
        _missile_lock_label.text = str(player.call("get_missile_lock_ui"))
    var boss := game.call("get_boss") as Node
    var show_boss_health := bool(game.call("is_boss_area_active")) and boss != null and is_instance_valid(boss) and not bool(boss.get("is_defeated"))
    _boss_panel.visible = show_boss_health
    if show_boss_health:
        var boss_health := float(boss.get("health"))
        var boss_health_max := float(boss.get("health_max"))
        _boss_title.text = "SIEGE CLASS // CENTRAL MARKET"
        _boss_health_bar.max_value = boss_health_max
        _boss_health_bar.value = boss_health
        _boss_value.text = "%04d / %04d" % [int(round(boss_health)), int(round(boss_health_max))]

    var locked_enemy := player.call("get_locked_enemy") as Node
    var locked_boss := locked_enemy != null and is_instance_valid(locked_enemy) and bool(locked_enemy.get("is_boss"))
    var show_part_health := missile_selected and not locked_boss and locked_enemy != null and is_instance_valid(locked_enemy) and locked_enemy.has_method("get_part_health_snapshot")
    _target_part_panel.visible = show_part_health
    if show_part_health:
        _update_target_part_panel(locked_enemy)
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

func _build_target_part_panel(root: Control) -> void:
    _target_part_panel = ColorRect.new()
    _target_part_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    _target_part_panel.offset_left = -370.0
    _target_part_panel.offset_top = 108.0
    _target_part_panel.offset_right = -24.0
    _target_part_panel.offset_bottom = 334.0
    _target_part_panel.color = Color(0.018, 0.035, 0.05, 0.90)
    _target_part_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _target_part_panel.visible = false
    root.add_child(_target_part_panel)

    _target_part_title = _label(_target_part_panel, "LOCKED TARGET // PART STATUS", Vector2(14.0, 10.0), Vector2(320.0, 22.0), 13, Color(1.0, 0.48, 0.22))
    var part_ids: Array[StringName] = [
        &"left_arm",
        &"right_arm",
        &"upper_torso",
        &"lower_torso",
        &"left_leg",
        &"right_leg",
    ]
    var part_names: Dictionary = {
        &"left_arm": "LEFT ARM",
        &"right_arm": "RIGHT ARM",
        &"upper_torso": "UPPER TORSO",
        &"lower_torso": "LOWER TORSO",
        &"left_leg": "LEFT LEG",
        &"right_leg": "RIGHT LEG",
    }
    for row_index in part_ids.size():
        var part_id := part_ids[row_index]
        var row_y := 38.0 + float(row_index) * 29.0
        var name_label := _label(_target_part_panel, str(part_names[part_id]), Vector2(14.0, row_y), Vector2(104.0, 22.0), 10, Color(0.78, 0.84, 0.84))
        var bar := ProgressBar.new()
        bar.position = Vector2(122.0, row_y + 2.0)
        bar.size = Vector2(156.0, 18.0)
        bar.max_value = 1.0
        bar.value = 1.0
        bar.show_percentage = false
        bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.08, 0.10, 0.12)))
        bar.add_theme_stylebox_override("fill", _make_bar_style(_part_bar_color(part_id)))
        _target_part_panel.add_child(bar)
        var value_label := _label(_target_part_panel, "000/000", Vector2(286.0, row_y), Vector2(55.0, 22.0), 10, Color(0.70, 0.90, 0.90))
        value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _target_part_rows[part_id] = {"bar": bar, "value": value_label, "name": name_label}

func _build_boss_panel(root: Control) -> void:
    _boss_panel = ColorRect.new()
    _boss_panel.position = Vector2(420.0, 104.0)
    _boss_panel.size = Vector2(440.0, 72.0)
    _boss_panel.color = Color(0.10, 0.018, 0.025, 0.94)
    _boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _boss_panel.visible = false
    root.add_child(_boss_panel)

    _boss_title = _label(_boss_panel, "SIEGE CLASS // CENTRAL MARKET", Vector2(14.0, 8.0), Vector2(310.0, 20.0), 13, Color(1.0, 0.42, 0.18))
    _boss_value = _label(_boss_panel, "2400 / 2400", Vector2(326.0, 8.0), Vector2(98.0, 20.0), 12, Color(1.0, 0.78, 0.38))
    _boss_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _boss_health_bar = ProgressBar.new()
    _boss_health_bar.position = Vector2(14.0, 37.0)
    _boss_health_bar.size = Vector2(412.0, 22.0)
    _boss_health_bar.max_value = 2400.0
    _boss_health_bar.value = 2400.0
    _boss_health_bar.show_percentage = false
    _boss_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _boss_health_bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.16, 0.06, 0.07)))
    _boss_health_bar.add_theme_stylebox_override("fill", _make_bar_style(Color(0.92, 0.10, 0.08)))
    _boss_panel.add_child(_boss_health_bar)

func _make_bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 2
    style.corner_radius_top_right = 2
    style.corner_radius_bottom_left = 2
    style.corner_radius_bottom_right = 2
    return style

func _part_bar_color(part_id: StringName) -> Color:
    if part_id == &"upper_torso" or part_id == &"lower_torso":
        return Color(1.0, 0.30, 0.12)
    if part_id == &"left_leg" or part_id == &"right_leg":
        return Color(1.0, 0.66, 0.16)
    return Color(0.20, 0.78, 0.82)

func _update_target_part_panel(enemy: Node) -> void:
    var current: Dictionary = enemy.call("get_part_health_snapshot")
    var maximum: Dictionary = enemy.call("get_part_max_health_snapshot")
    _target_part_title.text = "LOCKED TARGET // " + str(enemy.name)
    for part_id in _target_part_rows.keys():
        var row: Dictionary = _target_part_rows[part_id]
        var bar := row["bar"] as ProgressBar
        var value_label := row["value"] as Label
        var part_max := float(maximum.get(part_id, 1.0))
        var part_current := float(current.get(part_id, 0.0))
        bar.max_value = part_max
        bar.value = part_current
        value_label.text = "%03d/%03d" % [int(round(part_current)), int(round(part_max))]
        row["name"].add_theme_color_override("font_color", Color(0.42, 0.92, 0.86) if part_current > 0.0 else Color(0.42, 0.44, 0.45))
