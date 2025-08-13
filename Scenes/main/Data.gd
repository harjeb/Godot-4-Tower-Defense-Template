extends Node

## Resource path constants for better maintainability
const PATHS = {
	"scenes": {
		"turrets": {
			"projectile": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
			"melee": "res://Scenes/turrets/meleeTurret/meleeTurret.tscn",
			"ray": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
			"base": "res://Scenes/turrets/turretBase/turret_base.tscn"
		},
		"ui": {
			"turret_details": "res://Scenes/ui/turretUI/turret_details.tscn"
		}
	},
	"assets": {
		"turrets": {
			"techno": "res://Assets/turrets/technoturret.png",
			"laser": "res://Assets/turrets/laserturret.png",
			"real_laser": "res://Assets/turrets/reallaser.png",
			"dynamite": "res://Assets/turrets/dynamite.png"
		},
		"bullets": {
			"fire": "res://Assets/bullets/bullet1.tres",
			"laser": "res://Assets/bullets/bullet2.tres"
		},
		"summon_stones": {
			"shiva": "res://Assets/summon_stones/shiva.png",
			"lucifer": "res://Assets/summon_stones/lucifer.png",
			"europa": "res://Assets/summon_stones/europa.png",
			"titan": "res://Assets/summon_stones/titan.png",
			"zeus": "res://Assets/summon_stones/zeus.png"
		},
		"maps": {
			"map1": "res://Assets/maps/map1.webp",
			"map2": "res://Assets/maps/map2.png"
		}
	}
}

## Safe resource loading with error handling
static func load_resource_safe(path: String, expected_type: String = "") -> Resource:
	if not ResourceLoader.exists(path):
		push_error("Resource not found: " + path)
		return null
	
	var resource = load(path)
	if not resource:
		push_error("Failed to load resource: " + path)
		return null
	
	if expected_type != "" and resource.get_class() != expected_type:
		push_warning("Resource type mismatch for " + path + ". Expected: " + expected_type)
	
	return resource

## Get path from PATHS dictionary with error checking
static func get_path(category: String, subcategory: String, item: String) -> String:
	if not PATHS.has(category):
		push_error("Path category not found: " + category)
		return ""
	
	if not PATHS[category].has(subcategory):
		push_error("Path subcategory not found: " + category + "." + subcategory)
		return ""
	
	if not PATHS[category][subcategory].has(item):
		push_error("Path item not found: " + category + "." + subcategory + "." + item)
		return ""
	
	return PATHS[category][subcategory][item]

var turrets := {
	"gatling": {
		"stats": {
			"damage": 10,
			"attack_speed": 2.0,
			"attack_range": 200.0,
			"bulletSpeed": 200.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Gatling Gun",
		"cost": 50,
		"upgrade_cost": 50,
		"max_level": 2,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 4.0,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
	},
	"laser": {
		"stats": {
			"damage": 0.5,
			"attack_speed": 20.0,
			"attack_range": 250.0,
			"bulletSpeed": 400.0,
			"bulletPierce": 4,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Flamethrower",
		"cost": 70,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 1.0,
		"rotates": false,
		"bullet": "laser",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
	},
	"ray": {
		"stats": {
			"damage": 0.5,
			"attack_speed": 0.5,
			"attack_range": 300.0,
			"ray_duration": 1.0,
			"ray_length": 300.0,
		},
		"upgrades": {
			"damage": {"amount": 1.0, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
			"ray_length": {"amount": 1.5, "multiplies": true},
			"ray_duration": {"amount": 1.5, "multiplies": true},
		},
		"name": "Raygun",
		"cost": 30,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 1.0,
		"rotates": true,
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "ray",
	},
	"melee": {
		"stats": {
			"damage": 5.0,
			"attack_speed": 1.0,
			"attack_range": 100.0,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Explosive",
		"cost": 70,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/meleeTurret/meleeTurret.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 1.0,
		"rotates": false,
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "melee",
	},
	"arrow_tower": {
		"stats": {
			"damage": 15,
			"attack_speed": 1.2,
			"attack_range": 80.0,
			"bulletSpeed": 200.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 3.0, "multiplies": false},
			"attack_speed": {"amount": 1.3, "multiplies": true},
		},
		"name": "Arrow Tower",
		"cost": 50,
		"upgrade_cost": 40,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 3.0,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.05,
		"ta_bonus": 0.01,
		"passive_effect": "capture_tower_synergy",
		"aoe_type": "none",
		"special_mechanics": []
	},
	"capture_tower": {
		"stats": {
			"damage": 8,
			"attack_speed": 0.5,
			"attack_range": 100.0,
			"bulletSpeed": 150.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 2.0, "multiplies": false},
			"attack_speed": {"amount": 1.2, "multiplies": true},
		},
		"name": "Capture Tower",
		"cost": 75,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 3.5,
		"rotates": true,
		"bullet": "laser",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "attack_speed_aura",
		"aoe_type": "slow",
		"special_mechanics": ["slow_effect"]
	},
	"mage_tower": {
		"stats": {
			"damage": 45,
			"attack_speed": 0.33,
			"attack_range": 90.0,
			"bulletSpeed": 100.0,
			"bulletPierce": 5,
		},
		"upgrades": {
			"damage": {"amount": 8.0, "multiplies": false},
			"attack_speed": {"amount": 1.1, "multiplies": true},
		},
		"name": "Mage Tower",
		"cost": 120,
		"upgrade_cost": 80,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 4.0,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "mage_damage_synergy",
		"aoe_type": "circle",
		"special_mechanics": ["aoe_damage"]
	},
	"detection_tower": {
		"stats": {
			"damage": 0,
			"attack_speed": 0.0,
			"attack_range": 120.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
		},
		"upgrades": {
			"attack_range": {"amount": 20.0, "multiplies": false},
		},
		"name": "Detection Tower",
		"cost": 60,
		"upgrade_cost": 30,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 3.0,
		"rotates": false,
		"bullet": "none",
		"element": "light",
		"gem_slot": null,
		"turret_category": "support",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "stealth_detection",
		"aoe_type": "none",
		"special_mechanics": ["stealth_detection"]
	},
	"doomsday_tower": {
		"stats": {
			"damage": 25,
			"attack_speed": 0.05,
			"attack_range": 70.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
			"dot_damage": 25.0,
			"dot_duration": 5.0,
			"disable_duration": 2.0,
		},
		"upgrades": {
			"damage": {"amount": 10.0, "multiplies": false},
			"dot_damage": {"amount": 10.0, "multiplies": false},
		},
		"name": "Doomsday Tower",
		"cost": 200,
		"upgrade_cost": 120,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 5.0,
		"rotates": false,
		"bullet": "none",
		"element": "dark",
		"gem_slot": null,
		"turret_category": "special",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "ta_cooldown_reduction",
		"aoe_type": "circle",
		"special_mechanics": ["dot_damage", "disable_effect"]
	},
	"pulse_tower": {
		"stats": {
			"damage": 20,
			"attack_speed": 0.56,
			"attack_range": 85.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
			"pulse_interval": 3.0,
		},
		"upgrades": {
			"damage": {"amount": 5.0, "multiplies": false},
			"attack_speed": {"amount": 1.2, "multiplies": true},
		},
		"name": "Pulse Tower",
		"cost": 90,
		"upgrade_cost": 60,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 4.0,
		"rotates": false,
		"bullet": "none",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "special",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "adjacent_tower_boost",
		"aoe_type": "periodic_circle",
		"special_mechanics": ["periodic_aoe"]
	},
	"ricochet_tower": {
		"stats": {
			"damage": 12,
			"attack_speed": 0.67,
			"attack_range": 75.0,
			"bulletSpeed": 250.0,
			"bulletPierce": 1,
			"ricochet_count": 5,
		},
		"upgrades": {
			"damage": {"amount": 3.0, "multiplies": false},
			"ricochet_count": {"amount": 2, "multiplies": false},
		},
		"name": "Ricochet Tower",
		"cost": 80,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 3.5,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "unique_damage_bonus",
		"aoe_type": "bounce",
		"special_mechanics": ["ricochet_shots"]
	},
	"aura_tower": {
		"stats": {
			"damage": 0,
			"attack_speed": 0.0,
			"attack_range": 95.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
			"slow_strength": 0.3,
		},
		"upgrades": {
			"attack_range": {"amount": 15.0, "multiplies": false},
			"slow_strength": {"amount": 0.1, "multiplies": false},
		},
		"name": "Aura Tower",
		"cost": 70,
		"upgrade_cost": 40,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 4.0,
		"rotates": false,
		"bullet": "none",
		"element": "ice",
		"gem_slot": null,
		"turret_category": "support",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "adjacent_da_ta_boost",
		"aoe_type": "persistent_slow",
		"special_mechanics": ["persistent_slow"]
	},
	"weakness_tower": {
		"stats": {
			"damage": 10,
			"attack_speed": 1.25,
			"attack_range": 65.0,
			"bulletSpeed": 180.0,
			"bulletPierce": 1,
			"armor_reduction": 15,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"armor_reduction": {"amount": 5, "multiplies": false},
		},
		"name": "Weakness Tower",
		"cost": 65,
		"upgrade_cost": 45,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 3.0,
		"rotates": true,
		"bullet": "laser",
		"element": "dark",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "slowed_enemy_bonus",
		"aoe_type": "armor_reduce",
		"special_mechanics": ["armor_reduction"]
	},
}

func _ready():
	load_custom_turret_data()

# Combat balance configuration
const combat_settings := {
	"da_max_chance": 0.5,  # Maximum Double Attack chance (50%)
	"ta_max_chance": 0.25  # Maximum Triple Attack chance (25%)
}

func load_custom_turret_data():
	# 检查是否存在自定义炮塔数据文件
	var save_file_path = "user://saved_turrets/turret_data.json"
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var custom_data = json.data
				
				# 合并自定义数据到现有数据中
				for turret_id in custom_data.keys():
					if turrets.has(turret_id):
						# 更新现有炮塔数据
						merge_turret_data(turrets[turret_id], custom_data[turret_id])
					else:
						# 添加新的炮塔类型
						turrets[turret_id] = custom_data[turret_id]

func merge_turret_data(original: Dictionary, custom: Dictionary):
	# 递归合并字典数据
	for key in custom.keys():
		if original.has(key) and typeof(original[key]) == TYPE_DICTIONARY and typeof(custom[key]) == TYPE_DICTIONARY:
			merge_turret_data(original[key], custom[key])
		else:
			original[key] = custom[key]

const stats := {
	"damage": {"name": "Damage"},
	"attack_speed": {"name": "Speed"},
	"attack_range": {"name": "Range"},
	"bulletSpeed": {"name": "Bullet Speed"},
	"bulletPierce": {"name": "Bullet Pierce"},
	"ray_length": {"name": "Ray Length"},
	"ray_duration": {"name": "Ray Duration"},
}

const bullets := {
	"fire": {
		"frames": "res://Assets/bullets/bullet1.tres",
	},
	"laser": {
		"frames": "res://Assets/bullets/bullet2.tres",
	}
}

const enemies := {
	"redDino": {
		"stats": {
			"hp": 10.0,
			"defense": 15,
			"speed": 1.0,
			"baseDamage": 5.0,
			"goldYield": 10.0,
			},
		"difficulty": 1.0,
		"sprite": "res://Assets/enemies/dino1.png",
		"element": "neutral",
		"special_abilities": [],
		"monster_skills": ["frost_aura"],
		"skill_cooldowns": {"frost_aura": 8.0},
		"drop_table": {
			"base_chance": 0.05,
			"items": ["fire_basic", "ice_basic", "earth_basic"]
		}
	},
	"blueDino": {
		"stats": {
			"hp": 5.0,
			"defense": 10,
			"speed": 2.0,
			"baseDamage": 5.0,
			"goldYield": 10.0,
			},
		"difficulty": 2.0,
		"sprite": "res://Assets/enemies/dino2.png",
		"element": "ice",
		"special_abilities": [],
		"monster_skills": ["acceleration"],
		"skill_cooldowns": {"acceleration": 5.0},
		"drop_table": {
			"base_chance": 0.06,
			"items": ["ice_basic", "wind_basic"]
		}
	},
	"yellowDino": {
		"stats": {
			"hp": 10.0,
			"defense": 20,
			"speed": 5.0,
			"baseDamage": 1.0,
			"goldYield": 10.0,
			},
		"difficulty": 3.0,
		"sprite": "res://Assets/enemies/dino3.png",
		"element": "wind",
		"special_abilities": ["stealth"],
		"monster_skills": ["self_destruct"],
		"skill_cooldowns": {"self_destruct": 999.0},
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "light_basic"]
		}
	},
	"greenDino": {
		"stats": {
			"hp": 10.0,
			"defense": 25,
			"speed": 10.0,
			"baseDamage": 1.0,
			"goldYield": 10.0,
			},
		"difficulty": 4.0,
		"sprite": "res://Assets/enemies/dino4.png",
		"element": "earth",
		"special_abilities": ["split"],
		"monster_skills": ["petrification"],
		"skill_cooldowns": {"petrification": 7.0},
		"drop_table": {
			"base_chance": 0.07,
			"items": ["earth_basic", "dark_basic"]
		}
	},
	"stealthDino": {
		"stats": {
			"hp": 15.0,
			"defense": 30,
			"speed": 1.5,
			"baseDamage": 5.0,
			"goldYield": 15.0,
		},
		"element": "neutral",
		"special_abilities": ["stealth"],
		"monster_skills": ["acceleration"],
		"skill_cooldowns": {"acceleration": 5.0},
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "light_basic"]
		},
		"difficulty": 2.5,
		"sprite": "res://Assets/enemies/dino2.png"
	},
	"healerDino": {
		"stats": {
			"hp": 20.0,
			"defense": 40,
			"speed": 0.8,
			"baseDamage": 3.0,
			"goldYield": 20.0,
		},
		"element": "light",
		"special_abilities": ["heal"],
		"monster_skills": ["frost_aura"],
		"skill_cooldowns": {"frost_aura": 8.0},
		"drop_table": {
			"base_chance": 0.10,
			"items": ["light_basic", "light_intermediate"]
		},
		"difficulty": 3.5,
		"sprite": "res://Assets/enemies/dino1.png"
	}
}

# 元素系统数据
const elements := {
	"fire": {"name": "火", "color": Color.RED},
	"ice": {"name": "冰", "color": Color.CYAN}, 
	"wind": {"name": "风", "color": Color.GREEN},
	"earth": {"name": "土", "color": Color.SADDLE_BROWN},
	"light": {"name": "光", "color": Color.WHITE},
	"dark": {"name": "暗", "color": Color.BLACK},
	"neutral": {"name": "无属性", "color": Color.GRAY}
}

# 属性克制关系
const element_effectiveness := {
	"fire": {"strong_against": ["wind"], "weak_against": ["ice"]},
	"ice": {"strong_against": ["fire"], "weak_against": ["wind"]},
	"wind": {"strong_against": ["earth"], "weak_against": ["ice"]},
	"earth": {"strong_against": ["fire"], "weak_against": ["wind"]},
	"light": {"strong_against": ["dark"], "weak_against": ["dark"]},
	"dark": {"strong_against": ["light"], "weak_against": ["light"]},
	"neutral": {"strong_against": [], "weak_against": []}
}

# 宝石数据
const gems := {
	"fire_basic": {
		"name": "火焰宝石 1级",
		"element": "fire",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "火箭",
				"description": "命中单位受到灼烧DEBUFF",
				"effects": ["burn_debuff_1"]
			},
			"capture_tower": {
				"name": "火网",
				"description": "范围内所有敌方受到灼热",
				"effects": ["burn_area_1"]
			},
			"mage_tower": {
				"name": "火球",
				"description": "伤害增加20%，命中单位受到灼烧",
				"effects": ["damage_boost_20", "burn_debuff_1"]
			},
			"感应塔": {
				"name": "火捆",
				"description": "范围内的隐身单位受到2层灼烧，受到伤害增加5%",
				"effects": ["burn_debuff_2", "damage_taken_boost_5"]
			},
			"末日塔": {
				"name": "痛楚",
				"description": "伤害间隔降低0.2",
				"effects": ["damage_interval_reduction_0.2"]
			},
			"pulse_tower": {
				"name": "火焰脉冲",
				"description": "攻击范围内所有单位灼热",
				"effects": ["burn_area_1"]
			},
			"弹射塔": {
				"name": "火弹",
				"description": "被弹射目标灼热",
				"effects": ["burn_debuff_1"]
			},
			"aura_tower": {
				"name": "炽热光环",
				"description": "范围内所有塔的攻击速度+3%",
				"effects": ["attack_speed_boost_3"]
			},
			"weakness_tower": {
				"name": "高温",
				"description": "防御力降低5%，受到一层灼烧",
				"effects": ["defense_reduction_5", "burn_debuff_1"]
			}
		},
		"sprite": "res://Assets/gems/fire_basic.png"
	},
	"fire_intermediate": {
		"name": "炽热之心 2级",
		"element": "fire",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "炽火箭",
				"description": "命中单位受到3层灼烧，对风属性伤害增加10%",
				"effects": ["burn_debuff_3", "wind_damage_boost_10"]
			},
			"capture_tower": {
				"name": "焦油火网",
				"description": "受到灼热3层，移动速度降低30%，持续4秒",
				"effects": ["burn_debuff_3", "slow_30"]
			},
			"mage_tower": {
				"name": "天火炼狱",
				"description": "伤害增加30%，范围内造成火海持续4秒，所有目标受到3层灼烧",
				"effects": ["damage_boost_30", "fire_field_4s", "burn_debuff_3"]
			},
			"感应塔": {
				"name": "火牢",
				"description": "范围内的隐身单位受到3层灼烧，受到伤害增加10%",
				"effects": ["burn_debuff_3", "damage_taken_boost_10"]
			},
			"末日塔": {
				"name": "窒息烟尘",
				"description": "伤害间隔降低0.25，持续时间增加10S",
				"effects": ["damage_interval_reduction_0.25", "duration_increase_10s"]
			},
			"pulse_tower": {
				"name": "震荡脉冲",
				"description": "攻击范围内所有单位3层灼烧，打断技能引导，25%几率禁锢0.5秒",
				"effects": ["burn_debuff_3", "interrupt_cast", "imprison_chance_25_0.5s"]
			},
			"弹射塔": {
				"name": "炎爆弹射",
				"description": "被弹射目标灼热3层，对单位造成0.1S炭化",
				"effects": ["burn_debuff_3", "carbonization_0.1s"]
			},
			"aura_tower": {
				"name": "炎热光环",
				"description": "范围内所有塔的攻击速度+5%，充能速度加10%",
				"effects": ["attack_speed_boost_5", "charge_speed_boost_10"]
			},
			"weakness_tower": {
				"name": "中暑",
				"description": "防御力降低10%，受到五层灼烧",
				"effects": ["defense_reduction_10", "burn_debuff_5"]
			}
		},
		"sprite": "res://Assets/gems/fire_intermediate.png"
	},
	"fire_advanced": {
		"name": "炎狱之魂 3级",
		"element": "fire",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "炙热火雨",
				"description": "单体攻击变为3目标攻击，命中单位受到5层灼烧，对风属性伤害增加30%",
				"effects": ["multi_target_3", "burn_debuff_5", "wind_damage_boost_30"]
			},
			"capture_tower": {
				"name": "炭化领域",
				"description": "施放焦油火网，同时在目标范围生成炭化地面，敌人在范围内停留超过2.5秒受到炭化，持续1.5秒",
				"effects": ["burn_debuff_3", "slow_30", "carbonization_field_2.5s"]
			},
			"mage_tower": {
				"name": "超新星引爆",
				"description": "伤害增加50%，范围内造成火海持续4秒，火海内死亡的敌人爆炸，对周围敌人造成伤害并增加5层灼热",
				"effects": ["damage_boost_50", "fire_field_4s", "death_explosion"]
			},
			"感应塔": {
				"name": "火狱",
				"description": "范围内的隐身单位立即受到2S禁锢和5层灼烧，受到伤害增加20%",
				"effects": ["imprison_2s", "burn_debuff_5", "damage_taken_boost_20"]
			},
			"末日塔": {
				"name": "热死病",
				"description": "持续时间无限，伤害间隔降低0.3",
				"effects": ["duration_infinite", "damage_interval_reduction_0.3"]
			},
			"pulse_tower": {
				"name": "地狱火风暴",
				"description": "每次脉冲将范围内所有敌人向外推开，70%炭化0.75秒，敌人变得脆弱，受到伤害增加25%持续3秒",
				"effects": ["knockback_enemies", "carbonization_chance_70_0.75s", "vulnerability_25"]
			},
			"弹射塔": {
				"name": "爆燃连锁",
				"description": "对单位造成0.5S炭化，弹射到的目标灼热层数越高伤害越高，倍率=1+(层数+25)/100",
				"effects": ["carbonization_0.5s", "chain_damage_multiplier"]
			},
			"aura_tower": {
				"name": "炙热光环",
				"description": "范围内所有塔的攻击速度+10%，充能速度加20%",
				"effects": ["attack_speed_boost_10", "charge_speed_boost_20"]
			},
			"weakness_tower": {
				"name": "热射病",
				"description": "防御力降低15%，受到八层灼烧",
				"effects": ["defense_reduction_15", "burn_debuff_8"]
			}
		},
		"sprite": "res://Assets/gems/fire_advanced.png"
	},
	"ice_basic": {
		"name": "初级冰宝石",
		"element": "ice",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/ice_basic.png"
	},
	"ice_intermediate": {
		"name": "中级冰宝石",
		"element": "ice",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/ice_intermediate.png"
	},
	"ice_advanced": {
		"name": "高级冰宝石",
		"element": "ice",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/ice_advanced.png"
	},
	"wind_basic": {
		"name": "初级风宝石",
		"element": "wind",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/wind_basic.png"
	},
	"wind_intermediate": {
		"name": "中级风宝石",
		"element": "wind",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/wind_intermediate.png"
	},
	"wind_advanced": {
		"name": "高级风宝石",
		"element": "wind",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/wind_advanced.png"
	},
	"earth_basic": {
		"name": "初级土宝石",
		"element": "earth",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/earth_basic.png"
	},
	"earth_intermediate": {
		"name": "中级土宝石",
		"element": "earth",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/earth_intermediate.png"
	},
	"earth_advanced": {
		"name": "高级土宝石",
		"element": "earth",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/earth_advanced.png"
	},
	"light_basic": {
		"name": "初级光宝石",
		"element": "light",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/light_basic.png"
	},
	"light_intermediate": {
		"name": "中级光宝石",
		"element": "light",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/light_intermediate.png"
	},
	"light_advanced": {
		"name": "高级光宝石",
		"element": "light",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/light_advanced.png"
	},
	"dark_basic": {
		"name": "初级暗宝石",
		"element": "dark",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/dark_basic.png"
	},
	"dark_intermediate": {
		"name": "中级暗宝石",
		"element": "dark",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/dark_intermediate.png"
	},
	"dark_advanced": {
		"name": "高级暗宝石",
		"element": "dark",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/dark_advanced.png"
	}
}

# 效果定义
const effects := {
	# 灼烧效果
	"burn_debuff_1": {
		"type": "debuff",
		"debuff_type": "burn",
		"stacks": 1,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"burn_debuff_3": {
		"type": "debuff", 
		"debuff_type": "burn",
		"stacks": 3,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"burn_debuff_5": {
		"type": "debuff",
		"debuff_type": "burn", 
		"stacks": 5,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"burn_debuff_8": {
		"type": "debuff",
		"debuff_type": "burn", 
		"stacks": 8,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	
	# 属性修改器
	"damage_boost_20": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.20
	},
	"damage_boost_30": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.30
	},
	"damage_boost_50": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.50
	},
	
	# 攻击修改器
	"multi_target_3": {
		"type": "attack_modifier",
		"property": "target_count",
		"value": 3
	},
	"multi_target_5": {
		"type": "attack_modifier",
		"property": "target_count",
		"value": 5
	},
	
	# 伤害修改器
	"wind_damage_boost_10": {
		"type": "damage_modifier",
		"target_element": "wind",
		"multiplier": 1.10
	},
	"wind_damage_boost_30": {
		"type": "damage_modifier",
		"target_element": "wind",
		"multiplier": 1.30
	},
	
	# 防御修改器
	"defense_reduction_5": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.95
	},
	"defense_reduction_10": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.90
	},
	"defense_reduction_15": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.85
	},
	
	# 攻速修改器
	"attack_speed_boost_3": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.03
	},
	"attack_speed_boost_5": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.05
	},
	"attack_speed_boost_10": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.10
	},
	
	# 充能速度修改器
	"charge_speed_boost_10": {
		"type": "stat_modifier",
		"stat": "charge_speed",
		"operation": "multiply",
		"value": 1.10
	},
	"charge_speed_boost_20": {
		"type": "stat_modifier",
		"stat": "charge_speed",
		"operation": "multiply",
		"value": 1.20
	},
	
	# 伤害间隔修改器
	"damage_interval_reduction_0.2": {
		"type": "stat_modifier",
		"stat": "damage_interval",
		"operation": "add",
		"value": -0.2
	},
	"damage_interval_reduction_0.25": {
		"type": "stat_modifier",
		"stat": "damage_interval",
		"operation": "add",
		"value": -0.25
	},
	"damage_interval_reduction_0.3": {
		"type": "stat_modifier",
		"stat": "damage_interval",
		"operation": "add",
		"value": -0.3
	},
	
	# 特殊效果
	"carbonization_0.1s": {
		"type": "debuff",
		"debuff_type": "炭化",
		"duration": 0.1
	},
	"carbonization_0.5s": {
		"type": "debuff",
		"debuff_type": "炭化",
		"duration": 0.5
	},
	"carbonization_1.5s": {
		"type": "debuff",
		"debuff_type": "炭化",
		"duration": 1.5
	},
	"imprison_2s": {
		"type": "debuff",
		"debuff_type": "禁锢",
		"duration": 2.0
	},
	"vulnerability_25": {
		"type": "debuff",
		"debuff_type": "脆弱",
		"damage_increase": 0.25,
		"duration": 3.0
	},
	
	# 移动速度修改器
	"slow_30": {
		"type": "stat_modifier",
		"stat": "movement_speed",
		"operation": "multiply",
		"value": 0.70,
		"duration": 4.0
	},
	
	# 伤害承受增加
	"damage_taken_boost_5": {
		"type": "stat_modifier",
		"stat": "damage_taken",
		"operation": "multiply",
		"value": 1.05,
		"duration": 3.0
	},
	"damage_taken_boost_10": {
		"type": "stat_modifier",
		"stat": "damage_taken",
		"operation": "multiply",
		"value": 1.10,
		"duration": 3.0
	},
	"damage_taken_boost_20": {
		"type": "stat_modifier",
		"stat": "damage_taken",
		"operation": "multiply",
		"value": 1.20,
		"duration": 3.0
	},
	
	# 特殊效果（占位符，后续实现）
	"burn_area_1": {
		"type": "special",
		"effect_type": "area_burn",
		"stacks": 1
	},
	"burn_debuff_2": {
		"type": "debuff",
		"debuff_type": "burn",
		"stacks": 2,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"duration_increase_10s": {
		"type": "stat_modifier",
		"stat": "effect_duration",
		"operation": "add",
		"value": 10.0
	},
	"interrupt_cast": {
		"type": "special",
		"effect_type": "interrupt"
	},
	"imprison_chance_25_0.5s": {
		"type": "special",
		"effect_type": "chance_imprison",
		"chance": 0.25,
		"duration": 0.5
	},
	"duration_infinite": {
		"type": "special",
		"effect_type": "infinite_duration"
	},
	"knockback_enemies": {
		"type": "special",
		"effect_type": "knockback"
	},
	"carbonization_chance_70_0.75s": {
		"type": "special",
		"effect_type": "chance_carbonization",
		"chance": 0.70,
		"duration": 0.75
	},
	"chain_damage_multiplier": {
		"type": "special",
		"effect_type": "chain_multiplier"
	},
	"fire_field_4s": {
		"type": "special",
		"effect_type": "fire_field",
		"duration": 4.0
	},
	"death_explosion": {
		"type": "special",
		"effect_type": "explosion_on_death"
	},
	"carbonization_field_2.5s": {
		"type": "special",
		"effect_type": "carbonization_field",
		"trigger_time": 2.5,
		"duration": 1.5
	}
}

# 武器盘BUFF数据
const weapon_wheel_buffs := {
	"projectile_damage": {
		"name": "投射物伤害",
		"applies_to": ["gatling", "laser"],
		"bonus": 0.05
	},
	"ray_damage": {
		"name": "射线伤害", 
		"applies_to": ["ray"],
		"bonus": 0.08
	},
	"melee_damage": {
		"name": "近战伤害",
		"applies_to": ["melee"], 
		"bonus": 0.06
	},
	"fire_element": {
		"name": "火元素强化",
		"element_type": "fire",
		"bonus": 0.10
	},
	"ice_element": {
		"name": "冰元素强化",
		"element_type": "ice",
		"bonus": 0.10
	},
	"wind_element": {
		"name": "风元素强化",
		"element_type": "wind",
		"bonus": 0.10
	},
	"earth_element": {
		"name": "土元素强化",
		"element_type": "earth",
		"bonus": 0.10
	},
	"light_element": {
		"name": "光元素强化",
		"element_type": "light",
		"bonus": 0.10
	},
	"dark_element": {
		"name": "暗元素强化",
		"element_type": "dark",
		"bonus": 0.10
	}
}

const maps := {
	"map1": {
		"name": "Grass Map",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 10,
		"startingGold": 100,
		"spawner_settings":
			{
			"difficulty": {"initial": 2.0, "increase": 1.5, "multiplies": true},
			"max_waves": 10,
			"wave_spawn_count": 10,
			"special_waves": {},
			},
	},
	"map2": {
		"name": "Desert Map",
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 15,
		"startingGold": 200,
		"spawner_settings":
			{
			"difficulty": {"initial": 1.0, "increase": 1.2, "multiplies": true},
			"max_waves": 10,
			"wave_spawn_count": 10,
			"special_waves": {},
			},
	},
	# Chapter 1 Maps
	"chapter1_level1": {
		"name": "Chapter 1 - Level 1",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 20,
		"startingGold": 150,
		"chapter": 1,
		"level": 1,
		"spawner_settings": {
			"difficulty": {"initial": 1.0, "increase": 1.1, "multiplies": true},
			"max_waves": 20,
			"wave_spawn_count": 8,
			"special_waves": {
				10: {"enemy_type": "redDino", "count": 15},
				20: {"enemy_type": "blueDino", "count": 5}
			},
		},
	},
	"chapter1_level2": {
		"name": "Chapter 1 - Level 2", 
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 20,
		"startingGold": 150,
		"chapter": 1,
		"level": 2,
		"spawner_settings": {
			"difficulty": {"initial": 1.2, "increase": 1.15, "multiplies": true},
			"max_waves": 20,
			"wave_spawn_count": 10,
			"special_waves": {
				5: {"enemy_type": "redDino", "count": 12},
				15: {"enemy_type": "blueDino", "count": 8},
				20: {"enemy_type": "yellowDino", "count": 3}
			},
		},
	},
	"chapter1_level3": {
		"name": "Chapter 1 - Level 3",
		"bg": "res://Assets/maps/map1.webp", 
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 25,
		"startingGold": 200,
		"chapter": 1,
		"level": 3,
		"spawner_settings": {
			"difficulty": {"initial": 1.5, "increase": 1.2, "multiplies": true},
			"max_waves": 30,
			"wave_spawn_count": 12,
			"special_waves": {
				10: {"enemy_type": "redDino", "count": 20},
				20: {"enemy_type": "blueDino", "count": 15},
				25: {"enemy_type": "yellowDino", "count": 8},
				30: {"enemy_type": "greenDino", "count": 5}
			},
		},
	},
	"chapter1_level4": {
		"name": "Chapter 1 - Level 4",
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 30,
		"startingGold": 250,
		"chapter": 1,
		"level": 4,
		"spawner_settings": {
			"difficulty": {"initial": 2.0, "increase": 1.25, "multiplies": true},
			"max_waves": 30,
			"wave_spawn_count": 15,
			"special_waves": {
				8: {"enemy_type": "stealthDino", "count": 10},
				16: {"enemy_type": "yellowDino", "count": 12},
				24: {"enemy_type": "greenDino", "count": 8},
				30: {"enemy_type": "healerDino", "count": 5}
			},
		},
	},
	"chapter1_level5": {
		"name": "Chapter 1 - Level 5 (Boss)",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 50,
		"startingGold": 300,
		"chapter": 1,
		"level": 5,
		"spawner_settings": {
			"difficulty": {"initial": 2.5, "increase": 1.3, "multiplies": true},
			"max_waves": 50,
			"wave_spawn_count": 20,
			"special_waves": {
				10: {"enemy_type": "redDino", "count": 30},
				20: {"enemy_type": "blueDino", "count": 25},
				30: {"enemy_type": "stealthDino", "count": 15},
				40: {"enemy_type": "greenDino", "count": 12},
				45: {"enemy_type": "healerDino", "count": 8},
				50: {"enemy_type": "healerDino", "count": 10}  # Final boss wave
			},
		},
	}
}

# Charge System Configuration
const charge_system := {
	"max_charge": 100,
	"charge_per_attack": {
		"arrow_tower": 8,
		"capture_tower": 12,
		"mage_tower": 15
	},
	"charge_abilities": {
		"arrow_tower": {
			"name": "剑雨",
			"description": "小范围AOE，在目标区域施放15支箭",
			"range": 120.0,
			"arrow_count": 15,
			"damage_multiplier": 0.8
		},
		"capture_tower": {
			"name": "刺网", 
			"description": "捕获网范围增加100%，被捕单位防御力降低15%",
			"range_multiplier": 2.0,
			"armor_reduction": 0.15,
			"duration": 3.0
		},
		"mage_tower": {
			"name": "激活",
			"description": "攻击速度增加30%，持续3S",
			"speed_bonus": 0.30,
			"duration": 3.0
		}
	}
}

# Summon Stone Configuration
const summon_stones := {
	"shiva": {
		"name": "湿婆",
		"description": "所有塔攻击力+150%，持续15S",
		"cooldown": 180.0,
		"duration": 15.0,
		"effect_type": "global_damage_boost",
		"damage_multiplier": 2.5,
		"icon": "res://Assets/summon_stones/shiva.png"
	},
	"lucifer": {
		"name": "路西法",
		"description": "圆形范围内共造成2000点光属性伤害",
		"cooldown": 120.0,
		"effect_type": "targeted_damage",
		"damage": 2000,
		"element": "light",
		"range": 150.0,
		"icon": "res://Assets/summon_stones/lucifer.png"
	},
	"europa": {
		"name": "欧罗巴",
		"description": "圆形范围内共造成1200点冰属性伤害，并冻结所有单位2s",
		"cooldown": 180.0,
		"effect_type": "freeze_damage",
		"damage": 1200,
		"element": "ice",
		"range": 180.0,
		"freeze_duration": 2.0,
		"icon": "res://Assets/summon_stones/europa.png"
	},
	"titan": {
		"name": "泰坦",
		"description": "对所有塔充能30，伤害增加30%，持续5S",
		"cooldown": 120.0,
		"effect_type": "charge_and_damage",
		"charge_bonus": 30,
		"damage_bonus": 0.30,
		"duration": 5.0,
		"icon": "res://Assets/summon_stones/titan.png"
	},
	"zeus": {
		"name": "宙斯",
		"description": "驱散范围内敌方的BUFF，造成1500点光属性伤害",
		"cooldown": 180.0,
		"effect_type": "dispel_damage",
		"damage": 1500,
		"element": "light",
		"range": 200.0,
		"icon": "res://Assets/summon_stones/zeus.png"
	}
}

# Tower Tech Tree Configuration - Individual tower progression
const tower_tech_tree := {
	"arrow_tower": {
		"name": "箭塔科技",
		"1": {
			"name": "基础箭塔",
			"description": "标准弓箭手塔",
			"cost": 0,
			"unlocked": true,
			"gem_slot_level": 1
		},
		"2a": {
			"name": "精准射手",
			"description": "提高命中率和射程",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"attack_range": 0.3, "da_bonus": 0.1}
		},
		"2b": {
			"name": "连射弓手",
			"description": "提高攻击速度和多重攻击",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"attack_speed": 0.4, "ta_bonus": 0.05}
		},
		"3a": {
			"name": "神射手",
			"description": "极致精准，必定暴击",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"attack_range": 0.5, "da_bonus": 0.2, "damage": 0.3}
		},
		"3b": {
			"name": "穿透射手",
			"description": "箭矢可穿透多个敌人",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"pierce": 2, "damage": 0.2}
		},
		"3c": {
			"name": "暴雨射手",
			"description": "极快攻速，连射不断",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"attack_speed": 0.8, "ta_bonus": 0.1}
		},
		"3d": {
			"name": "多重射手",
			"description": "每次攻击发射多支箭",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"multi_shot": 3, "damage": 0.15}
		}
	},
	"capture_tower": {
		"name": "捕获塔科技",
		"1": {
			"name": "基础捕获塔",
			"description": "标准减速塔",
			"cost": 0,
			"unlocked": true,
			"gem_slot_level": 1
		},
		"2a": {
			"name": "冰霜陷阱",
			"description": "冰冻效果，范围伤害",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"aoe_range": 50.0, "slow_strength": 0.3}
		},
		"2b": {
			"name": "蛛网陷阱",
			"description": "强力减速，持续时间长",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"slow_duration": 0.8, "damage": 0.2}
		},
		"3a": {
			"name": "急冻领域",
			"description": "大范围冰冻，冰系伤害",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"aoe_range": 80.0, "freeze_chance": 0.3, "element": "ice"}
		},
		"3b": {
			"name": "寒冰风暴",
			"description": "冰暴攻击，群体减速",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"aoe_damage": 30.0, "attack_speed": 0.3}
		},
		"3c": {
			"name": "剧毒蛛网",
			"description": "毒性减速，持续伤害",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"dot_damage": 20.0, "slow_strength": 0.5}
		},
		"3d": {
			"name": "束缚之网",
			"description": "强力定身，防御削弱",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"immobilize": true, "armor_reduction": 0.4}
		}
	},
	"mage_tower": {
		"name": "法师塔科技",
		"1": {
			"name": "基础法师塔",
			"description": "标准魔法塔",
			"cost": 0,
			"unlocked": true,
			"gem_slot_level": 1
		},
		"2a": {
			"name": "元素法师",
			"description": "精通元素魔法",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"elemental_damage": 0.4, "aoe_range": 20.0}
		},
		"2b": {
			"name": "奥术法师",
			"description": "纯粹魔法力量",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"damage": 0.5, "mana_efficiency": 0.3}
		},
		"3a": {
			"name": "风暴法师",
			"description": "雷电风暴，链式伤害",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"chain_lightning": 3, "element": "wind"}
		},
		"3b": {
			"name": "烈焰法师",
			"description": "火焰爆炸，灼烧效果",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"explosion_damage": 80.0, "element": "fire", "burn_dot": 15.0}
		},
		"3c": {
			"name": "秘法大师",
			"description": "纯能量伤害，无视防御",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"damage": 0.8, "ignore_armor": true}
		},
		"3d": {
			"name": "时空法师",
			"description": "时间操控，减速敌人",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"time_slow": 0.4, "damage": 0.4, "area_effect": true}
		}
	}
}

# Tech Tree Configuration with Tech Points
const tech_tree := {
	"damage_boost": {
		"name": "伤害强化",
		"description": "所有炮塔伤害+10%",
		"cost": 1,
		"max_level": 5,
		"unlocked": false,
		"requirements": []
	},
	"attack_speed_boost": {
		"name": "攻速强化",
		"description": "所有炮塔攻速+8%",
		"cost": 1,
		"max_level": 5,
		"unlocked": false,
		"requirements": []
	},
	"range_boost": {
		"name": "射程强化",
		"description": "所有炮塔射程+15%",
		"cost": 1,
		"max_level": 3,
		"unlocked": false,
		"requirements": []
	},
	"da_chance_boost": {
		"name": "连击强化",
		"description": "DA几率+5%",
		"cost": 2,
		"max_level": 3,
		"unlocked": false,
		"requirements": ["damage_boost"]
	},
	"ta_chance_boost": {
		"name": "三连击强化", 
		"description": "TA几率+3%",
		"cost": 3,
		"max_level": 2,
		"unlocked": false,
		"requirements": ["da_chance_boost"]
	},
	"charge_speed_boost": {
		"name": "充能加速",
		"description": "充能获取速度+50%",
		"cost": 2,
		"max_level": 3,
		"unlocked": false,
		"requirements": ["attack_speed_boost"]
	},
	"economic_boost": {
		"name": "经济强化",
		"description": "击杀敌人金币+20%",
		"cost": 1,
		"max_level": 4,
		"unlocked": false,
		"requirements": []
	},
	"wave_preparation": {
		"name": "战术准备",
		"description": "波次间隔时间+10秒",
		"cost": 1,
		"max_level": 3,
		"unlocked": false,
		"requirements": []
	},
	"projectile_speed_boost": {
		"name": "弹道加速",
		"description": "投射物速度+25%",
		"cost": 2,
		"max_level": 4,
		"unlocked": false,
		"requirements": ["attack_speed_boost"]
	}
}

# Tower Mechanics Configuration
const tower_mechanics := {
	"ricochet_shots": {
		"description": "子弹在敌人间弹射",
		"max_bounces": 5,
		"bounce_range": 80.0,
		"damage_falloff": 0.9
	},
	"periodic_aoe": {
		"description": "周期性区域伤害",
		"pulse_interval": 3.0,
		"range_multiplier": 1.0
	},
	"persistent_slow": {
		"description": "持续范围减速",
		"slow_strength": 0.3,
		"tick_interval": 0.5
	},
	"dot_damage": {
		"description": "持续伤害效果",
		"dot_duration": 15.0,
		"tick_interval": 1.0,
		"damage_per_tick": 25.0
	},
	"armor_reduction": {
		"description": "降低护甲效果",
		"reduction_amount": 0.05,
		"max_stacks": 10,
		"duration": 5.0
	}
}
