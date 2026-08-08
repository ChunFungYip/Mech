extends Node
class_name MechUpgradeManager

const PROFILE_PATH: String = "user://mech_upgrade_profile.cfg"
const SAVE_SLOT_COUNT: int = 3
const SAVE_SLOT_PATH_FORMAT: String = "user://mech_campaign_slot_%d.cfg"
const SAVE_STATE_PATH_FORMAT: String = "user://mech_campaign_slot_%d_state.cfg"
const DEFAULT_CREDITS: int = 1200

signal profile_changed
signal credits_changed(value: int)
signal weapon_group_changed(group_id: StringName)
signal mech_tuning_changed(tuning_id: StringName)
signal cosmetic_changed(theme_id: StringName)

var credits: int = DEFAULT_CREDITS
var weapon_group: StringName = &"strike"
var mech_tuning: StringName = &"balanced"
var cosmetic_theme: StringName = &"neon"
var upgrade_branch: StringName = &"strike"
var active_slot: int = 1
var campaign_mission: int = 1
var campaign_completed: int = 0
var upgrade_levels: Dictionary = {
    "armor": 0,
    "mobility": 0,
    "machinegun": 0,
    "rocket": 0,
    "missile": 0,
}

func _ready() -> void:
    load_profile()

func load_profile() -> void:
    if not _load_from_path(PROFILE_PATH):
        _emit_profile_signals()

func _load_from_path(path: String) -> bool:
    var config := ConfigFile.new()
    if config.load(path) != OK:
        return false

    credits = maxi(int(config.get_value("profile", "credits", DEFAULT_CREDITS)), 0)
    var saved_group := StringName(str(config.get_value("profile", "weapon_group", "strike")))
    if saved_group == &"strike" or saved_group == &"support":
        weapon_group = saved_group
    var saved_tuning := StringName(str(config.get_value("profile", "mech_tuning", "balanced")))
    if saved_tuning == &"balanced" or saved_tuning == &"heavy" or saved_tuning == &"mobile":
        mech_tuning = saved_tuning
    var saved_theme := StringName(str(config.get_value("profile", "cosmetic_theme", "neon")))
    if saved_theme == &"neon" or saved_theme == &"amber" or saved_theme == &"arctic":
        cosmetic_theme = saved_theme
    var saved_branch := StringName(str(config.get_value("profile", "upgrade_branch", "strike")))
    if saved_branch == &"strike" or saved_branch == &"support":
        upgrade_branch = saved_branch
    for upgrade_id in upgrade_levels.keys():
        var saved_level := int(config.get_value("upgrades", str(upgrade_id), 0))
        upgrade_levels[upgrade_id] = clampi(saved_level, 0, get_upgrade_max_level(StringName(str(upgrade_id))))
    active_slot = clampi(int(config.get_value("campaign", "active_slot", active_slot)), 1, SAVE_SLOT_COUNT)
    campaign_mission = maxi(int(config.get_value("campaign", "mission", 1)), 1)
    campaign_completed = maxi(int(config.get_value("campaign", "completed", 0)), 0)
    _emit_profile_signals()
    return true

func save_profile() -> void:
    _save_to_path(PROFILE_PATH)
    save_slot(active_slot)

func _save_to_path(path: String) -> void:
    var config := ConfigFile.new()
    config.set_value("profile", "credits", credits)
    config.set_value("profile", "weapon_group", String(weapon_group))
    config.set_value("profile", "mech_tuning", String(mech_tuning))
    config.set_value("profile", "cosmetic_theme", String(cosmetic_theme))
    config.set_value("profile", "upgrade_branch", String(upgrade_branch))
    for upgrade_id in upgrade_levels.keys():
        config.set_value("upgrades", str(upgrade_id), upgrade_levels[upgrade_id])
    config.set_value("campaign", "active_slot", active_slot)
    config.set_value("campaign", "mission", campaign_mission)
    config.set_value("campaign", "completed", campaign_completed)
    config.save(path)

func save_slot(slot_id: int) -> bool:
    if slot_id < 1 or slot_id > SAVE_SLOT_COUNT:
        return false
    active_slot = slot_id
    _save_to_path(_slot_path(slot_id))
    _save_to_path(PROFILE_PATH)
    return true

func load_slot(slot_id: int) -> bool:
    if slot_id < 1 or slot_id > SAVE_SLOT_COUNT:
        return false
    if not _load_from_path(_slot_path(slot_id)):
        return false
    active_slot = slot_id
    _save_to_path(PROFILE_PATH)
    _emit_profile_signals()
    return true

func get_slot_summary(slot_id: int) -> String:
    if slot_id < 1 or slot_id > SAVE_SLOT_COUNT:
        return "INVALID SLOT"
    var config := ConfigFile.new()
    if config.load(_slot_path(slot_id)) != OK:
        return "SLOT %02d // EMPTY" % slot_id
    var mission := int(config.get_value("campaign", "mission", 1))
    var completed := int(config.get_value("campaign", "completed", 0))
    var state_status := "SAVE READY" if has_game_state(slot_id) else "PROFILE ONLY"
    return "SLOT %02d // MISSION %02d // COMPLETE %02d // %s" % [slot_id, mission, completed, state_status]

func save_game_state(slot_id: int, state: Dictionary) -> bool:
    if slot_id < 1 or slot_id > SAVE_SLOT_COUNT:
        return false
    var config := ConfigFile.new()
    config.set_value("state", "version", int(state.get("version", 1)))
    for state_key in state.keys():
        config.set_value("state", str(state_key), state[state_key])
    return config.save(_state_path(slot_id)) == OK

func load_game_state(slot_id: int) -> Dictionary:
    if slot_id < 1 or slot_id > SAVE_SLOT_COUNT:
        return {}
    var config := ConfigFile.new()
    if config.load(_state_path(slot_id)) != OK:
        return {}
    var state: Dictionary = {}
    for state_key in config.get_section_keys("state"):
        state[state_key] = config.get_value("state", state_key)
    return state

func has_game_state(slot_id: int) -> bool:
    if slot_id < 1 or slot_id > SAVE_SLOT_COUNT:
        return false
    return FileAccess.file_exists(_state_path(slot_id))

func record_mission_complete(mission_index: int) -> void:
    campaign_completed = maxi(campaign_completed, mission_index)
    campaign_mission = maxi(campaign_mission, mission_index + 1)
    save_profile()

func _slot_path(slot_id: int) -> String:
    return SAVE_SLOT_PATH_FORMAT % slot_id

func _state_path(slot_id: int) -> String:
    return SAVE_STATE_PATH_FORMAT % slot_id

func get_upgrade_ids() -> Array[StringName]:
    return [&"armor", &"mobility", &"machinegun", &"rocket", &"missile"]

func get_upgrade_name(upgrade_id: StringName) -> String:
    return str(get_upgrade_definition(upgrade_id).get("name", "UNKNOWN"))

func get_upgrade_description(upgrade_id: StringName) -> String:
    return str(get_upgrade_definition(upgrade_id).get("description", ""))

func get_upgrade_level(upgrade_id: StringName) -> int:
    return int(upgrade_levels.get(String(upgrade_id), 0))

func get_upgrade_max_level(upgrade_id: StringName) -> int:
    return int(get_upgrade_definition(upgrade_id).get("max_level", 3))

func get_upgrade_cost(upgrade_id: StringName) -> int:
    var definition := get_upgrade_definition(upgrade_id)
    var level := get_upgrade_level(upgrade_id)
    return int(definition.get("base_cost", 100)) * (level + 1)

func purchase_upgrade(upgrade_id: StringName) -> bool:
    var level := get_upgrade_level(upgrade_id)
    if level >= get_upgrade_max_level(upgrade_id):
        return false
    var cost := get_upgrade_cost(upgrade_id)
    if credits < cost:
        return false
    credits -= cost
    upgrade_levels[String(upgrade_id)] = level + 1
    save_profile()
    credits_changed.emit(credits)
    profile_changed.emit()
    return true

func add_credits(amount: int) -> void:
    if amount <= 0:
        return
    credits += amount
    save_profile()
    credits_changed.emit(credits)
    profile_changed.emit()

func get_weapon_group_name() -> String:
    return "STRIKE GROUP" if weapon_group == &"strike" else "SUPPORT GROUP"

func get_weapon_group_description() -> String:
    if weapon_group == &"strike":
        return "LEFT: DIRECT ROCKET  //  RIGHT: MACHINE GUN"
    return "LEFT: MACHINE GUN  //  RIGHT: DIRECT ROCKET"

func set_weapon_group(group_id: StringName) -> void:
    if group_id != &"strike" and group_id != &"support":
        return
    weapon_group = group_id
    save_profile()
    weapon_group_changed.emit(weapon_group)
    profile_changed.emit()

func get_mech_tuning_name() -> String:
    match mech_tuning:
        &"heavy":
            return "HEAVY FRAME"
        &"mobile":
            return "MOBILE FRAME"
    return "BALANCED FRAME"

func get_mech_tuning_description() -> String:
    match mech_tuning:
        &"heavy":
            return "+100 HEALTH  //  -1.0 M/S MOVE SPEED"
        &"mobile":
            return "+1.2 M/S MOVE SPEED  //  -50 HEALTH"
    return "STANDARD HEALTH  //  STANDARD MOBILITY"

func set_mech_tuning(tuning_id: StringName) -> void:
    if tuning_id != &"balanced" and tuning_id != &"heavy" and tuning_id != &"mobile":
        return
    mech_tuning = tuning_id
    save_profile()
    mech_tuning_changed.emit(mech_tuning)
    profile_changed.emit()

func set_cosmetic_theme(theme_id: StringName) -> void:
    if theme_id != &"neon" and theme_id != &"amber" and theme_id != &"arctic":
        return
    cosmetic_theme = theme_id
    save_profile()
    cosmetic_changed.emit(cosmetic_theme)
    profile_changed.emit()

func set_upgrade_branch(branch_id: StringName) -> void:
    if branch_id != &"strike" and branch_id != &"support":
        return
    upgrade_branch = branch_id
    save_profile()
    profile_changed.emit()

func get_cosmetic_theme_name() -> String:
    match cosmetic_theme:
        &"amber":
            return "AMBER // MARKET GUARD"
        &"arctic":
            return "ARCTIC // HARBOUR WATCH"
    return "NEON // TITAN STANDARD"

func get_upgrade_definition(upgrade_id: StringName) -> Dictionary:
    match upgrade_id:
        &"armor":
            return {"name": "REINFORCED ARMOR", "description": "+100 maximum health per level", "base_cost": 150, "max_level": 3}
        &"mobility":
            return {"name": "SERVO ACTUATORS", "description": "+0.4 m/s movement speed per level", "base_cost": 130, "max_level": 3}
        &"machinegun":
            return {"name": "BALLISTIC CALIBRATION", "description": "+4 machine-gun damage per level", "base_cost": 140, "max_level": 3}
        &"rocket":
            return {"name": "ROCKET PAYLOAD", "description": "+15 rocket damage per level", "base_cost": 160, "max_level": 3}
        &"missile":
            return {"name": "MISSILE GUIDANCE", "description": "+8 missile damage per level", "base_cost": 180, "max_level": 3}
    return {"name": "UNKNOWN", "description": "No data", "base_cost": 9999, "max_level": 0}

func _emit_profile_signals() -> void:
    credits_changed.emit(credits)
    weapon_group_changed.emit(weapon_group)
    mech_tuning_changed.emit(mech_tuning)
    profile_changed.emit()
