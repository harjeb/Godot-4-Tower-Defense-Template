extends Node
class_name ManualTestingGuide

## 手动测试指南
## 提供手动测试步骤和验证清单，用于用户验收测试

static var testing_checklist = {
	"element_system": {
		"name": "元素系统测试",
		"tests": [
			{
				"name": "元素克制关系验证",
				"steps": [
					"创建火元素炮塔，攻击风元素敌人",
					"观察伤害数值，应该显示红色（高伤害）",
					"创建风元素炮塔，攻击火元素敌人", 
					"观察伤害数值，应该显示蓝色（低伤害）"
				],
				"expected": "火克制风造成1.5倍伤害，风被火克制造成0.75倍伤害"
			},
			{
				"name": "光暗互克验证",
				"steps": [
					"创建光元素炮塔，攻击暗元素敌人",
					"创建暗元素炮塔，攻击光元素敌人",
					"比较伤害数值"
				],
				"expected": "光暗互相克制，都造成1.5倍伤害"
			},
			{
				"name": "中性元素验证",
				"steps": [
					"创建中性炮塔，攻击各种元素敌人",
					"观察伤害数值"
				],
				"expected": "中性元素对所有敌人都造成1.0倍正常伤害"
			}
		]
	},
	"enemy_abilities": {
		"name": "敌人特殊能力测试",
		"tests": [
			{
				"name": "隐身能力验证",
				"steps": [
					"生成具有隐身能力的敌人（yellowDino或stealthDino）",
					"观察敌人显示为半透明状态",
					"用普通炮塔攻击，应该无法锁定",
					"用光元素炮塔或装备光宝石的炮塔攻击",
					"确认能够锁定和攻击隐身敌人"
				],
				"expected": "隐身敌人半透明显示，只有光元素炮塔能检测"
			},
			{
				"name": "分裂能力验证", 
				"steps": [
					"生成具有分裂能力的敌人（greenDino）",
					"击杀敌人，观察是否分裂成2个子单位",
					"击杀分裂后的子单位，确认再次分裂",
					"击杀第三代分裂单位，确认不再分裂"
				],
				"expected": "敌人死亡时分裂2次，最多产生4个子单位，第三代不分裂"
			},
			{
				"name": "治疗能力验证",
				"steps": [
					"生成具有治疗能力的敌人（healerDino）",
					"攻击敌人使其受伤但不死亡",
					"等待7秒观察敌人是否自动治疗",
					"确认治疗量为最大血量的10%",
					"确认满血敌人不会治疗"
				],
				"expected": "敌人每7秒治疗10%最大血量，满血时不治疗"
			}
		]
	},
	"gem_system": {
		"name": "宝石系统测试",
		"tests": [
			{
				"name": "宝石掉落验证",
				"steps": [
					"击杀不同类型的敌人",
					"观察地面掉落的宝石物品",
					"点击拾取宝石，确认添加到背包"
				],
				"expected": "敌人有概率掉落对应元素的宝石，拾取后进入背包"
			},
			{
				"name": "宝石合成验证",
				"steps": [
					"收集2个相同的初级宝石",
					"打开宝石合成界面",
					"执行2合1合成操作",
					"确认消耗2个初级宝石，获得1个中级宝石"
				],
				"expected": "2个初级宝石合成1个中级宝石，2个中级合成1个高级"
			},
			{
				"name": "宝石装备验证",
				"steps": [
					"选中炮塔，打开详情面板",
					"将宝石从背包拖拽到炮塔插槽",
					"观察炮塔元素变化和伤害加成",
					"卸下宝石确认恢复原状"
				],
				"expected": "宝石装备改变炮塔元素，提供对应的伤害加成"
			}
		]
	},
	"inventory_ui": {
		"name": "背包和UI系统测试",
		"tests": [
			{
				"name": "背包容量验证",
				"steps": [
					"收集物品直到背包显示20/20满容量",
					"尝试再拾取物品，确认提示背包已满",
					"删除或使用一些物品释放空间",
					"确认能够继续拾取新物品"
				],
				"expected": "背包最大容量20槽，满了无法添加新物品"
			},
			{
				"name": "武器盘BUFF验证",
				"steps": [
					"打开武器盘界面，添加各种BUFF物品",
					"填满10个槽位",
					"观察炮塔伤害数值变化",
					"移除BUFF确认伤害恢复"
				],
				"expected": "武器盘最大10槽，BUFF叠加影响炮塔伤害"
			},
			{
				"name": "物品掉落概率验证",
				"steps": [
					"击杀大量相同类型敌人",
					"统计掉落物品的种类和数量",
					"确认掉落概率符合配置数据"
				],
				"expected": "物品掉落概率符合Data.gd中的配置"
			}
		]
	},
	"combat_integration": {
		"name": "战斗系统集成测试",
		"tests": [
			{
				"name": "复合伤害计算验证",
				"steps": [
					"创建火元素炮塔，装备火宝石",
					"在武器盘中装备投射物和火元素BUFF",
					"攻击风元素敌人",
					"手动计算期望伤害并与实际伤害对比"
				],
				"expected": "伤害 = 基础 × 炮塔BUFF × 元素BUFF × 属性克制"
			},
			{
				"name": "BUFF叠加规则验证",
				"steps": [
					"装备多个相同类型的元素BUFF",
					"确认加算叠加（1.0 + 0.1 + 0.1 = 1.2）",
					"装备不同类型BUFF（炮塔类型+元素+宝石）",
					"确认乘算叠加（1.05 × 1.2 × 1.5）"
				],
				"expected": "同类型BUFF加算，不同类型BUFF乘算"
			},
			{
				"name": "实时战斗场景验证",
				"steps": [
					"开始游戏关卡，部署多种元素炮塔",
					"装备不同宝石和武器盘BUFF",
					"观察对不同敌人的战斗效果",
					"确认隐身检测、分裂处理等正常工作"
				],
				"expected": "所有系统在实时战斗中协同工作正常"
			}
		]
	}
}

# 生成手动测试报告
static func generate_manual_test_checklist() -> String:
	var report = "# 塔防游戏增强系统手动测试清单\n\n"
	report += "## 测试说明\n"
	report += "请按照以下清单逐项测试，在每个项目后标记✓（通过）或✗（失败）\n\n"
	
	for system_id in testing_checklist.keys():
		var system = testing_checklist[system_id]
		report += "## %s\n\n" % system.name
		
		for test in system.tests:
			report += "### %s [ ]\n\n" % test.name
			report += "**测试步骤：**\n"
			
			for i in range(test.steps.size()):
				report += "%d. %s\n" % [i + 1, test.steps[i]]
			
			report += "\n**期望结果：** %s\n\n" % test.expected
			report += "**实际结果：** ________________\n\n"
			report += "**测试状态：** [ ] 通过 [ ] 失败\n\n"
			report += "**备注：** ________________\n\n"
			report += "---\n\n"
	
	report += "## 测试总结\n\n"
	report += "**测试者：** ________________\n"
	report += "**测试日期：** ________________\n"
	report += "**测试环境：** ________________\n"
	report += "**整体评价：** ________________\n"
	
	return report

# 验证手动测试结果
static func validate_manual_test_results(results: Dictionary) -> Dictionary:
	var validation = {
		"total_systems": testing_checklist.size(),
		"tested_systems": 0,
		"passed_systems": 0,
		"failed_systems": 0,
		"overall_status": false
	}
	
	for system_id in testing_checklist.keys():
		if system_id in results:
			validation.tested_systems += 1
			if results[system_id].passed:
				validation.passed_systems += 1
			else:
				validation.failed_systems += 1
	
	validation.overall_status = (validation.failed_systems == 0 and validation.tested_systems == validation.total_systems)
	
	return validation

# 获取测试系统信息
static func get_test_system_info(system_id: String) -> Dictionary:
	if system_id in testing_checklist:
		return testing_checklist[system_id]
	return {}

# 获取所有测试系统列表
static func get_all_test_systems() -> Array:
	var systems = []
	for system_id in testing_checklist.keys():
		systems.append({
			"id": system_id,
			"name": testing_checklist[system_id].name,
			"test_count": testing_checklist[system_id].tests.size()
		})
	return systems

# 打印手动测试指南
static func print_manual_testing_guide():
	print("\n" + "="*60)
	print("塔防游戏增强系统 - 手动测试指南")
	print("="*60)
	
	for system_id in testing_checklist.keys():
		var system = testing_checklist[system_id]
		print("\n【%s】" % system.name)
		
		for i in range(system.tests.size()):
			var test = system.tests[i]
			print("%d. %s" % [i + 1, test.name])
			print("   期望：%s" % test.expected)
	
	print("\n" + "="*60)
	print("请按照上述清单进行手动测试")
	print("="*60 + "\n")