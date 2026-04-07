class_name CommandManager
extends RefCounted

signal all_commands_set()
signal command_set(unit_uuid: String, command: CombatCommand)

var _commands: Dictionary = {}
var _pending_units: Array = []

func start_command_phase(player_units: Array) -> void:
	_commands.clear()
	_pending_units.clear()
	
	for unit in player_units:
		if unit is CombatUnit and not unit.is_fainted():
			_pending_units.append(unit)

func set_command(unit_uuid: String, command: CombatCommand) -> bool:
	if not is_unit_pending(unit_uuid):
		return false
	
	if not command.is_valid:
		return false
	
	_commands[unit_uuid] = command
	command_set.emit(unit_uuid, command)
	
	_pending_units = _pending_units.filter(func(u): return u.uuid != unit_uuid)
	
	if _pending_units.is_empty():
		all_commands_set.emit()
	
	return true

func get_command(unit_uuid: String) -> CombatCommand:
	return _commands.get(unit_uuid, null)

func get_all_commands() -> Array:
	var result: Array = []
	for cmd in _commands.values():
		result.append(cmd)
	return result

func get_commands_sorted_by_priority() -> Array:
	var commands := get_all_commands()
	commands.sort_custom(func(a, b): return a.priority > b.priority)
	return commands

func has_pending_commands() -> bool:
	return not _pending_units.is_empty()

func get_pending_units() -> Array:
	return _pending_units.duplicate()

func is_unit_pending(unit_uuid: String) -> bool:
	for unit in _pending_units:
		if unit.uuid == unit_uuid:
			return true
	return false

func auto_set_commands(ai_func: Callable) -> void:
	for unit in _pending_units:
		var cmd: CombatCommand = ai_func.call(unit)
		if cmd != null:
			set_command(unit.uuid, cmd)

func clear() -> void:
	_commands.clear()
	_pending_units.clear()
