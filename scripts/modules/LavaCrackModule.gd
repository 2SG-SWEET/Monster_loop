class_name LavaCrackModule
extends BaseTileModule

func _ready():
	super._ready()
	
	if not module_data:
		module_data = TileModuleData.new()
		module_data.module_id = "lava_crack"
		module_data.display_name = "熔岩裂隙"
		module_data.description = "炽热的熔岩地带，火系精灵出没"
		module_data.initial_charge = 5
		module_data.spawn_elements = [Enums.Element.FIRE]
		module_data.spawn_weights = [100]
		module_data.special_effects = {
			"atk_bonus_per_loop": 5
		}
		module_data.on_disappear_rewards = {
			"core_fire": 1
		}
		_current_charge = module_data.initial_charge

func generate_monster() -> Dictionary:
	var monster := super.generate_monster()
	monster["capture_rate"] = 0.40
	monster["atk"] = int(monster.get("atk", 25) * 1.1)
	return monster

func get_special_effect() -> Dictionary:
	var effects := super.get_special_effect()
	effects["atk_bonus_per_loop"] = 5
	return effects

func _on_player_enter(player: Node2D) -> void:
	super._on_player_enter(player)
