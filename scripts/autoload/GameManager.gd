extends Node

var _current_phase: Enums.GamePhase = Enums.GamePhase.PREPARATION
var _current_loop: int = 0
var _boss_progress: int = 0
var _total_charge: int = 0
var _is_game_active: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game() -> void:
	_current_phase = Enums.GamePhase.PREPARATION
	_current_loop = 0
	_boss_progress = 0
	_total_charge = 0
	_is_game_active = true
	
	var game_state: Dictionary = SaveManager.get_data().get("game_state", {})
	game_state["current_phase"] = _current_phase
	game_state["boss_progress"] = _boss_progress
	game_state["total_charge"] = _total_charge
	SaveManager.mark_dirty()
	
	EventBus.game_phase_changed.emit(_current_phase)

func set_phase(new_phase: Enums.GamePhase) -> void:
	if _current_phase == new_phase:
		return
	
	_current_phase = new_phase
	
	var game_state: Dictionary = SaveManager.get_data().get("game_state", {})
	game_state["current_phase"] = _current_phase
	SaveManager.mark_dirty()
	
	EventBus.game_phase_changed.emit(_current_phase)

func get_current_phase() -> Enums.GamePhase:
	return _current_phase

func increment_loop() -> void:
	_current_loop += 1
	var player: Dictionary = SaveManager.get_data().get("player", {})
	player["current_loop"] = _current_loop
	SaveManager.mark_dirty()
	EventBus.loop_completed.emit(_current_loop)

func get_current_loop() -> int:
	return _current_loop

func set_total_charge(total: int) -> void:
	_total_charge = total
	var game_state: Dictionary = SaveManager.get_data().get("game_state", {})
	game_state["total_charge"] = _total_charge
	SaveManager.mark_dirty()

func update_boss_progress(charge_consumed: int) -> void:
	_boss_progress += charge_consumed
	
	var game_state: Dictionary = SaveManager.get_data().get("game_state", {})
	game_state["boss_progress"] = _boss_progress
	SaveManager.mark_dirty()
	
	EventBus.boss_progress_updated.emit(_boss_progress, _total_charge)
	
	if _boss_progress >= _total_charge and _total_charge > 0:
		trigger_boss_spawn()

func trigger_boss_spawn() -> void:
	set_phase(Enums.GamePhase.BOSS)
	var boss_data := generate_boss_data()
	EventBus.boss_spawned.emit(boss_data)

func generate_boss_data() -> Dictionary:
	var tier := SaveManager.get_player_tier()
	var base_stats := {
		"hp": 200 + tier * 50,
		"atk": 40 + tier * 8,
		"def": 30 + tier * 6,
		"spd": 25 + tier * 3
	}
	
	return {
		"uuid": "boss_%d" % Time.get_ticks_msec(),
		"display_name": "BOSS Lv.%d" % (tier + 1),
		"element": Enums.Element.FIRE,
		"level": 5 + tier * 2,
		"hp": base_stats.hp,
		"max_hp": base_stats.hp,
		"atk": base_stats.atk,
		"def": base_stats.def,
		"spd": base_stats.spd,
		"skills": ["boss_attack", "boss_skill"],
		"is_boss": true
	}

func end_game(is_victory: bool) -> void:
	_is_game_active = false
	
	if is_victory:
		SaveManager.increment_tier()
	
	set_phase(Enums.GamePhase.RESULT)
	EventBus.game_over.emit(is_victory)

func is_game_active() -> bool:
	return _is_game_active

func get_boss_progress_percent() -> float:
	if _total_charge <= 0:
		return 0.0
	return float(_boss_progress) / float(_total_charge)

func get_difficulty_multiplier() -> float:
	var tier := SaveManager.get_player_tier()
	return 1.0 + GameConstants.DIFFICULTY_SCALING * tier
