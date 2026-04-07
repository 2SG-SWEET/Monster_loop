class_name GameSceneManager
extends Node

signal loop_completed(loop_count: int)
signal all_tiles_consumed
signal boss_spawn_requested

@export var path_radius: float = GameConstants.PATH_RADIUS
@export var grid_count: int = GameConstants.MAX_GRID_SLOTS
@export var move_speed: float = GameConstants.MOVE_SPEED

var current_loop_count: int = 0
var is_game_active: bool = false
var is_boss_spawned: bool = false
var grid_slots: Array = []

var _loop_path: Path2D
var _player_follow: PathFollow2D
var _tile_container: Node2D
var _boss_spawn_point: Marker2D

func initialize(path: Path2D, follow: PathFollow2D, container: Node2D, spawn_point: Marker2D) -> void:
	_loop_path = path
	_player_follow = follow
	_tile_container = container
	_boss_spawn_point = spawn_point
	
	_initialize_grid_slots()
	_connect_event_bus()
	_load_deck_to_hand()

func _initialize_grid_slots() -> void:
	if _loop_path == null or _loop_path.curve == null:
		return
	
	var curve := _loop_path.curve
	var baked_points := curve.get_baked_points()
	
	grid_slots.clear()
	
	for i in range(grid_count):
		var t := float(i) / float(grid_count)
		var pos := curve.sample_baked(t * curve.get_baked_length())
		
		var slot := GridSlot.new(i, pos)
		grid_slots.append(slot)

func _connect_event_bus() -> void:
	EventBus.tile_placed.connect(_on_tile_placed)
	EventBus.tile_consumed.connect(_on_tile_consumed)
	EventBus.combat_triggered.connect(_on_combat_triggered)
	EventBus.boss_spawned.connect(_on_boss_spawned)

func update(delta: float) -> void:
	if not is_game_active or is_boss_spawned:
		return
	
	_update_player_movement(delta)

func _update_player_movement(delta: float) -> void:
	if _loop_path == null or _player_follow == null:
		return
	
	var path_length := _loop_path.curve.get_baked_length()
	var move_distance := move_speed * delta
	
	_player_follow.progress += move_distance
	
	if _player_follow.progress >= path_length:
		_player_follow.progress = 0.0
		_on_loop_completed()

func _on_loop_completed() -> void:
	current_loop_count += 1
	loop_completed.emit(current_loop_count)
	EventBus.loop_completed.emit(current_loop_count)
	
	_reset_tile_triggers()
	_update_egg_progress()

func _reset_tile_triggers() -> void:
	for slot in grid_slots:
		if slot.has_module():
			slot.module_instance.reset_loop_trigger()

func _update_egg_progress() -> void:
	var eggs: Array = SaveManager.get_data().get("eggs", [])
	var hatched: Array = []
	
	for egg in eggs:
		egg.progress = egg.get("progress", 0) + 1
		if egg.progress >= egg.get("required_progress", 10):
			hatched.append(egg)
			_hatch_egg(egg)
	
	for egg in hatched:
		eggs.erase(egg)
	
	SaveManager.mark_dirty()

func _hatch_egg(egg: Dictionary) -> void:
	var elements := [Enums.Element.FIRE, Enums.Element.WATER, Enums.Element.GRASS,
					Enums.Element.ELECTRIC, Enums.Element.BUG]
	var random_element: Enums.Element = elements[randi() % elements.size()]
	
	var new_monster := {
		"uuid": "monster_%s" % str(Time.get_ticks_msec()),
		"display_name": _get_monster_name_by_element(random_element),
		"species": "%s_slime" % Enums.element_to_string(random_element).to_lower(),
		"element": random_element,
		"level": 5,
		"base_hp": 100,
		"base_atk": 30,
		"base_def": 20,
		"base_spd": 20,
		"skills": ["tackle", _get_element_skill(random_element)],
		"traits": []
	}
	
	SaveManager.add_monster(new_monster)
	EventBus.monster_captured.emit(new_monster)

func _get_monster_name_by_element(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "火史莱姆"
		Enums.Element.WATER: return "水精灵"
		Enums.Element.GRASS: return "草苗龟"
		Enums.Element.ELECTRIC: return "电击兽"
		Enums.Element.BUG: return "虫宝宝"
	return "未知精灵"

func _get_element_skill(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "fireball"
		Enums.Element.WATER: return "water_jet"
		Enums.Element.GRASS: return "vine_whip"
		Enums.Element.ELECTRIC: return "thunder_shock"
		Enums.Element.BUG: return "bug_bite"
	return "tackle"

func _on_tile_placed(module_id: String, grid_index: int) -> void:
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot: GridSlot = grid_slots[grid_index]
	if slot.is_occupied:
		return
	
	var module_instance := TileModuleFactory.create_module(module_id)
	if module_instance == null:
		return
	
	module_instance.position = slot.position
	module_instance.initialize(module_instance.module_data, grid_index)
	_tile_container.add_child(module_instance)
	
	slot.set_module(module_instance)
	
	BossProgressManager.add_total_charge(module_instance.get_charge())

func _on_tile_consumed(module_id: String, grid_index: int, remaining_charge: int) -> void:
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot: GridSlot = grid_slots[grid_index]
	
	if remaining_charge <= 0 and slot.has_module():
		slot.module_instance.queue_free()
		slot.clear_module()
		_spawn_wasteland(slot.position)
	
	_check_all_tiles_consumed()

func _spawn_wasteland(pos: Vector2) -> void:
	var wasteland := Node2D.new()
	wasteland.position = pos
	wasteland.set_meta("is_wasteland", true)
	_tile_container.add_child(wasteland)

func _check_all_tiles_consumed() -> void:
	for slot in grid_slots:
		if slot.has_module() and slot.get_charge() > 0:
			return
	
	all_tiles_consumed.emit()
	_spawn_boss()

func _spawn_boss() -> void:
	if is_boss_spawned:
		return
	
	is_boss_spawned = true
	is_game_active = false
	
	var boss_data := GameManager.generate_boss_data()
	EventBus.boss_spawned.emit(boss_data)
	boss_spawn_requested.emit()

func _on_combat_triggered(_module_id: String, _enemy_data: Dictionary) -> void:
	is_game_active = false

func _on_boss_spawned(_boss_data: Dictionary) -> void:
	pass

func _load_deck_to_hand() -> void:
	var deck_data: Dictionary = SaveManager.get_data().get("deck", {})
	var cards: Array = deck_data.get("cards", [])
	
	var hand_cards: Array = []
	for card_entry in cards:
		var module_id: String = card_entry.get("module_id", "")
		var count: int = card_entry.get("count", 1)
		for i in count:
			hand_cards.append(module_id)
	
	HandUIManager.set_hand_cards(hand_cards)

func start_game() -> void:
	is_game_active = true
	is_boss_spawned = false
	current_loop_count = 0

func pause_game() -> void:
	is_game_active = false

func resume_game() -> void:
	if not is_boss_spawned:
		is_game_active = true

func get_player_position() -> Vector2:
	if _player_follow:
		return _player_follow.global_position
	return Vector2.ZERO

func get_grid_slot_at_index(index: int) -> GridSlot:
	if index >= 0 and index < grid_slots.size():
		return grid_slots[index]
	return null

func get_nearest_empty_slot() -> int:
	if _player_follow == null:
		return -1
	
	var player_pos := _player_follow.global_position
	var nearest_index := -1
	var nearest_distance := INF
	
	for i in range(grid_slots.size()):
		var slot: GridSlot = grid_slots[i]
		if not slot.is_occupied:
			var distance := slot.position.distance_to(player_pos)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_index = i
	
	return nearest_index
