extends Control
class_name InventoryUI

signal inventory_closed
signal gem_selected(gem_data: Dictionary)

@onready var grid_container: GridContainer
@onready var close_button: Button
@onready var title_label: Label
@onready var scroll_container: ScrollContainer

var inventory_manager: Node
var slot_scene: PackedScene
var inventory_slots: Array[InventorySlot] = []
var main_panel: Panel

func _ready():
	# 获取管理器引用
	inventory_manager = get_inventory_manager()
	if inventory_manager:
		inventory_manager.inventory_updated.connect(_on_inventory_updated)
	
	# 创建UI元素
	setup_ui()
	
	# 设置输入处理
	set_process_input(true)

func setup_ui():
	# 创建主面板
	main_panel = Panel.new()
	main_panel.size = Vector2(400, 500)
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# 添加背景样式（与武器盘保持一致）
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.15, 0.95)  # 深灰色背景，增加不透明度
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.4, 0.8)  # 边框颜色
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	main_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(main_panel)
	
	# 创建标题栏背景
	var title_background = Panel.new()
	title_background.position = Vector2(0, 0)
	title_background.size = Vector2(400, 40)
	
	# 创建标题栏样式（确保背景透明，只显示边框）
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.25, 0.25, 0.3, 0.8)  # 蓝灰色背景
	title_style.border_width_bottom = 1
	title_style.border_color = Color(0.6, 0.6, 0.6, 0.5)
	title_style.corner_radius_top_left = 8
	title_style.corner_radius_top_right = 8
	title_style.corner_radius_bottom_left = 0
	title_style.corner_radius_bottom_right = 0
	title_background.add_theme_stylebox_override("panel", title_style)
	main_panel.add_child(title_background)
	
	# 创建标题
	title_label = Label.new()
	title_label.text = "📦 背包 (拖拽移动)"
	title_label.position = Vector2(10, 5)
	title_label.size = Vector2(300, 30)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_panel.add_child(title_label)
	
	# 添加拖拽功能到标题栏
	setup_panel_dragging(title_background)
	
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(360, 10)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(_on_close_button_pressed)
	main_panel.add_child(close_button)
	
	# 创建滚动容器
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(10, 45)
	scroll_container.size = Vector2(380, 445)
	main_panel.add_child(scroll_container)
	
	# 创建网格容器
	grid_container = GridContainer.new()
	grid_container.columns = 5
	grid_container.size = Vector2(360, 400)
	scroll_container.add_child(grid_container)
	
	# 创建背包槽位
	setup_inventory_slots()

func setup_inventory_slots():
	for i in range(20):  # 20个背包槽位
		var slot = InventorySlot.new()
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(64, 64)
		slot.item_clicked.connect(_on_slot_item_clicked)
		grid_container.add_child(slot)
		inventory_slots.append(slot)

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_inventory"):
		close_inventory()

func _on_inventory_updated(inventory: Array):
	# 清空所有槽位
	for slot in inventory_slots:
		slot.clear_item()
	
	# 填充物品
	for i in range(inventory.size()):
		if i < inventory_slots.size():
			inventory_slots[i].set_item(inventory[i])

func _on_slot_item_clicked(slot_index: int, item_data: Dictionary):
	if not item_data.is_empty():
		gem_selected.emit(item_data)
		var gem_name = "未知"
		if item_data.has("name"):
			gem_name = item_data.get("name")
		print("选中宝石: ", gem_name)

func _on_close_button_pressed():
	close_inventory()

func close_inventory():
	inventory_closed.emit()
	hide()

func open_inventory():
	show()
	if inventory_manager:
		_on_inventory_updated(inventory_manager.get_inventory_data())

func get_inventory_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("InventoryManager")
	return null

# 拖拽功能设置
var dragging = false
var drag_start_position = Vector2.ZERO

func setup_panel_dragging(panel_node: Control):
	panel_node.gui_input.connect(_on_panel_input)

func _on_panel_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start_position = event.global_position - main_panel.position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		main_panel.position = event.global_position - drag_start_position

# 内部槽位类
class InventorySlot:
	extends Control
	
	signal item_clicked(slot_index: int, item_data: Dictionary)
	
	var slot_index: int = 0
	var item_data: Dictionary = {}
	var background: NinePatchRect
	var item_icon: TextureRect
	var quantity_label: Label
	
	func _init():
		custom_minimum_size = Vector2(64, 64)
		
		# 创建背景框
		background = NinePatchRect.new()
		background.size = Vector2(64, 64)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# 创建背景样式
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.6, 0.6, 0.6, 0.8)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		
		# 应用样式到Panel而不是NinePatchRect
		var panel = Panel.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_theme_stylebox_override("panel", style)
		add_child(panel)
		
		# 创建物品图标
		item_icon = TextureRect.new()
		item_icon.position = Vector2(4, 4)
		item_icon.size = Vector2(56, 56)
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(item_icon)
		
		# 创建数量标签
		quantity_label = Label.new()
		quantity_label.position = Vector2(40, 45)
		quantity_label.size = Vector2(20, 15)
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		add_child(quantity_label)
		
		# 设置点击检测
		gui_input.connect(_on_gui_input)
	
	func set_item(item: Dictionary):
		item_data = item
		
		if item.is_empty():
			clear_item()
			return
		
		# 设置图标 (使用占位符)
		var texture = PlaceholderTexture2D.new()
		texture.size = Vector2(56, 56)
		item_icon.texture = texture
		
		# 根据宝石元素设置颜色
		if item.has("data") and item.data.has("element"):
			var element = item.data.element
			item_icon.modulate = ElementSystem.get_element_color(element)
		else:
			item_icon.modulate = Color.WHITE
		
		# 设置数量
		if item.has("quantity") and item.quantity > 1:
			quantity_label.text = str(item.quantity)
			quantity_label.show()
		else:
			quantity_label.hide()
	
	func clear_item():
		item_data = {}
		item_icon.texture = null
		item_icon.modulate = Color.WHITE
		quantity_label.hide()
	
	func _on_gui_input(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				item_clicked.emit(slot_index, item_data)
