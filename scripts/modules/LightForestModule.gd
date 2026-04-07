class_name LightForestModule
extends BaseTileModule

func _ready():
	super._ready()
	
	if not module_data:
		module_data = TileModuleData.new()
		module_data.module_id = "light_forest"
		module_data.display_name = "微光森林"
		module_data.description = "充满生机的森林，草系和虫系精灵出没"
		module_data.initial_charge = 3
		module_data.spawn_elements = [Enums.Element.GRASS, Enums.Element.BUG]
		module_data.spawn_weights = [50, 50]
		module_data.special_effects = {
			"fruit_drop_chance": 0.3
		}
		module_data.on_disappear_rewards = {
			"life_shard": 1
		}
		_current_charge = module_data.initial_charge

func generate_monster() -> Dictionary:
	var monster := super.generate_monster()
	monster["capture_rate"] = 0.45
	return monster

func _on_player_enter(player: Node2D) -> void:
	super._on_player_enter(player)
