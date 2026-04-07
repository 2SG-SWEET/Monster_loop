class_name CombatScene
extends Node

@onready var _player_units_container: HBoxContainer = $UI/BattleUI/PlayerUnits
@onready var _enemy_units_container: HBoxContainer = $UI/BattleUI/EnemyUnits
@onready var _action_panel: Control = $UI/BattleUI/ActionPanel
@onready var _turn_order_panel: HBoxContainer = $UI/BattleUI/TurnOrderPanel
@onready var _message_label: Label = $UI/BattleUI/MessageLabel

var _combat_manager: CombatManager = null
var _selected_unit: CombatUnit = null
var _selected_target: CombatUnit = null

func _ready():
	_combat_manager = CombatManager.new()
	_combat_manager.combat_started.connect(_on_combat_started)
	_combat_manager.turn_started.connect(_on_turn_started)
	_combat_manager.command_phase_started.connect(_on_command_phase_started)
	_combat_manager.action_executed.connect(_on_action_executed)
	_combat_manager.combat_ended.connect(_on_combat_ended)
	
	_setup_test_combat()

func _setup_test_combat() -> void:
	var player_data := [
		{
			"uuid": "player_1",
			"display_name": "初始精灵",
			"element": Enums.Element.FIRE,
			"level": 5,
			"hp": 100,
			"atk": 30,
			"def": 20,
			"spd": 20,
			"skills": ["tackle", "fireball"],
			"is_player": true
		}
	]
	
	var enemy_data := {
		"uuid": "enemy_1",
		"display_name": "野生精灵",
		"element": Enums.Element.GRASS,
		"level": 3,
		"hp": 80,
		"atk": 25,
		"def": 15,
		"spd": 18,
		"skills": ["tackle", "vine_whip"]
	}
	
	_combat_manager.start_combat(player_data, enemy_data, "light_forest")

func _on_combat_started() -> void:
	_update_units_display()
	_show_message("战斗开始！")

func _on_turn_started(turn_number: int) -> void:
	_show_message("第 %d 回合" % turn_number)
	_update_turn_order_display()

func _on_command_phase_started() -> void:
	var pending := _combat_manager.get_pending_player_units()
	if not pending.is_empty():
		_selected_unit = pending[0]
		_show_unit_actions(_selected_unit)
	else:
		_show_message("等待执行...")

func _on_action_executed(action_data: Dictionary) -> void:
	_update_units_display()
	
	var msg := _format_action_message(action_data)
	_show_message(msg)
	
	await get_tree().create_timer(0.5).timeout

func _on_combat_ended(result: Dictionary) -> void:
	if result.is_victory:
		_show_message("战斗胜利！")
	else:
		_show_message("战斗失败...")
	
	await get_tree().create_timer(2.0).timeout
	
	EventBus.combat_ended.emit(result)

func _update_units_display() -> void:
	_clear_container(_player_units_container)
	_clear_container(_enemy_units_container)
	
	for unit in _combat_manager.get_player_units():
		var display := _create_unit_display(unit)
		_player_units_container.add_child(display)
	
	for unit in _combat_manager.get_enemy_units():
		var display := _create_unit_display(unit)
		display.gui_input.connect(_on_enemy_unit_clicked.bind(unit))
		_enemy_units_container.add_child(display)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _create_unit_display(unit: CombatUnit) -> Control:
	var vbox := VBoxContainer.new()
	
	var name_label := Label.new()
	name_label.text = unit.display_name
	vbox.add_child(name_label)
	
	var hp_label := Label.new()
	hp_label.text = "HP: %d/%d" % [unit.current_hp, unit.max_hp]
	vbox.add_child(hp_label)
	
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	hp_bar.custom_minimum_size = Vector2(100, 10)
	vbox.add_child(hp_bar)
	
	if unit.is_fainted():
		vbox.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	vbox.set_meta("unit_uuid", unit.uuid)
	return vbox

func _update_turn_order_display() -> void:
	_clear_container(_turn_order_panel)
	
	var order := _combat_manager.get_turn_order()
	for unit in order:
		var icon := Label.new()
		icon.text = unit.display_name[0]
		icon.custom_minimum_size = Vector2(30, 30)
		_turn_order_panel.add_child(icon)

func _show_unit_actions(unit: CombatUnit) -> void:
	_clear_container(_action_panel)
	
	var attack_btn := Button.new()
	attack_btn.text = "攻击"
	attack_btn.pressed.connect(_on_attack_pressed)
	_action_panel.add_child(attack_btn)
	
	if not unit.skills.is_empty():
		for i in range(mini(2, unit.skills.size())):
			var skill_id := unit.skills[i]
			var skill := SkillDatabase.get_skill(skill_id)
			if skill:
				var skill_btn := Button.new()
				skill_btn.text = skill.display_name
				skill_btn.pressed.connect(_on_skill_pressed.bind(i))
				_action_panel.add_child(skill_btn)
	
	var capture_btn := Button.new()
	capture_btn.text = "捕获"
	capture_btn.pressed.connect(_on_capture_pressed)
	_action_panel.add_child(capture_btn)
	
	var steal_btn := Button.new()
	steal_btn.text = "偷窃"
	steal_btn.pressed.connect(_on_steal_pressed)
	_action_panel.add_child(steal_btn)
	
	var defend_btn := Button.new()
	defend_btn.text = "防御"
	defend_btn.pressed.connect(_on_defend_pressed)
	_action_panel.add_child(defend_btn)

func _on_enemy_unit_clicked(event: InputEvent, unit: CombatUnit) -> void:
	if event is InputEventMouseButton and event.pressed:
		_selected_target = unit

func _on_attack_pressed() -> void:
	if _selected_unit == null:
		return
	
	if _selected_target == null:
		var enemies := _combat_manager.get_enemy_units()
		for e in enemies:
			if not e.is_fainted():
				_selected_target = e
				break
	
	if _selected_target != null:
		_combat_manager.set_player_command(
			_selected_unit.uuid,
			CombatCommand.CommandType.ATTACK,
			_selected_target.uuid
		)
		_advance_to_next_unit()

func _on_skill_pressed(skill_index: int) -> void:
	if _selected_unit == null:
		return
	
	if _selected_target == null:
		var enemies := _combat_manager.get_enemy_units()
		for e in enemies:
			if not e.is_fainted():
				_selected_target = e
				break
	
	if _selected_target != null:
		_combat_manager.set_player_command(
			_selected_unit.uuid,
			CombatCommand.CommandType.SKILL,
			_selected_target.uuid,
			skill_index
		)
		_advance_to_next_unit()

func _on_capture_pressed() -> void:
	if _selected_unit == null:
		return
	
	if _selected_target == null:
		var enemies := _combat_manager.get_enemy_units()
		for e in enemies:
			if not e.is_fainted():
				_selected_target = e
				break
	
	if _selected_target != null:
		_combat_manager.set_player_command(
			_selected_unit.uuid,
			CombatCommand.CommandType.CAPTURE,
			_selected_target.uuid
		)
		_advance_to_next_unit()

func _on_steal_pressed() -> void:
	if _selected_unit == null:
		return
	
	if _selected_target == null:
		var enemies := _combat_manager.get_enemy_units()
		for e in enemies:
			if not e.is_fainted():
				_selected_target = e
				break
	
	if _selected_target != null:
		_combat_manager.set_player_command(
			_selected_unit.uuid,
			CombatCommand.CommandType.STEAL,
			_selected_target.uuid
		)
		_advance_to_next_unit()

func _on_defend_pressed() -> void:
	if _selected_unit == null:
		return
	
	_combat_manager.set_player_command(
		_selected_unit.uuid,
		CombatCommand.CommandType.DEFEND
	)
	_advance_to_next_unit()

func _advance_to_next_unit() -> void:
	var pending := _combat_manager.get_pending_player_units()
	if not pending.is_empty():
		_selected_unit = pending[0]
		_selected_target = null
		_show_unit_actions(_selected_unit)
	else:
		_clear_container(_action_panel)
		_show_message("执行中...")

func _show_message(text: String) -> void:
	if _message_label:
		_message_label.text = text

func _format_action_message(action_data: Dictionary) -> String:
	var actor_uuid: String = action_data.get("actor_uuid", "")
	var cmd_type: int = action_data.get("command_type", 0)
	
	var actor := _combat_manager._get_unit_by_uuid(actor_uuid) if _combat_manager else null
	var actor_name := actor.display_name if actor else "未知"
	
	match cmd_type:
		CombatCommand.CommandType.ATTACK:
			var damage: int = action_data.get("damage", 0)
			return "%s 攻击造成 %d 伤害！" % [actor_name, damage]
		CombatCommand.CommandType.SKILL:
			var damage: int = action_data.get("damage", 0)
			return "%s 使用技能造成 %d 伤害！" % [actor_name, damage]
		CombatCommand.CommandType.CAPTURE:
			var result: Dictionary = action_data.get("capture_result", {})
			if result.get("success", false):
				return "成功捕获！"
			return "捕获失败..."
		CombatCommand.CommandType.STEAL:
			var result: Dictionary = action_data.get("steal_result", {})
			if result.get("success", false):
				return "偷到了 %s！" % result.get("item_name", "道具")
			return "偷窃失败..."
		CombatCommand.CommandType.DEFEND:
			return "%s 进入防御姿态！" % actor_name
	
	return ""
