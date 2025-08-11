extends Control
class_name TestScene

## 测试场景UI
## 提供可视化界面来运行和查看测试结果

@onready var test_runner: TestRunner = TestRunner.new()
@onready var output_text: TextEdit
@onready var run_all_button: Button
@onready var validate_button: Button
@onready var suite_list: ItemList
@onready var progress_bar: ProgressBar
@onready var status_label: Label

var original_print_function: Callable

func _ready():
	setup_ui()
	setup_test_runner()
	redirect_print_output()

func setup_ui():
	# 创建主容器
	var main_container = VBoxContainer.new()
	add_child(main_container)
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 标题
	var title_label = Label.new()
	title_label.text = "塔防游戏增强系统 - 测试套件"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# 按钮容器
	var button_container = HBoxContainer.new()
	main_container.add_child(button_container)
	
	run_all_button = Button.new()
	run_all_button.text = "运行所有测试"
	run_all_button.pressed.connect(_on_run_all_pressed)
	button_container.add_child(run_all_button)
	
	validate_button = Button.new()
	validate_button.text = "验证核心功能"
	validate_button.pressed.connect(_on_validate_pressed)
	button_container.add_child(validate_button)
	
	var generate_report_button = Button.new()
	generate_report_button.text = "生成测试报告"
	generate_report_button.pressed.connect(_on_generate_report_pressed)
	button_container.add_child(generate_report_button)
	
	# 状态和进度
	var status_container = HBoxContainer.new()
	main_container.add_child(status_container)
	
	status_label = Label.new()
	status_label.text = "就绪"
	status_container.add_child(status_label)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(200, 20)
	status_container.add_child(progress_bar)
	
	# 分割面板
	var split_container = HSplitContainer.new()
	split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(split_container)
	
	# 左侧：测试套件列表
	var left_panel = VBoxContainer.new()
	split_container.add_child(left_panel)
	
	var suite_label = Label.new()
	suite_label.text = "测试套件列表"
	left_panel.add_child(suite_label)
	
	suite_list = ItemList.new()
	suite_list.custom_minimum_size = Vector2(250, 0)
	suite_list.item_selected.connect(_on_suite_selected)
	left_panel.add_child(suite_list)
	
	var run_suite_button = Button.new()
	run_suite_button.text = "运行选中套件"
	run_suite_button.pressed.connect(_on_run_suite_pressed)
	left_panel.add_child(run_suite_button)
	
	# 右侧：输出文本
	var right_panel = VBoxContainer.new()
	split_container.add_child(right_panel)
	
	var output_label = Label.new()
	output_label.text = "测试输出"
	right_panel.add_child(output_label)
	
	output_text = TextEdit.new()
	output_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_text.editable = false
	output_text.placeholder_text = "测试输出将显示在这里..."
	right_panel.add_child(output_text)
	
	var clear_button = Button.new()
	clear_button.text = "清空输出"
	clear_button.pressed.connect(_on_clear_output_pressed)
	right_panel.add_child(clear_button)

func setup_test_runner():
	add_child(test_runner)
	
	# 注册所有测试套件
	test_runner.register_test_suite(ElementSystemTests.new())
	test_runner.register_test_suite(EnemyAbilitiesTests.new())  
	test_runner.register_test_suite(GemSystemTests.new())
	test_runner.register_test_suite(InventoryUISystemTests.new())
	test_runner.register_test_suite(CombatIntegrationTests.new())
	
	# 连接信号
	test_runner.all_tests_completed.connect(_on_all_tests_completed)
	
	# 填充测试套件列表
	var available_suites = test_runner.get_available_test_suites()
	for suite_name in available_suites:
		suite_list.add_item(suite_name)
	
	print_to_output("测试运行器已初始化，包含 %d 个测试套件" % available_suites.size())

func redirect_print_output():
	# 重定向print输出到UI文本框
	# 注意：这是一个简化的实现，实际项目中可能需要更复杂的日志系统
	pass

func print_to_output(text: String):
	if output_text:
		output_text.text += text + "\n"
		# 自动滚动到底部
		output_text.scroll_vertical = output_text.get_v_scroll_bar().max_value

func _on_run_all_pressed():
	run_all_button.disabled = true
	validate_button.disabled = true
	status_label.text = "正在运行所有测试..."
	progress_bar.value = 0
	
	print_to_output("\n开始运行所有测试套件...")
	
	# 在下一帧运行测试，避免阻塞UI
	await get_tree().process_frame
	var summary = test_runner.run_all_tests()
	
	_display_test_results(summary)

func _on_validate_pressed():
	run_all_button.disabled = true
	validate_button.disabled = true
	status_label.text = "正在验证核心功能..."
	progress_bar.value = 0
	
	print_to_output("\n开始验证核心功能...")
	
	await get_tree().process_frame
	var validation_results = test_runner.validate_core_functionality()
	
	_display_validation_results(validation_results)

func _on_generate_report_pressed():
	var success = test_runner.generate_test_report("user://test_report.txt")
	if success:
		print_to_output("测试报告已生成: user://test_report.txt")
		status_label.text = "报告已生成"
	else:
		print_to_output("生成测试报告失败")
		status_label.text = "报告生成失败"

func _on_run_suite_pressed():
	var selected_indices = suite_list.get_selected_items()
	if selected_indices.is_empty():
		print_to_output("请选择要运行的测试套件")
		return
	
	var selected_index = selected_indices[0]
	var suite_name = suite_list.get_item_text(selected_index)
	
	print_to_output("\n运行测试套件: " + suite_name)
	status_label.text = "运行套件: " + suite_name
	
	await get_tree().process_frame
	var result = test_runner.run_test_suite(suite_name)
	
	if not result.is_empty():
		_display_single_suite_result(result)
	else:
		print_to_output("未找到指定的测试套件")

func _on_suite_selected(index: int):
	var suite_name = suite_list.get_item_text(index)
	print_to_output("选中测试套件: " + suite_name)

func _on_clear_output_pressed():
	output_text.text = ""
	status_label.text = "输出已清空"

func _on_all_tests_completed(summary: Dictionary):
	_display_test_results(summary)

func _display_test_results(summary: Dictionary):
	print_to_output("\n=== 测试完成 ===")
	print_to_output("测试套件: %d" % summary.total_suites)
	print_to_output("总测试数: %d" % summary.total_tests)
	print_to_output("通过: %d" % summary.total_passed)
	print_to_output("失败: %d" % summary.total_failed)
	print_to_output("成功率: %.1f%%" % summary.success_rate)
	print_to_output("总耗时: %.2fms" % summary.total_duration)
	
	if summary.total_failed == 0:
		print_to_output("\n🎉 所有测试通过！")
		status_label.text = "所有测试通过"
		status_label.modulate = Color.GREEN
	else:
		print_to_output("\n⚠️  有测试失败，请检查实现")
		status_label.text = "有测试失败"
		status_label.modulate = Color.RED
	
	progress_bar.value = summary.success_rate
	run_all_button.disabled = false
	validate_button.disabled = false

func _display_single_suite_result(result: Dictionary):
	print_to_output("\n--- %s 结果 ---" % result.suite_name)
	print_to_output("测试数量: %d" % result.total_tests)
	print_to_output("通过: %d" % result.passed)
	print_to_output("失败: %d" % result.failed)
	print_to_output("耗时: %.2fms" % result.total_duration)
	
	if result.failed > 0:
		print_to_output("\n失败的测试:")
		for test_name in result.test_results.keys():
			var test_result = result.test_results[test_name]
			if not test_result.passed:
				print_to_output("  - %s: %s" % [test_name, test_result.message])
	
	status_label.text = "套件完成: " + result.suite_name
	progress_bar.value = float(result.passed) / result.total_tests * 100.0

func _display_validation_results(results: Dictionary):
	print_to_output("\n=== 核心功能验证 ===")
	print_to_output("元素系统: %s" % ("✓" if results.element_system else "✗"))
	print_to_output("敌人特殊能力: %s" % ("✓" if results.enemy_abilities else "✗"))
	print_to_output("宝石系统: %s" % ("✓" if results.gem_system else "✗"))
	print_to_output("背包UI系统: %s" % ("✓" if results.inventory_ui else "✗"))
	print_to_output("战斗集成: %s" % ("✓" if results.combat_integration else "✗"))
	
	if results.overall_status:
		print_to_output("\n✅ 系统整体功能正常！")
		status_label.text = "验证通过"
		status_label.modulate = Color.GREEN
		progress_bar.value = 100.0
	else:
		print_to_output("\n❌ 系统存在问题，请检查失败的组件")
		status_label.text = "验证失败"
		status_label.modulate = Color.RED
		progress_bar.value = 50.0
	
	run_all_button.disabled = false
	validate_button.disabled = false

# 快速启动测试的静态方法
static func launch_test_scene():
	var scene = TestScene.new()
	var scene_tree = Engine.get_main_loop() as SceneTree
	scene_tree.current_scene.queue_free()
	scene_tree.current_scene = scene
	scene_tree.root.add_child(scene)