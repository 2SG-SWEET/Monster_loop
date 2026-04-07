class_name CaptureManager
extends RefCounted

static func calculate_capture_rate(target: CombatUnit, module_id: String = "") -> float:
	var base_rate := GameConstants.BASE_CAPTURE_RATE
	
	if target.is_weakened:
		base_rate += GameConstants.WEAKEN_CAPTURE_BONUS
	
	var hp_percent := target.get_hp_percent()
	if hp_percent < 0.3:
		base_rate += GameConstants.LOW_HP_CAPTURE_BONUS * (1.0 - hp_percent)
	
	if target.unit_type == CombatUnit.UnitType.BOSS:
		base_rate *= 0.5
	
	base_rate = mini(base_rate, GameConstants.MAX_CAPTURE_RATE)
	
	return base_rate

static func attempt_capture(target: CombatUnit, module_id: String = "") -> Dictionary:
	var inventory := SaveManager.get_inventory()
	var pokeballs: int = inventory.get("pokeballs", 0)
	
	if pokeballs <= 0:
		return {
			"success": false,
			"reason": "no_pokeballs",
			"message": "没有精灵球了！"
		}
	
	SaveManager.use_item("pokeballs", 1)
	
	var rate := calculate_capture_rate(target, module_id)
	var roll := randf()
	var success := roll < rate
	
	if success:
		var captured_monster := _create_captured_monster_data(target)
		SaveManager.add_monster(captured_monster)
		EventBus.monster_captured.emit(captured_monster)
		
		return {
			"success": true,
			"capture_rate": rate,
			"roll": roll,
			"monster_data": captured_monster,
			"message": "成功捕获了 %s！" % target.display_name
		}
	
	return {
		"success": false,
		"capture_rate": rate,
		"roll": roll,
		"message": "捕获失败..."
	}

static func _create_captured_monster_data(unit: CombatUnit) -> Dictionary:
	return {
		"uuid": "monster_%d_%d" % [Time.get_ticks_msec(), randi() % 1000],
		"display_name": unit.display_name,
		"species": unit.display_name,
		"element": unit.element,
		"level": unit.level,
		"base_hp": unit.base_hp,
		"base_atk": unit.base_atk,
		"base_def": unit.base_def,
		"base_spd": unit.base_spd,
		"skills": unit.skills,
		"traits": unit.traits,
		"captured_at": Time.get_datetime_string_from_system()
	}
