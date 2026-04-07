class_name PlayerController
extends CharacterBody2D

signal entered_tile(module_instance: BaseTileModule)

var current_module: BaseTileModule = null
var last_module_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready():
	add_to_group("player")

func _on_body_entered(body: Node2D) -> void:
	if body is BaseTileModule:
		_handle_tile_collision(body)

func _handle_tile_collision(module: BaseTileModule) -> void:
	if module._has_triggered_this_loop or module.is_consumed():
		return
	
	current_module = module
	entered_tile.emit(module)
	
	_trigger_tile_effects(module)

func _trigger_tile_effects(module: BaseTileModule) -> void:
	module._has_triggered_this_loop = true
	
	if randf() < module.trigger_combat_probability():
		_trigger_combat(module)
	else:
		module.consume_charge()

func _trigger_combat(module: BaseTileModule) -> void:
	var enemy_data := module.generate_monster()
	var tier: int = SaveManager.get_player_tier()
	
	enemy_data = _apply_tier_scaling(enemy_data, tier)
	
	EventBus.combat_triggered.emit(module.get_module_id(), enemy_data)

func _apply_tier_scaling(data: Dictionary, tier: int) -> Dictionary:
	var scaling := 1.0 + GameConstants.DIFFICULTY_SCALING * tier
	data["atk"] = int(data.get("atk", 30) * scaling)
	data["def"] = int(data.get("def", 20) * scaling)
	data["hp"] = int(data.get("hp", 100) * scaling)
	data["max_hp"] = data["hp"]
	return data

func set_visible_state(visible: bool) -> void:
	if sprite:
		sprite.visible = visible
	if collision:
		collision.disabled = not visible
