class_name DeckSlotUI
extends PanelContainer

signal slot_clicked(slot_index: int)
signal slot_cleared(slot_index: int)

var slot_index: int = 0
var module_id: String = ""
var count: int = 0
var card_data: TileCardData = null

@onready var icon_rect: TextureRect = $HBoxContainer/IconRect
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var count_label: Label = $HBoxContainer/InfoContainer/CountLabel
@onready var remove_button: Button = $HBoxContainer/RemoveButton

func _ready():
	if remove_button:
		remove_button.pressed.connect(_on_remove_pressed)
	gui_input.connect(_on_gui_input)

func set_card(data: TileCardData, card_count: int) -> void:
	card_data = data
	module_id = data.module_id
	count = card_count
	
	if icon_rect and data.icon:
		icon_rect.texture = data.icon
	if name_label:
		name_label.text = data.display_name
	if count_label:
		count_label.text = "×%d" % count
	
	visible = true

func clear_slot() -> void:
	card_data = null
	module_id = ""
	count = 0
	
	if icon_rect:
		icon_rect.texture = null
	if name_label:
		name_label.text = "空槽位"
	if count_label:
		count_label.text = ""
	
	visible = false

func increment() -> bool:
	if count >= 5:
		return false
	count += 1
	if count_label:
		count_label.text = "×%d" % count
	return true

func decrement() -> bool:
	if count <= 0:
		return false
	count -= 1
	if count <= 0:
		clear_slot()
	elif count_label:
		count_label.text = "×%d" % count
	return true

func _on_remove_pressed() -> void:
	slot_cleared.emit(slot_index)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(slot_index)
