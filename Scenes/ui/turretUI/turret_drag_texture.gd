extends TextureRect

var turretType := ""

var can_grab = false
var grabbed_offset = Vector2()
var initial_pos := position
var placeholder = null

# Tooltip System
var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var is_mouse_over: bool = false
var is_dragging: bool = false

func _ready():
	Globals.gold_changed.connect(check_can_purchase)
	setup_tooltip()
	connect_mouse_events()

func connect_mouse_events():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event):
	if event is InputEventMouseButton and check_can_purchase(Globals.current_map.gold):
		can_grab = event.pressed
		grabbed_offset = position - get_global_mouse_position()
		if event.pressed:
			is_dragging = true
			hide_tooltip()
		else:
			is_dragging = false

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_grab:
		if placeholder:
			placeholder.position = get_global_mouse_position() - get_viewport_rect().size / 2
		else:
			position = get_global_mouse_position() + grabbed_offset
	if Input.is_action_just_released("LeftClick") and placeholder:
		check_can_drop()

func _get_drag_data(_at_position):
	if check_can_purchase(Globals.current_map.gold):
		visible = false
		create_placeholder()

func check_can_drop():
	position = initial_pos
	can_grab = false
	is_dragging = false
	visible = true
	if placeholder.can_place:
		build()
		placeholder = null
		return
	failed_drop()

func build():
	Globals.current_map.gold -= Data.turrets[turretType]["cost"]
	placeholder.build()

func failed_drop():
	if placeholder:
		placeholder.queue_free()
		placeholder = null

func create_placeholder():
	var turretScene := load(Data.turrets[turretType]["scene"])
	var turret = turretScene.instantiate()
	turret.turret_type = turretType
	Globals.turrets_node.add_child(turret)
	placeholder = turret
	placeholder.set_placeholder()

func check_can_purchase(newGold):
	if turretType:
		if newGold >= Data.turrets[turretType]["cost"]:
			get_parent().can_purchase = true
			return true
		get_parent().can_purchase = false
		return false

# Tooltip System Methods
func setup_tooltip():
	# 创建tooltip面板
	tooltip_panel = Panel.new()
	tooltip_panel.size = Vector2(300, 250)
	tooltip_panel.visible = false
	tooltip_panel.z_index = 1000  # 确保显示在最上层
	
	# 设置面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	# 创建文本标签
	tooltip_label = RichTextLabel.new()
	tooltip_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tooltip_label.add_theme_constant_override("margin_left", 12)
	tooltip_label.add_theme_constant_override("margin_right", 12)
	tooltip_label.add_theme_constant_override("margin_top", 12)
	tooltip_label.add_theme_constant_override("margin_bottom", 12)
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_panel.add_child(tooltip_label)
	
	# 添加到场景根节点以确保显示在最上层
	call_deferred("add_tooltip_to_scene")

func add_tooltip_to_scene():
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(tooltip_panel)
	else:
		get_viewport().add_child(tooltip_panel)

func _on_mouse_entered():
	is_mouse_over = true
	if not is_dragging:
		# 添加小延迟避免鼠标快速移过时显示tooltip
		get_tree().create_timer(0.5).timeout.connect(show_tooltip_delayed)

func _on_mouse_exited():
	is_mouse_over = false
	hide_tooltip()

func show_tooltip_delayed():
	if is_mouse_over and not is_dragging:
		show_tooltip()

func show_tooltip():
	if not tooltip_panel or turretType == "" or is_dragging:
		return
	
	# 更新tooltip内容
	update_tooltip_content()
	
	# 设置位置
	position_tooltip()
	
	tooltip_panel.visible = true

func hide_tooltip():
	if tooltip_panel:
		tooltip_panel.visible = false

func position_tooltip():
	if not tooltip_panel:
		return
	
	# 获取购买栏容器的全局位置
	var container_global_pos = global_position
	var container_size = size
	
	# 默认显示在容器上方
	var tooltip_pos = Vector2(
		container_global_pos.x + container_size.x / 2 - tooltip_panel.size.x / 2,
		container_global_pos.y - tooltip_panel.size.y - 10
	)
	
	# 确保不超出屏幕边界
	var screen_size = get_viewport().get_visible_rect().size
	
	# 水平边界检查
	if tooltip_pos.x < 10:
		tooltip_pos.x = 10
	elif tooltip_pos.x + tooltip_panel.size.x > screen_size.x - 10:
		tooltip_pos.x = screen_size.x - tooltip_panel.size.x - 10
	
	# 垂直边界检查 - 如果上方空间不够，显示在下方
	if tooltip_pos.y < 10:
		tooltip_pos.y = container_global_pos.y + container_size.y + 10
	
	tooltip_panel.position = tooltip_pos

func update_tooltip_content():
	if not tooltip_label or turretType == "":
		return
	
	var turret_data = Data.turrets[turretType]
	var turret_name = turret_data.get("name", turretType)
	var cost = turret_data.get("cost", 0)
	var element = turret_data.get("element", "neutral")
	var category = turret_data.get("turret_category", "unknown")
	
	# 构建tooltip内容
	var content = "[center][color=gold][b]%s[/b][/color][/center]\n" % turret_name
	content += "[center][color=yellow]价格: %d 金币[/color][/center]\n\n" % cost
	
	# 检查是否有足够金币
	if Globals.current_map and Globals.current_map.gold < cost:
		content += "[center][color=red][b]金币不足![/b][/color][/center]\n\n"
	
	# 元素信息
	if element != "neutral":
		var element_color = get_element_color(element)
		var element_name = get_element_name(element)
		content += "[color=%s]元素: %s[/color]\n" % [element_color, element_name]
	
	# 类别信息
	var category_name = get_category_name(category)
	content += "[color=lightblue]类型: %s[/color]\n\n" % category_name
	
	# 属性信息
	if turret_data.has("stats"):
		content += "[color=white][b]基础属性:[/b][/color]\n"
		var stats = turret_data["stats"]
		
		if stats.has("damage"):
			content += "[color=orange]• 伤害: %s[/color]\n" % str(stats["damage"])
		
		if stats.has("attack_speed"):
			content += "[color=green]• 攻击速度: %s[/color]\n" % str(stats["attack_speed"])
		
		if stats.has("attack_range"):
			content += "[color=cyan]• 攻击范围: %s[/color]\n" % str(stats["attack_range"])
		
		if stats.has("bulletSpeed"):
			content += "[color=yellow]• 弹道速度: %s[/color]\n" % str(stats["bulletSpeed"])
		
		if stats.has("bulletPierce"):
			content += "[color=purple]• 穿透: %s[/color]\n" % str(stats["bulletPierce"])
	
	# 升级信息
	if turret_data.has("max_level") and turret_data["max_level"] > 1:
		content += "\n[color=lightgreen]可升级等级: %d[/color]\n" % turret_data["max_level"]
		if turret_data.has("upgrade_cost"):
			content += "[color=lightgreen]升级费用: %d 金币[/color]\n" % turret_data["upgrade_cost"]
	
	# 特殊能力提示
	var special_info = get_special_ability_info(turretType, category)
	if special_info != "":
		content += "\n[color=pink][b]特殊能力:[/b][/color]\n%s" % special_info
	
	tooltip_label.text = content

func get_element_color(element: String) -> String:
	match element:
		"fire": return "red"
		"ice": return "lightblue"
		"wind": return "lightgreen"
		"earth": return "brown"
		"light": return "yellow"
		"dark": return "purple"
		_: return "white"

func get_element_name(element: String) -> String:
	match element:
		"fire": return "火"
		"ice": return "冰"
		"wind": return "风"
		"earth": return "土"
		"light": return "光"
		"dark": return "暗"
		_: return "无"

func get_category_name(category: String) -> String:
	match category:
		"projectile": return "弹道塔"
		"melee": return "近战塔"
		"ray": return "射线塔"
		"support": return "辅助塔"
		"special": return "特殊塔"
		_: return "未知"

func get_special_ability_info(turret_type: String, category: String) -> String:
	# 根据REQUIREMENTS.md中的塔类型描述
	match turret_type:
		"gatling":
			return "[color=orange]• 快速攻击的弹道塔[/color]"
		"laser":
			return "[color=cyan]• 激光射线攻击[/color]"
		"ray":
			return "[color=yellow]• 持续伤害射线[/color]"
		"melee":
			return "[color=red]• 近距离高伤害攻击[/color]"
		_:
			match category:
				"projectile":
					return "[color=orange]• 发射弹道进行攻击[/color]"
				"melee":
					return "[color=red]• 范围近战攻击[/color]"
				"ray":
					return "[color=yellow]• 射线持续伤害[/color]"
				"support":
					return "[color=green]• 提供辅助效果[/color]"
				"special":
					return "[color=purple]• 特殊功能塔[/color]"
				_:
					return ""

func _exit_tree():
	# 清理tooltip
	if tooltip_panel and is_instance_valid(tooltip_panel):
		tooltip_panel.queue_free()
