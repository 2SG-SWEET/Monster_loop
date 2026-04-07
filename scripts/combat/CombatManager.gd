class_name CombatManager
extends RefCounted

signal combat_started()
signal combat_ended(result: Dictionary)
signal turn_started(turn_number: int)
signal turn_phase_changed(phase: String)
signal command_phase_started()
signal execution_phase_started()
signal action_executed(action_data: Dictionary)

var _player_units: Array = []
var _enemy_units: Array = []
var _turn_order_manager: TurnOrderManager
var _command_manager: CommandManager
var _current_turn: int = 0
var _is_active: bool = false
var _module_id: String = ""

func _init():
	_turn_order_manager = TurnOrderManager.new()
	_command_manager = CommandManager.new()
	
	_command_manager.all_commands_set.connect(_on_all_commands_set)

func start_combat(player_data: Array, enemy_data: Dictionary, module_id: String = "") -> void:
	_is_active = true
	_current_turn = 0
	_module_id = module_id
	
	_player_units.clear()
	_enemy_units.clear()
	
	for data in player_data:
		var unit := CombatUnit.new(data)
		unit.unit_type = CombatUnit.UnitType.PLAYER
		_player_units.append(unit)
	
	var enemy_unit := CombatUnit.new(enemy_data)
	enemy_unit.unit_type = CombatUnit.UnitType.ENEMY
	if enemy_data.get("is_boss", false):
		enemy_unit.unit_type = CombatUnit.UnitType.BOSS
	_enemy_units.append(enemy_unit)
	
	combat_started.emit()
	_start_new_turn()

func _start_new_turn() -> void:
	_current_turn += 1
	turn_started.emit(_current_turn)
	EventBus.turn_started.emit(_current_turn)
	
	for unit in _player_units:
		unit.reset_turn_state()
	for unit in _enemy_units:
		unit.reset_turn_state()
	
	_turn_order_manager.calculate_turn_order(_get_all_units())
	
	_start_command_phase()

func _start_command_phase() -> void:
	turn_phase_changed.emit("command")
	command_phase_started.emit()
	
	_command_manager.start_command_phase(_player_units)
	
	var enemy_commands := CombatAI.generate_commands_for_enemies(_enemy_units, _player_units)
	for cmd in enemy_commands:
		if cmd.actor != null:
			_command_manager.set_command(cmd.actor.uuid, cmd)

func set_player_command(unit_uuid: String, command_type: CombatCommand.CommandType, target_uuid: String = "", skill_index: int = -1) -> bool:
	var unit := _get_unit_by_uuid(unit_uuid)
	if unit == null:
		return false
	
	var target: CombatUnit = null
	if target_uuid != "":
		target = _get_unit_by_uuid(target_uuid)
	
	var cmd := CombatCommand.new(unit, command_type, target)
	cmd.skill_index = skill_index
	
	return _command_manager.set_command(unit_uuid, cmd)

func _on_all_commands_set() -> void:
	_start_execution_phase()

func _start_execution_phase() -> void:
	turn_phase_changed.emit("execution")
	execution_phase_started.emit()
	
	var commands := _command_manager.get_commands_sorted_by_priority()
	
	for cmd in commands:
		if cmd.is_valid and not cmd.actor.is_fainted():
			_execute_command(cmd)
	
	if _check_combat_end():
		return
	
	if _current_turn >= GameConstants.MAX_TURNS:
		_end_combat(false, "战斗超过最大回合数")
		return
	
	_start_new_turn()

func _execute_command(cmd: CombatCommand) -> void:
	var action_data: Dictionary = {
		"actor_uuid": cmd.actor.uuid,
		"command_type": cmd.command_type,
		"target_uuid": cmd.target.uuid if cmd.target else ""
	}
	
	match cmd.command_type:
		CombatCommand.CommandType.ATTACK:
			_execute_attack(cmd, action_data)
		CombatCommand.CommandType.SKILL:
			_execute_skill(cmd, action_data)
		CombatCommand.CommandType.CAPTURE:
			_execute_capture(cmd, action_data)
		CombatCommand.CommandType.STEAL:
			_execute_steal(cmd, action_data)
		CombatCommand.CommandType.DEFEND:
			_execute_defend(cmd, action_data)
	
	action_executed.emit(action_data)
	EventBus.command_executed.emit(action_data)

func _execute_attack(cmd: CombatCommand, action_data: Dictionary) -> void:
	if cmd.target == null:
		return
	
	var damage_result := DamageCalculator.calculate_damage(cmd.actor, cmd.target, 10, cmd.actor.element)
	cmd.target.take_damage(damage_result.damage)
	
	action_data["damage"] = damage_result.damage
	action_data["is_critical"] = damage_result.is_critical
	action_data["element_effect"] = damage_result.element_effect
	
	_check_and_apply_weaken(cmd.actor, cmd.target)

func _execute_skill(cmd: CombatCommand, action_data: Dictionary) -> void:
	if cmd.target == null or cmd.skill_index < 0:
		return
	
	if cmd.skill_index >= cmd.actor.skills.size():
		_execute_attack(cmd, action_data)
		return
	
	var skill_id := cmd.actor.skills[cmd.skill_index]
	var skill := SkillDatabase.get_skill(skill_id) if SkillDatabase._initialized else null
	
	if skill == null:
		_execute_attack(cmd, action_data)
		return
	
	var damage_result := DamageCalculator.calculate_skill_damage(cmd.actor, cmd.target, skill)
	cmd.target.take_damage(damage_result.damage)
	
	action_data["damage"] = damage_result.damage
	action_data["is_critical"] = damage_result.is_critical
	action_data["element_effect"] = damage_result.element_effect
	action_data["skill_id"] = skill_id
	
	EventBus.skill_used.emit(cmd.actor.uuid, skill_id, cmd.target.uuid)
	_check_and_apply_weaken(cmd.actor, cmd.target)

func _execute_capture(cmd: CombatCommand, action_data: Dictionary) -> void:
	if cmd.target == null:
		return
	
	var result := CaptureManager.attempt_capture(cmd.target, _module_id)
	action_data["capture_result"] = result
	
	if result.success:
		cmd.target.take_damage(cmd.target.current_hp)

func _execute_steal(cmd: CombatCommand, action_data: Dictionary) -> void:
	if cmd.target == null:
		return
	
	var result := StealManager.attempt_steal(cmd.target, _module_id)
	action_data["steal_result"] = result

func _execute_defend(cmd: CombatCommand, action_data: Dictionary) -> void:
	cmd.actor.set_defending(true)
	action_data["is_defending"] = true

func _check_and_apply_weaken(attacker: CombatUnit, target: CombatUnit) -> void:
	if attacker.unit_type != CombatUnit.UnitType.PLAYER:
		return
	
	attacker.consecutive_attacks += 1
	
	if attacker.consecutive_attacks >= 2:
		target.apply_weaken(1)
		attacker.consecutive_attacks = 0

func _check_combat_end() -> bool:
	var player_alive := false
	for unit in _player_units:
		if not unit.is_fainted():
			player_alive = true
			break
	
	var enemy_alive := false
	for unit in _enemy_units:
		if not unit.is_fainted():
			enemy_alive = true
			break
	
	if not player_alive:
		_end_combat(false, "所有精灵都倒下了")
		return true
	
	if not enemy_alive:
		_end_combat(true, "战斗胜利")
		return true
	
	return false

func _end_combat(is_victory: bool, message: String) -> void:
	_is_active = false
	
	var result := {
		"is_victory": is_victory,
		"message": message,
		"turns": _current_turn,
		"player_units": _player_units.map(func(u): return u.to_dictionary()),
		"enemy_units": _enemy_units.map(func(u): return u.to_dictionary())
	}
	
	combat_ended.emit(result)
	EventBus.combat_ended.emit(result)
	EventBus.turn_ended.emit(_current_turn)

func _get_all_units() -> Array:
	var all: Array = []
	all.append_array(_player_units)
	all.append_array(_enemy_units)
	return all

func _get_unit_by_uuid(uuid: String) -> CombatUnit:
	for unit in _player_units:
		if unit.uuid == uuid:
			return unit
	for unit in _enemy_units:
		if unit.uuid == uuid:
			return unit
	return null

func get_player_units() -> Array:
	return _player_units.duplicate()

func get_enemy_units() -> Array:
	return _enemy_units.duplicate()

func get_current_turn() -> int:
	return _current_turn

func is_active() -> bool:
	return _is_active

func get_turn_order() -> Array:
	return _turn_order_manager.get_turn_order()

func get_pending_player_units() -> Array:
	return _command_manager.get_pending_units()
