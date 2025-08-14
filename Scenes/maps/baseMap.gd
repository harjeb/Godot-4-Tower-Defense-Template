extends Node2D

# Import required classes
const PassiveSynergyManager = preload("res://Scenes/systems/PassiveSynergyManager.gd")
const MonsterSkillSystem = preload("res://Scenes/systems/MonsterSkillSystem.gd")
const PerformanceMonitor = preload("res://Scenes/systems/PerformanceMonitor.gd")

var map_type := "":
	set(val):
		map_type = val
		baseHP = Data.maps[val]["baseHp"]
		baseMaxHp = Data.maps[val]["baseHp"]
		gold = Data.maps[val]["startingGold"]
		$PathSpawner.map_type = val

var gameOver := false
var baseMaxHp := 20.0
var baseHP := baseMaxHp
var gold := 100:
	set(value):
		gold = value
		Globals.gold_changed.emit(value)

func _ready():
	Globals.turrets_node = $Turrets
	Globals.projectiles_node = $Projectiles
	Globals.current_map = self
	
	# Initialize enhancement systems
	initialize_enhancement_systems()

func get_base_damage(damage):
	if gameOver:
		return
	baseHP -= damage
	Globals.base_hp_changed.emit(baseHP, baseMaxHp)
	if baseHP <= 0:
		gameOver = true
		var gameOverPanelScene := preload("res://Scenes/ui/gameOver/game_over_panel.tscn")
		var gameOverPanel := gameOverPanelScene.instantiate()
		Globals.hud.add_child(gameOverPanel)

## Initialize the enhancement systems for the map
func initialize_enhancement_systems():
	# Create and add PassiveSynergyManager
	var synergy_manager = PassiveSynergyManager.new()
	synergy_manager.name = "PassiveSynergyManager"
	add_child(synergy_manager)
	
	# Create and add MonsterSkillSystem
	var monster_skill_system = MonsterSkillSystem.new()
	monster_skill_system.name = "MonsterSkillSystem"
	add_child(monster_skill_system)
	
	# Create and add PerformanceMonitor
	var performance_monitor = PerformanceMonitor.new()
	performance_monitor.name = "PerformanceMonitor"
	add_child(performance_monitor)
	
	# Connect performance monitor signals
	performance_monitor.performance_warning.connect(_on_performance_warning)
	performance_monitor.performance_critical.connect(_on_performance_critical)
	
	print("Tower Defense Enhancement Systems initialized successfully")

## Handle performance warnings
func _on_performance_warning(metric: String, current_value: float, threshold: float):
	# 显示性能警告弹框
	if ErrorHandler and ErrorHandler.has_method("show_warning"):
		ErrorHandler.show_warning("性能警告: %s 当前值 %.1f (阈值: %.1f)" % [metric, current_value, threshold], "性能警告")

## Handle critical performance issues
func _on_performance_critical(metric: String, current_value: float):
	# 显示严重性能问题弹框
	if ErrorHandler and ErrorHandler.has_method("show_error"):
		ErrorHandler.show_error("严重性能问题: %s 当前值 %.1f" % [metric, current_value], "性能错误")
