class_name CombatAI
extends RefCounted

static func select_action(enemy: CombatUnit, player_units: Array, enemy_units: Array) -> Dictionary:
	if enemy.is_fainted():
		return {"command_type": CombatCommand.CommandType.DEFEND}
	
	var alive_players := player_units.filter(func(u): return not u.is_fainted())
	
	if alive_players.is_empty():
		return {"command_type": CombatCommand.CommandType.DEFEND}
	
	var roll := randf()
	
	if roll < 0.7:
		return _select_attack(enemy, alive_players)
	elif roll < 0.9:
		return _select_skill(enemy, alive_players)
	else:
		return {"command_type": CombatCommand.CommandType.DEFEND}

static func _select_attack(enemy: CombatUnit, player_units: Array) -> Dictionary:
	var target := _select_target(player_units)
	return {
		"command_type": CombatCommand.CommandType.ATTACK,
		"target": target
	}

static func _select_skill(enemy: CombatUnit, player_units: Array) -> Dictionary:
	if enemy.skills.is_empty():
		return _select_attack(enemy, player_units)
	
	var target := _select_target(player_units)
	var skill_index := randi() % mini(3, enemy.skills.size())
	
	return {
		"command_type": CombatCommand.CommandType.SKILL,
		"target": target,
		"skill_index": skill_index
	}

static func _select_target(player_units: Array) -> CombatUnit:
	var lowest_hp: CombatUnit = null
	var lowest_hp_value := 999999
	
	for unit in player_units:
		if unit is CombatUnit and not unit.is_fainted():
			if unit.current_hp < lowest_hp_value:
				lowest_hp_value = unit.current_hp
				lowest_hp = unit
	
	if lowest_hp == null and not player_units.is_empty():
		for unit in player_units:
			if unit is CombatUnit:
				lowest_hp = unit
				break
	
	return lowest_hp

static func generate_commands_for_enemies(enemy_units: Array, player_units: Array) -> Array:
	var commands: Array = []
	
	for enemy in enemy_units:
		if enemy is CombatUnit and not enemy.is_fainted():
			var action := select_action(enemy, player_units, enemy_units)
			var cmd := CombatCommand.new(enemy, action.command_type, action.get("target", null))
			
			if action.has("skill_index"):
				cmd.skill_index = action.skill_index
			
			commands.append(cmd)
	
	return commands
