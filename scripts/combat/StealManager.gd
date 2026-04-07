class_name StealManager
extends RefCounted

const STEAL_REWARDS := {
	"evolution_stone": {
		"weight": 70,
		"display_name": "进化石"
	},
	"gene_fragment": {
		"weight": 30,
		"display_name": "稀有基因碎片"
	}
}

static func calculate_steal_rate(target: CombatUnit, module_id: String = "") -> float:
	var base_rate := GameConstants.BASE_STEAL_RATE
	
	if target.is_weakened:
		base_rate += GameConstants.WEAKEN_STEAL_BONUS
	
	if module_id == "abandoned_lab":
		base_rate += GameConstants.ABANDONED_LAB_STEAL_BONUS
	
	base_rate = mini(base_rate, GameConstants.MAX_STEAL_RATE)
	
	return base_rate

static func attempt_steal(target: CombatUnit, module_id: String = "") -> Dictionary:
	var rate := calculate_steal_rate(target, module_id)
	var roll := randf()
	var success := roll < rate
	
	if success:
		var item := _select_random_item()
		SaveManager.add_item(item.id, 1)
		EventBus.item_obtained.emit(item.id, 1)
		
		return {
			"success": true,
			"steal_rate": rate,
			"roll": roll,
			"item_id": item.id,
			"item_name": item.name,
			"message": "成功偷到了 %s！" % item.name
		}
	
	return {
		"success": false,
		"steal_rate": rate,
		"roll": roll,
		"message": "偷窃失败..."
	}

static func _select_random_item() -> Dictionary:
	var total_weight := 0
	for item_id in STEAL_REWARDS:
		total_weight += STEAL_REWARDS[item_id].weight
	
	var roll := randi() % total_weight
	var current := 0
	
	for item_id in STEAL_REWARDS:
		current += STEAL_REWARDS[item_id].weight
		if roll < current:
			return {
				"id": item_id,
				"name": STEAL_REWARDS[item_id].display_name
			}
	
	return {
		"id": "evolution_stone",
		"name": "进化石"
	}
