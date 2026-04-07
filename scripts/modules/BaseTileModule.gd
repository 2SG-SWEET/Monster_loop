class_name BaseTileModule
extends Area2D

signal tile_disappeared(module_id: String, grid_index: int)
signal special_effect_triggered(effect_data: Dictionary)

@export var module_data: TileModuleData

var _current_charge: int = 0
var _grid_index: int = -1
var _has_triggered_this_loop: bool = false
var _is_consumed: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	if module_data:
		_current_charge = module_data.initial_charge

func initialize(data: TileModuleData, grid_idx: int) -> void:
	module_data = data
	_grid_index = grid_idx
	_current_charge = data.initial_charge
	_has_triggered_this_loop = false
	_is_consumed = false

func get_charge() -> int:
	return _current_charge

func consume_charge() -> int:
	if _current_charge <= 0:
		return 0
	
	_current_charge -= 1
	EventBus.tile_consumed.emit(module_data.module_id, _grid_index, _current_charge)
	GameManager.update_boss_progress(1)
	
	if _current_charge <= 0:
		_on_disappear()
	
	return _current_charge

func trigger_combat_probability() -> float:
	return GameConstants.COMBAT_PROBABILITY

func generate_monster() -> Dictionary:
	if not module_data:
		return {}
	
	var element := module_data.get_random_spawn_element()
	var monster := MonsterDatabase.get_monster_by_element(element)
	
	if monster == null:
		monster = MonsterDatabase.get_random_monster(true)
	
	if monster == null:
		return {}
	
	var tier := SaveManager.get_player_tier()
	var level := randi_range(1, 3) + tier
	var diff_mult := GameManager.get_difficulty_multiplier()
	
	var instance := MonsterDatabase.create_instance(monster.monster_id, level)
	instance.hp = int(instance.hp * diff_mult)
	instance.max_hp = int(instance.max_hp * diff_mult)
	instance.atk = int(instance.atk * diff_mult)
	instance.def = int(instance.def * diff_mult)
	instance.module_id = module_data.module_id
	
	return instance

func get_special_effect() -> Dictionary:
	if not module_data:
		return {}
	return module_data.special_effects

func _on_disappear() -> void:
	_is_consumed = true
	
	var rewards := module_data.on_disappear_rewards if module_data else {}
	for item_id in rewards:
		var count: int = rewards[item_id]
		SaveManager.add_item(item_id, count)
		EventBus.item_obtained.emit(item_id, count)
	
	EventBus.tile_disappeared.emit(module_data.module_id if module_data else "", _grid_index)
	tile_disappeared.emit(module_data.module_id if module_data else "", _grid_index)
	
	queue_free()

func get_module_id() -> String:
	return module_data.module_id if module_data else ""

func get_display_name() -> String:
	return module_data.display_name if module_data else ""

func get_grid_index() -> int:
	return _grid_index

func reset_loop_trigger() -> void:
	_has_triggered_this_loop = false

func is_consumed() -> bool:
	return _is_consumed

func _on_body_entered(body: Node2D) -> void:
	if _has_triggered_this_loop or _is_consumed:
		return
	
	if body.is_in_group("player"):
		_has_triggered_this_loop = true
		_on_player_enter(body)

func _on_player_enter(_player: Node2D) -> void:
	if randf() < trigger_combat_probability():
		var enemy_data := generate_monster()
		EventBus.combat_triggered.emit(module_data.module_id if module_data else "", enemy_data)
	else:
		consume_charge()

func _get_monster_name_by_element(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "火史莱姆"
		Enums.Element.WATER: return "水精灵"
		Enums.Element.GRASS: return "草苗龟"
		Enums.Element.ELECTRIC: return "电击兽"
		Enums.Element.BUG: return "虫宝宝"
		Enums.Element.STEEL: return "钢铁侠"
	return "未知精灵"

func _get_skill_by_element(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "fireball"
		Enums.Element.WATER: return "water_jet"
		Enums.Element.GRASS: return "vine_whip"
		Enums.Element.ELECTRIC: return "thunder_shock"
		Enums.Element.BUG: return "bug_bite"
		Enums.Element.STEEL: return "iron_defense"
	return "tackle"
