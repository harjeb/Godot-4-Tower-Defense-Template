class_name TowerTechUI
extends Control

signal tower_tech_closed()

var tower_tech_system: TowerTechSystem
var tech_point_system: TechPointSystem
var current_tower_type: String = ""
var tech_buttons: Dictionary = {}

func _ready():
	find_systems()
	setup_ui()
	if tower_tech_system:
		tower_tech_system.tower_tech_unlocked.connect(_on_tech_unlocked)

func find_systems():
	tower_tech_system = get_tree().current_scene.get_node_or_null("TowerTechSystem")
	tech_point_system = get_tree().current_scene.get_node_or_null("TechPointSystem")

func setup_ui():
	# Create main container
	var bg_panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 15)
	bg_panel.add_child(main_vbox)
	
	# Header
	create_header(main_vbox)
	
	# Tower selection tabs
	create_tower_tabs(main_vbox)
	
	# Tech tree display
	create_tech_tree_display(main_vbox)

func create_header(parent: VBoxContainer):
	var header_hbox = HBoxContainer.new()
	parent.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "塔科技树"
	title.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	# Tech points display
	var points_label = Label.new()
	points_label.text = "科技点: 0"
	points_label.add_theme_font_size_override("font_size", 18)
	points_label.name = "TechPointsLabel"
	header_hbox.add_child(points_label)
	
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(80, 35)
	close_button.pressed.connect(_on_close_button_pressed)
	header_hbox.add_child(close_button)

func create_tower_tabs(parent: VBoxContainer):
	var tab_hbox = HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 5)
	parent.add_child(tab_hbox)
	
	for tower_type in Data.tower_tech_tree.keys():
		var tower_data = Data.tower_tech_tree[tower_type]
		var tab_button = Button.new()
		tab_button.text = tower_data.name
		tab_button.toggle_mode = true
		tab_button.custom_minimum_size = Vector2(120, 40)
		tab_button.pressed.connect(_on_tower_tab_pressed.bind(tower_type))
		tab_hbox.add_child(tab_button)
		
		# Set first tab as default
		if current_tower_type == "":
			current_tower_type = tower_type
			tab_button.button_pressed = true

func create_tech_tree_display(parent: VBoxContainer):
	# Scrollable area for tech tree
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.name = "TechTreeScroll"
	parent.add_child(scroll_container)
	
	var tech_tree_container = Control.new()
	tech_tree_container.custom_minimum_size = Vector2(800, 600)
	tech_tree_container.name = "TechTreeContainer"
	scroll_container.add_child(tech_tree_container)
	
	update_tech_tree_display()

func update_tech_tree_display():
	var container = get_node_or_null("Panel/VBoxContainer/TechTreeScroll/TechTreeContainer")
	if not container:
		return
	
	# Clear existing content
	for child in container.get_children():
		child.queue_free()
	
	tech_buttons.clear()
	
	if current_tower_type == "":
		return
	
	# Create tech nodes for current tower type
	create_tech_nodes(container, current_tower_type)

func create_tech_nodes(parent: Control, tower_type: String):
	var tower_data = {}
	if Data.tower_tech_tree.has(tower_type):
		tower_data = Data.tower_tech_tree.get(tower_type)
	
	# Level 1 (base) - center top
	create_tech_node(parent, tower_type, "1", Vector2(400, 50))
	
	# Level 2 options - spread left and right
	create_tech_node(parent, tower_type, "2a", Vector2(250, 200))
	create_tech_node(parent, tower_type, "2b", Vector2(550, 200))
	
	# Level 3 options - four corners
	create_tech_node(parent, tower_type, "3a", Vector2(150, 350))
	create_tech_node(parent, tower_type, "3b", Vector2(350, 350))
	create_tech_node(parent, tower_type, "3c", Vector2(450, 350))
	create_tech_node(parent, tower_type, "3d", Vector2(650, 350))
	
	# Draw connection lines
	create_connection_lines(parent, tower_type)

func create_tech_node(parent: Control, tower_type: String, tech_id: String, pos: Vector2):
	var tech_data = {}
	if Data.tower_tech_tree[tower_type].has(tech_id):
		tech_data = Data.tower_tech_tree[tower_type].get(tech_id)
	if tech_data.is_empty():
		return
	
	# Node container
	var node_panel = Panel.new()
	node_panel.custom_minimum_size = Vector2(160, 100)
	node_panel.position = pos - Vector2(80, 50)
	parent.add_child(node_panel)
	
	var node_vbox = VBoxContainer.new()
	node_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node_vbox.add_theme_constant_override("separation", 5)
	node_panel.add_child(node_vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = tech_data.name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	node_vbox.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = tech_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(140, 30)
	node_vbox.add_child(desc_label)
	
	# Cost and upgrade button
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	node_vbox.add_child(button_container)
	
	var cost_label = Label.new()
	cost_label.text = "消耗: %d" % tech_data.cost
	cost_label.add_theme_font_size_override("font_size", 10)
	button_container.add_child(cost_label)
	
	var upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(60, 25)
	upgrade_button.pressed.connect(_on_tech_button_pressed.bind(tower_type, tech_id))
	button_container.add_child(upgrade_button)
	
	# Store references
	tech_buttons[tech_id] = {
		"panel": node_panel,
		"button": upgrade_button,
		"cost_label": cost_label
	}
	
	update_tech_node_state(tower_type, tech_id)

func update_tech_node_state(tower_type: String, tech_id: String):
	if not tech_buttons.has(tech_id):
		return
	
	var components = tech_buttons[tech_id]
	var panel = components.panel
	var button = components.button
	
	var is_unlocked = tower_tech_system.is_tower_tech_unlocked(tower_type, tech_id)
	var can_unlock = tower_tech_system.can_unlock_tower_tech(tower_type, tech_id)
	
	if is_unlocked:
		button.text = "已解锁"
		button.disabled = true
		panel.modulate = Color.GREEN
	elif can_unlock:
		button.text = "解锁"
		button.disabled = false
		panel.modulate = Color.WHITE
	else:
		button.text = "无法解锁"
		button.disabled = true
		panel.modulate = Color(0.6, 0.6, 0.6)

func create_connection_lines(parent: Control, tower_type: String):
	# Draw lines connecting tech nodes
	var line_color = Color.GRAY
	var line_width = 2.0
	
	# 1 -> 2a, 2b
	draw_line_between_nodes(parent, Vector2(400, 50), Vector2(250, 200), line_color, line_width)
	draw_line_between_nodes(parent, Vector2(400, 50), Vector2(550, 200), line_color, line_width)
	
	# 2a -> 3a, 3b
	draw_line_between_nodes(parent, Vector2(250, 200), Vector2(150, 350), line_color, line_width)
	draw_line_between_nodes(parent, Vector2(250, 200), Vector2(350, 350), line_color, line_width)
	
	# 2b -> 3c, 3d
	draw_line_between_nodes(parent, Vector2(550, 200), Vector2(450, 350), line_color, line_width)
	draw_line_between_nodes(parent, Vector2(550, 200), Vector2(650, 350), line_color, line_width)

func draw_line_between_nodes(parent: Control, from: Vector2, to: Vector2, color: Color, width: float):
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.default_color = color
	line.width = width
	parent.add_child(line)

func _on_tower_tab_pressed(tower_type: String):
	current_tower_type = tower_type
	
	# Update tab button states
	var tab_container = get_node_or_null("Panel/VBoxContainer/HBoxContainer")
	if tab_container:
		for child in tab_container.get_children():
			if child is Button:
				child.button_pressed = false
	
	# Set current tab as pressed
	for child in tab_container.get_children():
		if child is Button and child.text == Data.tower_tech_tree[tower_type].name:
			child.button_pressed = true
			break
	
	update_tech_tree_display()

func _on_tech_button_pressed(tower_type: String, tech_id: String):
	if tower_tech_system.unlock_tower_tech(tower_type, tech_id):
		update_all_tech_nodes()
		update_tech_points_display()

func _on_tech_unlocked(tower_type: String, tech_id: String):
	update_all_tech_nodes()

func update_all_tech_nodes():
	for tech_id in tech_buttons.keys():
		update_tech_node_state(current_tower_type, tech_id)

func update_tech_points_display():
	var points_label = get_node_or_null("Panel/VBoxContainer/HBoxContainer/TechPointsLabel")
	if points_label and tech_point_system:
		points_label.text = "科技点: %d" % tech_point_system.get_tech_points()

func _on_close_button_pressed():
	hide()
	tower_tech_closed.emit()

func open_tower_tech_tree(tower_type: String = ""):
	if tower_type != "":
		current_tower_type = tower_type
	show()
	update_tech_points_display()
	update_tech_tree_display()

func close_tower_tech_tree():
	hide()
	tower_tech_closed.emit()