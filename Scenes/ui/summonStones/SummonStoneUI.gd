class_name SummonStoneUI
extends Control

signal stone_slot_clicked(slot: int, position: Vector2)

@onready var slot_containers: Array[Control] = []
@onready var cooldown_overlays: Array[Control] = []
@onready var progress_indicators: Array[TextureProgressBar] = []

var summon_system: Node

func _ready():
	setup_ui()
	find_summon_system()
	connect_signals()

func setup_ui():
	# Create 3 horizontal slots for WOW-style layout
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hbox.position = Vector2(50, -100)
	add_child(hbox)
	
	for i in range(3):
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(64, 64)
		slot_panel.add_theme_stylebox_override("panel", create_slot_style())
		hbox.add_child(slot_panel)
		slot_containers.append(slot_panel)
		
		# Add icon texture rect
		var icon_rect = TextureRect.new()
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		slot_panel.add_child(icon_rect)
		
		# Add progress bar for cooldown (circular)
		var progress = TextureProgressBar.new()
		progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		progress.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		progress.value = 100
		progress.modulate = Color(1, 1, 1, 0.8)
		slot_panel.add_child(progress)
		progress_indicators.append(progress)
		
		# Add cooldown text overlay
		var cooldown_label = Label.new()
		cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown_label.add_theme_font_size_override("font_size", 12)
		cooldown_label.modulate = Color.YELLOW
		cooldown_label.visible = false
		slot_panel.add_child(cooldown_label)
		cooldown_overlays.append(cooldown_label)
		
		# Connect click signal
		slot_panel.gui_input.connect(_on_slot_clicked.bind(i))

func create_slot_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func find_summon_system():
	summon_system = get_tree().current_scene.get_node_or_null("SummonStoneSystem")

func connect_signals():
	if summon_system:
		summon_system.summon_stone_equipped.connect(_on_stone_equipped)
		summon_system.summon_stone_cooldown_updated.connect(_on_cooldown_updated)

func _on_slot_clicked(slot: int, event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var global_pos = get_global_mouse_position()
			if summon_system:
				summon_system.activate_summon_stone(slot, global_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click to open stone selection
			stone_slot_clicked.emit(slot, get_global_mouse_position())

func _on_stone_equipped(slot: int, stone_id: String):
	if slot >= 0 and slot < slot_containers.size():
		var slot_panel = slot_containers[slot]
		var icon_rect = slot_panel.get_child(0) as TextureRect
		
		if stone_id != "" and Data.summon_stones.has(stone_id):
			var stone_data = Data.summon_stones[stone_id]
			var icon_path = stone_data.get("icon") if stone_data.has("icon") else ""
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon_rect.texture = load(icon_path)
			
			# Update tooltip
			var name_text = stone_data.get("name") if stone_data.has("name") else "Unknown"
			var desc_text = stone_data.get("description") if stone_data.has("description") else ""
			var cooldown_text = stone_data.get("cooldown") if stone_data.has("cooldown") else 0
			slot_panel.tooltip_text = "%s\n%s\nCD: %.0fs" % [
				name_text,
				desc_text,
				cooldown_text
			]
		else:
			icon_rect.texture = null
			slot_panel.tooltip_text = "Empty Slot"

func _on_cooldown_updated(slot: int, remaining_time: float):
	if slot >= 0 and slot < progress_indicators.size():
		var progress = progress_indicators[slot]
		var overlay = cooldown_overlays[slot] as Label
		
		if remaining_time > 0:
			var stone_id = summon_system.equipped_stones[slot]
			if stone_id != "" and Data.summon_stones.has(stone_id):
				var max_cooldown = Data.summon_stones[stone_id].cooldown
				var ratio = remaining_time / max_cooldown
				progress.value = (1.0 - ratio) * 100
				overlay.text = "%.1f" % remaining_time
				overlay.visible = true
		else:
			progress.value = 100
			overlay.visible = false
