extends CanvasLayer
class_name RepairBotMenu

var player: Node3D
var _root: Control
var _main_page: Control
var _upgrade_page: Control
var _weapon_page: Control
var _tuning_page: Control
var _credits_label: Label
var _dialogue_label: Label
var _page_title: Label
var _active_page: Control
var _upgrade_list: VBoxContainer
var _weapon_status_label: Label
var _tuning_status_label: Label
var _is_open: bool = false
var _upgrade_refresh_queued: bool = false
var _repair_panel: ColorRect
const REPAIR_PANEL_SIZE := Vector2(850.0, 610.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	add_to_group("repair_bot_menu")
	_build_ui()
	_root.visible = false
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	UpgradeManager.profile_changed.connect(_refresh_all)

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "RepairBotOverlay"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.005, 0.012, 0.022, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	_repair_panel = ColorRect.new()
	_repair_panel.custom_minimum_size = REPAIR_PANEL_SIZE
	_repair_panel.color = Color(0.018, 0.045, 0.062, 0.98)
	_repair_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_repair_panel)
	var panel := _repair_panel

	var left_accent := ColorRect.new()
	left_accent.size = Vector2(8.0, 610.0)
	left_accent.color = Color(0.18, 0.82, 0.82)
	panel.add_child(left_accent)

	_add_label(panel, "REPAIR BOT // HARBOR SERVICE NODE 07", Vector2(36.0, 24.0), Vector2(690.0, 32.0), 24, Color(0.48, 0.94, 0.92))
	_add_label(panel, "PILOT LINK ESTABLISHED // HONG KONG MARKET APPROACH", Vector2(38.0, 57.0), Vector2(680.0, 22.0), 12, Color(0.58, 0.68, 0.70))
	_credits_label = _add_label(panel, "CREDITS  0000", Vector2(630.0, 28.0), Vector2(180.0, 26.0), 16, Color(1.0, 0.76, 0.30))
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var tabs := HBoxContainer.new()
	tabs.position = Vector2(38.0, 96.0)
	tabs.size = Vector2(774.0, 38.0)
	tabs.add_theme_constant_override("separation", 8)
	panel.add_child(tabs)
	_add_tab(tabs, "DIAGNOSTIC", 0)
	_add_tab(tabs, "UPGRADE MECH", 1)
	_add_tab(tabs, "WEAPON GROUP", 2)
	_add_tab(tabs, "ADJUST FRAME", 3)

	_page_title = _add_label(panel, "SERVICE DIALOGUE", Vector2(40.0, 156.0), Vector2(700.0, 28.0), 18, Color(1.0, 0.68, 0.24))
	var content := Control.new()
	content.position = Vector2(40.0, 194.0)
	content.size = Vector2(770.0, 330.0)
	panel.add_child(content)

	_main_page = _build_main_page(content)
	_upgrade_page = _build_upgrade_page(content)
	_weapon_page = _build_weapon_page(content)
	_tuning_page = _build_tuning_page(content)

	var close_button := Button.new()
	close_button.text = "DISCONNECT // ESC"
	close_button.position = Vector2(600.0, 550.0)
	close_button.size = Vector2(210.0, 40.0)
	close_button.pressed.connect(close_menu)
	panel.add_child(close_button)
	_show_page(_main_page, "SERVICE DIALOGUE")

func _update_responsive_layout() -> void:
	if _repair_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size - Vector2(32.0, 32.0)
	var fit_scale := minf(viewport_size.x / REPAIR_PANEL_SIZE.x, viewport_size.y / REPAIR_PANEL_SIZE.y)
	fit_scale = minf(fit_scale, 1.0)
	_repair_panel.pivot_offset = REPAIR_PANEL_SIZE * 0.5
	_repair_panel.scale = Vector2.ONE * fit_scale

func _build_main_page(parent: Control) -> Control:
	var page := VBoxContainer.new()
	page.size = parent.size
	page.add_theme_constant_override("separation", 14)
	parent.add_child(page)
	_dialogue_label = Label.new()
	_dialogue_label.text = "SERVICE BOT:\nPILOT, WHAT DO YOU WANT TO DO?\n\nI can improve the HK-05, remap the hand weapon group, tune the chassis, or restore armor before the next sortie."
	_dialogue_label.custom_minimum_size = Vector2(0.0, 120.0)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 17)
	_dialogue_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.88))
	page.add_child(_dialogue_label)
	_add_menu_button(page, "UPGRADE MECH", Callable(self, "_show_upgrade_page"))
	_add_menu_button(page, "CHANGE WEAPON GROUP", Callable(self, "_show_weapon_page"))
	_add_menu_button(page, "ADJUST MECH FRAME", Callable(self, "_show_tuning_page"))
	_add_menu_button(page, "REPAIR TO FULL HEALTH", Callable(self, "_repair_player"))
	return page

func _build_upgrade_page(parent: Control) -> Control:
	var page := VBoxContainer.new()
	page.size = parent.size
	page.add_theme_constant_override("separation", 7)
	parent.add_child(page)
	_upgrade_list = page
	return page

func _build_weapon_page(parent: Control) -> Control:
	var page := VBoxContainer.new()
	page.size = parent.size
	page.add_theme_constant_override("separation", 12)
	parent.add_child(page)
	_weapon_status_label = Label.new()
	_weapon_status_label.custom_minimum_size = Vector2(0.0, 46.0)
	_weapon_status_label.add_theme_font_size_override("font_size", 16)
	_weapon_status_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.86))
	page.add_child(_weapon_status_label)
	_add_menu_button(page, "STRIKE GROUP // L ROCKET / R MACHINE GUN", Callable(self, "_select_strike_group"))
	_add_menu_button(page, "SUPPORT GROUP // L MACHINE GUN / R ROCKET", Callable(self, "_select_support_group"))
	_add_menu_button(page, "BACK TO SERVICE DIALOGUE", Callable(self, "_show_main_page"))
	return page

func _build_tuning_page(parent: Control) -> Control:
	var page := VBoxContainer.new()
	page.size = parent.size
	page.add_theme_constant_override("separation", 12)
	parent.add_child(page)
	_tuning_status_label = Label.new()
	_tuning_status_label.custom_minimum_size = Vector2(0.0, 46.0)
	_tuning_status_label.add_theme_font_size_override("font_size", 16)
	_tuning_status_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.86))
	page.add_child(_tuning_status_label)
	_add_menu_button(page, "BALANCED FRAME", Callable(self, "_select_balanced_frame"))
	_add_menu_button(page, "HEAVY FRAME // MORE HEALTH / LESS SPEED", Callable(self, "_select_heavy_frame"))
	_add_menu_button(page, "MOBILE FRAME // MORE SPEED / LESS HEALTH", Callable(self, "_select_mobile_frame"))
	_add_menu_button(page, "BACK TO SERVICE DIALOGUE", Callable(self, "_show_main_page"))
	return page

func _add_tab(parent: HBoxContainer, text: String, index: int) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180.0, 34.0)
	button.pressed.connect(_on_tab_pressed.bind(index))
	parent.add_child(button)

func _add_menu_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 42.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _add_label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _show_page(page: Control, title: String) -> void:
	_active_page = page
	for candidate in [_main_page, _upgrade_page, _weapon_page, _tuning_page]:
		candidate.visible = candidate == page
	_page_title.text = title
	_refresh_all()

func _show_main_page() -> void:
	_show_page(_main_page, "SERVICE DIALOGUE")

func _show_upgrade_page() -> void:
	_show_page(_upgrade_page, "UPGRADE MECH // SELECT A SYSTEM")

func _show_weapon_page() -> void:
	_show_page(_weapon_page, "CHANGE WEAPON GROUP")

func _show_tuning_page() -> void:
	_show_page(_tuning_page, "ADJUST MECH FRAME")

func _on_tab_pressed(index: int) -> void:
	match index:
		0:
			_show_main_page()
		1:
			_show_upgrade_page()
		2:
			_show_weapon_page()
		3:
			_show_tuning_page()

func _refresh_all() -> void:
	if not is_instance_valid(_credits_label):
		return
	_credits_label.text = "CREDITS  %04d" % UpgradeManager.credits
	if is_instance_valid(_weapon_status_label):
		_weapon_status_label.text = "CURRENT // %s\n%s" % [UpgradeManager.get_weapon_group_name(), UpgradeManager.get_weapon_group_description()]
	if is_instance_valid(_tuning_status_label):
		_tuning_status_label.text = "CURRENT // %s\n%s" % [UpgradeManager.get_mech_tuning_name(), UpgradeManager.get_mech_tuning_description()]
	if is_instance_valid(_upgrade_list) and not _upgrade_refresh_queued:
		_upgrade_refresh_queued = true
		call_deferred("_refresh_upgrade_list")

func _refresh_upgrade_list() -> void:
	_upgrade_refresh_queued = false
	if not is_instance_valid(_upgrade_list):
		return
	for child in _upgrade_list.get_children():
		child.queue_free()
	for upgrade_id in UpgradeManager.get_upgrade_ids():
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 50.0)
		row.add_theme_constant_override("separation", 10)
		_upgrade_list.add_child(row)

		var text := Label.new()
		text.text = "%s  LV %d/%d\n%s" % [UpgradeManager.get_upgrade_name(upgrade_id), UpgradeManager.get_upgrade_level(upgrade_id), UpgradeManager.get_upgrade_max_level(upgrade_id), UpgradeManager.get_upgrade_description(upgrade_id)]
		text.custom_minimum_size = Vector2(500.0, 48.0)
		text.add_theme_font_size_override("font_size", 13)
		text.add_theme_color_override("font_color", Color(0.78, 0.88, 0.88))
		row.add_child(text)

		var button := Button.new()
		var level := UpgradeManager.get_upgrade_level(upgrade_id)
		if level >= UpgradeManager.get_upgrade_max_level(upgrade_id):
			button.text = "MAXED"
			button.disabled = true
		else:
			button.text = "BUY %d" % UpgradeManager.get_upgrade_cost(upgrade_id)
			button.disabled = UpgradeManager.credits < UpgradeManager.get_upgrade_cost(upgrade_id)
		button.custom_minimum_size = Vector2(125.0, 42.0)
		button.pressed.connect(_purchase_upgrade.bind(upgrade_id))
		row.add_child(button)
	_add_menu_button(_upgrade_list, "BACK TO SERVICE DIALOGUE", Callable(self, "_show_main_page"))

func _purchase_upgrade(upgrade_id: StringName) -> void:
	if UpgradeManager.purchase_upgrade(upgrade_id):
		_dialogue_label.text = "SERVICE BOT:\nUPGRADE INSTALLED.\nThe new configuration is active on the HK-05."
	else:
		_dialogue_label.text = "SERVICE BOT:\nUPGRADE UNAVAILABLE.\nCheck credits or maximum level."
	_refresh_all()

func _select_strike_group() -> void:
	UpgradeManager.set_weapon_group(&"strike")
	_show_weapon_page()

func _select_support_group() -> void:
	UpgradeManager.set_weapon_group(&"support")
	_show_weapon_page()

func _select_balanced_frame() -> void:
	UpgradeManager.set_mech_tuning(&"balanced")
	_show_tuning_page()

func _select_heavy_frame() -> void:
	UpgradeManager.set_mech_tuning(&"heavy")
	_show_tuning_page()

func _select_mobile_frame() -> void:
	UpgradeManager.set_mech_tuning(&"mobile")
	_show_tuning_page()

func _repair_player() -> void:
	if is_instance_valid(player) and player.has_method("repair_full"):
		player.call("repair_full")
	_dialogue_label.text = "SERVICE BOT:\nARMOR RESTORED TO 100%.\nYou are cleared for the next sortie."

func open_menu(player_instance: Node3D) -> void:
	player = player_instance
	_is_open = true
	_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_main_page()

func close_menu() -> void:
	if not _is_open:
		return
	_is_open = false
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_open() -> bool:
	return _is_open

func _unhandled_input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("pause_menu"):
		close_menu()
		get_viewport().set_input_as_handled()
