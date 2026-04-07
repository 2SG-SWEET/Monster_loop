class_name Main
extends Node

@onready var _scene_container: Node = $SceneContainer

var _current_scene: Node = null
var _combat_manager: CombatManager = null

func _ready():
	SkillDatabase.initialize()
	MonsterDatabase.initialize()
	
	EventBus.game_phase_changed.connect(_on_game_phase_changed)
	EventBus.combat_triggered.connect(_on_combat_triggered)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.game_over.connect(_on_game_over)
	
	_load_scene(Enums.GamePhase.PREPARATION)

func _on_game_phase_changed(new_phase: Enums.GamePhase) -> void:
	print("游戏阶段变更: %d" % new_phase)
	if new_phase == Enums.GamePhase.RESULT:
		return
	
	_load_scene(new_phase)

func _load_scene(phase: Enums.GamePhase) -> void:
	print("加载场景，阶段: %d" % phase)
	
	if _current_scene != null:
		print("释放当前场景")
		_current_scene.queue_free()
		_current_scene = null
	
	var scene_path := _get_scene_path_by_phase(phase)
	print("场景路径: %s" % scene_path)
	
	if not ResourceLoader.exists(scene_path):
		push_warning("Scene not found: %s" % scene_path)
		return
	
	var scene := load(scene_path) as PackedScene
	_current_scene = scene.instantiate()
	_scene_container.add_child(_current_scene)
	print("场景加载完成")

func _get_scene_path_by_phase(phase: Enums.GamePhase) -> String:
	match phase:
		Enums.GamePhase.PREPARATION:
			return "res://scenes/preparation/PreparationScene.tscn"
		Enums.GamePhase.EXPLORATION:
			return "res://scenes/game/GameScene.tscn"
		Enums.GamePhase.COMBAT:
			return "res://scenes/combat/CombatScene.tscn"
		Enums.GamePhase.BOSS:
			return "res://scenes/combat/CombatScene.tscn"
		Enums.GamePhase.RESULT:
			return "res://scenes/main/ResultScene.tscn"
	return ""

func _on_combat_triggered(module_id: String, enemy_data: Dictionary) -> void:
	GameManager.set_phase(Enums.GamePhase.COMBAT)
	
	await get_tree().create_timer(0.1).timeout
	
	if _combat_manager == null:
		_combat_manager = CombatManager.new()
		_combat_manager.combat_ended.connect(_on_combat_manager_ended)
	
	var player_monsters := SaveManager.get_selected_monsters()
	if player_monsters.is_empty():
		player_monsters = SaveManager.get_player_monsters()
	
	_combat_manager.start_combat(player_monsters, enemy_data, module_id)

func _on_combat_ended(result: Dictionary) -> void:
	if _combat_manager != null:
		_combat_manager = null

func _on_combat_manager_ended(result: Dictionary) -> void:
	if result.is_victory:
		if GameManager.get_current_phase() == Enums.GamePhase.BOSS:
			GameManager.end_game(true)
		else:
			GameManager.set_phase(Enums.GamePhase.EXPLORATION)
	else:
		GameManager.end_game(false)

func _on_game_over(is_victory: bool) -> void:
	_load_scene(Enums.GamePhase.RESULT)
