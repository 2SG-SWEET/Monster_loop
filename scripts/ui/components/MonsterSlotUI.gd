class_name MonsterSlotUI
extends PanelContainer

signal slot_selected(slot_index: int)
signal monster_removed(slot_index: int)

var slot_index: int = 0
var monster_uuid: String = ""
var is_egg: bool = false
var monster_data: Dictionary = {}

@onready var icon_rect: TextureRect = $HBoxContainer/IconRect
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/InfoContainer/LevelLabel
@onready var state_label: Label = $HBoxContainer/InfoContainer/StateLabel
@onready var remove_button: Button = $HBoxContainer/RemoveButton
@onready var empty_label: Label = $EmptyLabel

func _ready():
	if remove_button:
		remove_button.pressed.connect(_on_remove_pressed)
	gui_input.connect(_on_gui_input)
	_show_empty_state()

func set_monster(data: Dictionary) -> void:
	monster_data = data
	monster_uuid = data.get("uuid", "")
	is_egg = false
	
	if name_label:
		name_label.text = data.get("display_name", "未知精灵")
	if level_label:
		level_label.text = "Lv.%d" % data.get("level", 1)
	
	if state_label:
		var hp_percent := float(data.get("hp", data.get("base_hp", 100))) / float(data.get("max_hp", data.get("base_hp", 100)))
		if hp_percent > 0.5:
			state_label.text = "健康"
			state_label.add_theme_color_override("font_color", Color.GREEN)
		elif hp_percent > 0:
			state_label.text = "受伤"
			state_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			state_label.text = "晕倒"
			state_label.add_theme_color_override("font_color", Color.RED)
	
	_show_monster_state()

func set_egg(data: Dictionary) -> void:
	monster_data = data
	monster_uuid = data.get("uuid", "")
	is_egg = true
	
	if name_label:
		name_label.text = "神秘蛋"
	if level_label:
		level_label.text = "孵化中"
	if state_label:
		state_label.text = "%d/%d" % [data.get("progress", 0), data.get("required_progress", 10)]
		state_label.add_theme_color_override("font_color", Color.CYAN)
	
	_show_monster_state()

func clear_slot() -> void:
	monster_uuid = ""
	is_egg = false
	monster_data = {}
	_show_empty_state()

func _show_empty_state() -> void:
	if empty_label:
		empty_label.visible = true
		empty_label.text = "点击选择精灵"
	if icon_rect:
		icon_rect.visible = false
	if name_label:
		name_label.get_parent().visible = false
	if remove_button:
		remove_button.visible = false

func _show_monster_state() -> void:
	if empty_label:
		empty_label.visible = false
	if icon_rect:
		icon_rect.visible = true
	if name_label:
		name_label.get_parent().visible = true
	if remove_button:
		remove_button.visible = true

func _on_remove_pressed() -> void:
	monster_removed.emit(slot_index)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_selected.emit(slot_index)
