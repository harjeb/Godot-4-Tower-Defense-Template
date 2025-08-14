extends Control

## Error Dialog - 显示错误信息的弹框
## 防止debug日志持续刷屏

signal dialog_closed

@onready var error_label = $Panel/MarginContainer/VBoxContainer/ErrorLabel
@onready var ok_button = $Panel/MarginContainer/VBoxContainer/OKButton
@onready var animation_player = $AnimationPlayer

var current_error_message: String = ""

func _ready():
	# 安全检查节点是否存在
	if not _validate_nodes():
		print("创建备用错误对话框...")
		_create_fallback_dialog()
	
	# Connect button signal
	if ok_button:
		ok_button.pressed.connect(_on_ok_button_pressed)
	
	# Hide initially
	visible = false
	
	# Pause the game when error dialog is shown
	if get_tree():
		get_tree().paused = false

func show_error(message: String, title: String = "错误"):
	"""显示错误对话框"""
	current_error_message = message
	
	# Set error message
	if error_label:
		error_label.text = message
	else:
		print("错误: error_label 为空，无法显示错误消息")
		return
	
	# Show dialog
	visible = true
	
	# Play show animation if available
	if animation_player and animation_player.has_animation("show"):
		animation_player.play("show")
	
	# Bring to front (safely)
	if get_tree() and get_tree().current_scene:
		var current_scene = get_tree().current_scene
		if current_scene.get_parent() and is_instance_valid(self):
			current_scene.move_child(self, current_scene.get_child_count() - 1)
		else:
			print("警告: 无法将错误对话框移到前台")
	
	print("错误对话框显示: ", message)

func _on_ok_button_pressed():
	"""关闭对话框"""
	visible = false
	
	# Play hide animation if available
	if animation_player and animation_player.has_animation("hide"):
		animation_player.play("hide")
	
	# Emit signal
	dialog_closed.emit()
	
	print("错误对话框已关闭")

func _input(event):
	"""处理输入事件"""
	if visible and event.is_action_pressed("ui_accept"):
		_on_ok_button_pressed()
	elif visible and event.is_action_pressed("ui_cancel"):
		_on_ok_button_pressed()

func set_error_color(color: Color):
	"""设置错误文本颜色"""
	if error_label:
		error_label.modulate = color

func get_error_message() -> String:
	"""获取当前错误消息"""
	return current_error_message

func is_dialog_visible() -> bool:
	"""检查对话框是否可见"""
	return visible

func _validate_nodes() -> bool:
	"""验证所有必需的节点是否存在"""
	var nodes_ok = true
	
	if not error_label:
		print("错误: ErrorLabel 节点不存在")
		nodes_ok = false
	
	if not ok_button:
		print("错误: OKButton 节点不存在")
		nodes_ok = false
	
	# AnimationPlayer 是可选的
	if not animation_player:
		print("警告: AnimationPlayer 节点不存在，动画将不可用")
	
	return nodes_ok

func _create_fallback_dialog():
	"""创建备用对话框（当场景节点缺失时）"""
	# 创建简单的文本标签
	var fallback_label = Label.new()
	fallback_label.text = "错误对话框场景配置错误"
	fallback_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(fallback_label)
	
	# 创建备用按钮
	var fallback_button = Button.new()
	fallback_button.text = "确定"
	fallback_button.position = Vector2(200, 300)
	fallback_button.pressed.connect(_on_ok_button_pressed)
	add_child(fallback_button)
	
	# 更新引用
	error_label = fallback_label
	ok_button = fallback_button