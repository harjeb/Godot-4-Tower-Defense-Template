@tool
extends SceneTree

## 冰元素系统验证执行器
## 快速验证冰元素宝石系统的完整性

func _init():
	print("冰元素宝石系统验证执行器")
	print("====================================")
	
	# 运行验证
	run_ice_validation()
	
	# 等待一帧确保所有输出完成
	await process_frame
	
	# 退出
	quit()

func run_ice_validation():
	print("开始验证冰元素系统...\n")
	
	var start_time = Time.get_time_dict_from_system()
	var validation_passed = true
	
	# 运行冰元素验证
	var validator = IceElementValidation.new()
	add_child(validator)
	
	# 等待验证完成
	await get_tree().process_frame
	
	# 执行验证
	validator.run_validation()
	
	# 等待验证完成
	await get_tree().process_frame
	
	# 检查结果
	if validator.failed_tests > 0:
		validation_passed = false
		print("\n❌ 验证失败: " + str(validator.failed_tests) + " 个测试失败")
	else:
		print("\n✅ 验证通过: 所有冰元素系统组件正常工作")
	
	var end_time = Time.get_time_dict_from_system()
	var duration = end_time["unix"] - start_time["unix"]
	print("\n验证耗时: " + str(duration) + " 秒")
	
	validator.queue_free()
	
	return validation_passed