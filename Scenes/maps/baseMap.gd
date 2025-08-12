extends Node2D

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
		Globals.goldChanged.emit(value)

func _ready():
	Globals.turretsNode = $Turrets
	Globals.projectilesNode = $Projectiles
	Globals.currentMap = self
	
	# Initialize enhancement systems
	initialize_enhancement_systems()

func get_base_damage(damage):
	if gameOver:
		return
	baseHP -= damage
	Globals.baseHpChanged.emit(baseHP, baseMaxHp)
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
	print("Performance Warning - %s: %.1f (threshold: %.1f)" % [metric, current_value, threshold])
	# Could show UI warning to player

## Handle critical performance issues
func _on_performance_critical(metric: String, current_value: float):
	print("Performance Critical - %s: %.1f" % [metric, current_value])
	# Could show UI warning and suggest reducing settings
