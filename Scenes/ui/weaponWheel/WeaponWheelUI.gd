extends Control
class_name WeaponWheelUI

signal weapon_wheel_closed
signal buff_removed(slot_index: int)

@onready var wheel_container: Control
@onready var close_button: Button
@onready var title_label: Label
@onready var stats_label: Label

var weapon_manager: Node
var wheel_slots: Array[WeaponWheelSlot] = []
var wheel_radius: float = 120.0

func _ready():
	# 获取管理器引用
	weapon_manager = get_weapon_wheel_manager()
	if weapon_manager:
		weapon_manager.weapon_wheel_updated.connect(_on_weapon_wheel_updated)
	
	# 创建UI元素
	setup_ui()
	
	# 设置输入处理
	set_process_input(true)

func setup_ui():
	# 创建主面板
	var panel = Panel.new()
	panel.size = Vector2(400, 400)
	panel.position = Vector2(100, 100)
	
	# 添加背景样式（与物品包保持一致）
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.15, 0.9)  # 深灰色背景
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.4, 0.8)  # 边框颜色
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(panel)
	
	# 创建标题
	title_label = Label.new()
	title_label.text = "⚔️ 武器盘 (拖拽移动)"
	title_label.position = Vector2(10, 10)
	title_label.size = Vector2(300, 30)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(title_label)
	
	# 添加拖拽功能
	setup_panel_dragging(panel)
	
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(360, 10)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(_on_close_button_pressed)
	panel.add_child(close_button)
	
	# 创建轮盘容器
	wheel_container = Control.new()
	wheel_container.position = Vector2(200, 200)  # 中心位置
	wheel_container.size = Vector2(0, 0)  # 不需要尺寸，只是作为中心点
	panel.add_child(wheel_container)
	
	# 创建统计信息标签
	stats_label = Label.new()
	stats_label.position = Vector2(10, 350)
	stats_label.size = Vector2(380, 40)
	stats_label.text = "激活BUFF: 0/10"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(stats_label)
	
	# 创建轮盘槽位
	setup_wheel_slots()

func setup_wheel_slots():
	for i in range(10):  # 10个武器盘槽位
		var slot = WeaponWheelSlot.new()
		slot.slot_index = i
		
		# 计算圆形布局位置
		var angle = i * PI * 2 / 10 - PI/2  # 从顶部开始
		var pos = Vector2(cos(angle), sin(angle)) * wheel_radius
		slot.position = pos - Vector2(32, 32)  # 调整中心点
		
		slot.buff_removed.connect(_on_buff_removed)
		wheel_container.add_child(slot)
		wheel_slots.append(slot)

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_weapon_wheel"):
		close_weapon_wheel()

func _on_weapon_wheel_updated(items: Array):
	# 更新所有槽位
	for i in range(wheel_slots.size()):
		if i < items.size():
			wheel_slots[i].set_buff(items[i])
		else:
			wheel_slots[i].clear_buff()
	
	# 更新统计信息
	update_stats_display()

func update_stats_display():
	if not weapon_manager:
		return
	
	var active_count = weapon_manager.get_slot_count()
	var total_slots = weapon_manager.max_slots
	stats_label.text = "激活BUFF: %d/%d" % [active_count, total_slots]

func _on_buff_removed(slot_index: int):
	if weapon_manager:
		weapon_manager.remove_from_weapon_wheel(slot_index)
	buff_removed.emit(slot_index)

func _on_close_button_pressed():
	close_weapon_wheel()

func close_weapon_wheel():
	weapon_wheel_closed.emit()
	hide()

func open_weapon_wheel():
	show()
	if weapon_manager:
		_on_weapon_wheel_updated(weapon_manager.get_weapon_wheel_data())

func get_weapon_wheel_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("WeaponWheelManager")
	return null

# 内部轮盘槽位类
class WeaponWheelSlot:
	extends Control
	
	signal buff_removed(slot_index: int)
	
	var slot_index: int = 0
	var buff_data: Dictionary = {}
	var background: NinePatchRect
	var buff_icon: TextureRect
	var remove_button: Button
	
	func _init():
		custom_minimum_size = Vector2(64, 64)
		
		# 创建背景
		background = NinePatchRect.new()
		background.size = Vector2(64, 64)
		background.modulate = Color(0.2, 0.2, 0.4, 0.8)
		add_child(background)
		
		# 创建BUFF图标
		buff_icon = TextureRect.new()
		buff_icon.position = Vector2(4, 4)
		buff_icon.size = Vector2(56, 56)
		buff_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(buff_icon)
		
		# 创建移除按钮
		remove_button = Button.new()
		remove_button.text = "-"
		remove_button.position = Vector2(45, -5)
		remove_button.size = Vector2(20, 20)
		remove_button.pressed.connect(_on_remove_pressed)
		remove_button.hide()
		add_child(remove_button)
	
	func set_buff(buff_item: Dictionary):
		buff_data = buff_item
		
		if buff_item.is_empty():
			clear_buff()
			return
		
		# 设置图标 (使用占位符)
		var texture = PlaceholderTexture2D.new()
		texture.size = Vector2(56, 56)
		buff_icon.texture = texture
		
		# 根据BUFF类型设置颜色
		if buff_item.has("data"):
			var data = buff_item.data
			if data.has("element_type"):
				buff_icon.modulate = ElementSystem.get_element_color(data.element_type)
			elif data.has("applies_to"):
				# 炮塔类型BUFF使用不同颜色
				buff_icon.modulate = Color.ORANGE
			else:
				buff_icon.modulate = Color.WHITE
		
		remove_button.show()
		
		# 设置提示信息
		if buff_item.has("data") and buff_item.data.has("name"):
			tooltip_text = buff_item.data.name + " (+" + str(buff_item.data.bonus * 100) + "%)"
	
	func clear_buff():
		buff_data = {}
		buff_icon.texture = null
		buff_icon.modulate = Color.WHITE
		remove_button.hide()
		tooltip_text = "空槽位"
	
	func _on_remove_pressed():
		buff_removed.emit(slot_index)
		clear_buff()

# 拖拽功能设置
var dragging = false
var drag_start_position = Vector2.ZERO

func setup_panel_dragging(panel_node: Panel):
	panel_node.gui_input.connect(_on_panel_input)

func _on_panel_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start_position = event.global_position - position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = event.global_position - drag_start_position