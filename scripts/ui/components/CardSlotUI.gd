class_name CardSlotUI
extends PanelContainer

signal clicked(card_data: TileCardData)
signal double_clicked(card_data: TileCardData)

var card_data: TileCardData = null
var is_selected: bool = false
var _click_count: int = 0
var _click_timer: float = 0.0

@onready var icon_rect: TextureRect = $VBoxContainer/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var charge_label: Label = $VBoxContainer/ChargeLabel
@onready var element_icons: HBoxContainer = $VBoxContainer/ElementIcons

func _ready():
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(delta: float) -> void:
	if _click_timer > 0:
		_click_timer -= delta
		if _click_timer <= 0:
			_click_count = 0

func set_card(data: TileCardData) -> void:
	card_data = data
	
	if icon_rect and data.icon:
		icon_rect.texture = data.icon
	if name_label:
		name_label.text = data.display_name
	if charge_label:
		charge_label.text = "×%d" % data.initial_charge
	
	_update_element_icons()
	_update_rarity_border()

func _update_element_icons() -> void:
	if element_icons == null or card_data == null:
		return
	
	for child in element_icons.get_children():
		child.queue_free()
	
	for element in card_data.element_types:
		var icon := Label.new()
		icon.text = Enums.element_to_string(element)[0]
		icon.custom_minimum_size = Vector2(20, 20)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		element_icons.add_child(icon)

func _update_rarity_border() -> void:
	if card_data == null:
		return
	
	var style := StyleBoxFlat.new()
	style.border_color = card_data.get_rarity_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	add_theme_stylebox_override("panel", style)

func set_selected(selected: bool) -> void:
	is_selected = selected
	modulate = Color(1.2, 1.2, 1.2) if selected else Color.WHITE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_click_count += 1
			_click_timer = 0.3
			
			if _click_count >= 2:
				_click_count = 0
				_click_timer = 0
				if card_data != null:
					double_clicked.emit(card_data)
			else:
				await get_tree().create_timer(0.3).timeout
				if _click_count == 1 and card_data != null:
					clicked.emit(card_data)
				_click_count = 0

func _on_mouse_entered() -> void:
	if not is_selected:
		modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	if not is_selected:
		modulate = Color.WHITE
