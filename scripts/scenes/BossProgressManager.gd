class_name BossProgressManager
extends RefCounted

signal progress_updated(current: int, total: int)
signal progress_completed

var _current_progress: int = 0
var _total_charge: int = 0

func initialize() -> void:
	_current_progress = 0
	_total_charge = 0

func set_total_charge(total: int) -> void:
	_total_charge = total
	_current_progress = 0
	progress_updated.emit(_current_progress, _total_charge)

func add_total_charge(charge: int) -> void:
	_total_charge += charge
	progress_updated.emit(_current_progress, _total_charge)

func update_progress(charge_consumed: int) -> void:
	_current_progress += charge_consumed
	
	progress_updated.emit(_current_progress, _total_charge)
	
	if _current_progress >= _total_charge and _total_charge > 0:
		progress_completed.emit()

func get_progress_percent() -> float:
	if _total_charge <= 0:
		return 0.0
	return float(_current_progress) / float(_total_charge)

func get_current_progress() -> int:
	return _current_progress

func get_total_charge() -> int:
	return _total_charge

func reset() -> void:
	_current_progress = 0
	_total_charge = 0
