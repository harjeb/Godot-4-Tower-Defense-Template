extends SceneTree

func _initialize():
	print("=== 跟踪弹系统验证 ===")
	
	# 测试1: 检查文件是否存在
	var homing_script_path = "res://Scenes/turrets/projectileTurret/bullet/homingBullet.gd"
	var homing_scene_path = "res://Scenes/turrets/projectileTurret/bullet/homingBullet.tscn"
	
	if ResourceLoader.exists(homing_script_path):
		print("✓ 跟踪弹脚本存在")
	else:
		print("✗ 跟踪弹脚本不存在")
	
	if ResourceLoader.exists(homing_scene_path):
		print("✓ 跟踪弹场景存在")
	else:
		print("✗ 跟踪弹场景不存在")
	
	# 测试2: 检查projectileTurret是否更新
	var projectile_turret_path = "res://Scenes/turrets/projectileTurret/projectileTurret.gd"
	if ResourceLoader.exists(projectile_turret_path):
		var turret_script = load(projectile_turret_path)
		if turret_script and turret_script.has_method("should_use_homing_bullets"):
			print("✓ 炮塔支持跟踪弹判断")
		else:
			print("✗ 炮塔缺少should_use_homing_bullets方法")
	
	# 测试3: 检查箭塔配置
	if Data and Data.turrets and Data.turrets.has("arrow_tower"):
		print("✓ 箭塔配置存在")
		var arrow_tower_data = Data.turrets.arrow_tower
		if arrow_tower_data.has("stats"):
			print("✓ 箭塔属性配置正确")
	else:
		print("✗ 箭塔配置不存在")
	
	print("\n=== 跟踪弹系统验证完成 ===")
	quit()