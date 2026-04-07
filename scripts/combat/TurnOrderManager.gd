class_name TurnOrderManager
extends RefCounted

signal turn_order_changed(order: Array)
signal current_unit_changed(unit: CombatUnit)

var _turn_order: Array = []
var _current_index: int = 0

func calculate_turn_order(all_units: Array) -> Array:
	var active_units: Array = []
	
	for unit in all_units:
		if unit is CombatUnit and not unit.is_fainted():
			active_units.append(unit)
	
	active_units.sort_custom(_compare_by_speed)
	
	_turn_order = active_units
	_current_index = 0
	
	turn_order_changed.emit(_turn_order)
	
	return _turn_order

func _compare_by_speed(a: CombatUnit, b: CombatUnit) -> bool:
	var spd_a := a.get_effective_spd()
	var spd_b := b.get_effective_spd()
	
	if spd_a != spd_b:
		return spd_a > spd_b
	
	return randf() > 0.5

func get_current_unit() -> CombatUnit:
	if _turn_order.is_empty() or _current_index >= _turn_order.size():
		return null
	return _turn_order[_current_index]

func advance_to_next() -> CombatUnit:
	_current_index += 1
	
	while _current_index < _turn_order.size():
		var unit: CombatUnit = _turn_order[_current_index]
		if not unit.is_fainted():
			current_unit_changed.emit(unit)
			return unit
		_current_index += 1
	
	return null

func is_turn_complete() -> bool:
	return _current_index >= _turn_order.size()

func get_remaining_units() -> Array:
	var remaining: Array = []
	for i in range(_current_index, _turn_order.size()):
		var unit: CombatUnit = _turn_order[i]
		if not unit.is_fainted():
			remaining.append(unit)
	return remaining

func get_turn_order() -> Array:
	return _turn_order.duplicate()

func reset() -> void:
	_turn_order.clear()
	_current_index = 0
