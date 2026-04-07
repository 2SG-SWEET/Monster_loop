class_name AbandonedLabModule
extends BaseTileModule

func _ready():
	super._ready()
	
	if not module_data:
		module_data = TileModuleData.new()
		module_data.module_id = "abandoned_lab"
		module_data.display_name = "废弃研究所"
		module_data.description = "废弃的研究设施，电系和钢系精灵出没"
		module_data.initial_charge = 2
		module_data.spawn_elements = [Enums.Element.ELECTRIC, Enums.Element.STEEL]
		module_data.spawn_weights = [50, 50]
		module_data.special_effects = {
			"steal_bonus": 0.2
		}
		module_data.on_disappear_rewards = {
			"tech_module": 1
		}
		_current_charge = module_data.initial_charge

func generate_monster() -> Dictionary:
	var monster := super.generate_monster()
	monster["capture_rate"] = 0.35
	return monster

func get_special_effect() -> Dictionary:
	var effects := super.get_special_effect()
	effects["steal_bonus"] = GameConstants.ABANDONED_LAB_STEAL_BONUS
	return effects

func _on_player_enter(player: Node2D) -> void:
	super._on_player_enter(player)
