extends Node
class_name MockHeroManager

## Mock Hero Manager for testing
## Simulates hero manager functionality without requiring full game state

signal hero_selection_available(available_heroes: Array[String])
signal hero_selection_completed(selected_hero: String)
signal hero_deployed(hero: HeroBase, position: Vector2)
signal hero_died(hero: HeroBase)
signal hero_respawned(hero: HeroBase)

var deployed_heroes: Array[HeroBase] = []
var current_wave: int = 1
var max_heroes: int = 5

func _ready():
	pass

func deploy_hero(hero_type: String, position: Vector2) -> HeroBase:
	"""Deploy a hero at specified position"""
	if deployed_heroes.size() >= max_heroes:
		return null
	
	var hero_scene = Data.load_resource_safe("res://Scenes/heroes/%s.tscn" % hero_type, "PackedScene")
	if not hero_scene:
		return null
	
	var hero = hero_scene.instantiate() as HeroBase
	if hero:
		get_parent().add_child(hero)
		hero.hero_type = hero_type
		hero.setup_hero_data()
		hero.global_position = position
		hero.respawn_hero()
		
		deployed_heroes.append(hero)
		hero_deployed.emit(hero, position)
		
		# Connect to hero signals
		hero.died.connect(_on_hero_died.bind(hero))
		hero.respawned.connect(_on_hero_respawned.bind(hero))
	
	return hero

func has_deployed_heroes() -> bool:
	"""Check if any heroes are deployed"""
	return deployed_heroes.size() > 0

func get_deployed_hero_count() -> int:
	"""Get number of deployed heroes"""
	return deployed_heroes.size()

func trigger_hero_selection(available_heroes: Array[String]):
	"""Trigger hero selection for testing"""
	hero_selection_available.emit(available_heroes)

func complete_hero_selection(selected_hero: String):
	"""Complete hero selection for testing"""
	hero_selection_completed.emit(selected_hero)

func _on_hero_died(hero: HeroBase):
	"""Handle hero death"""
	hero_died.emit(hero)

func _on_hero_respawned(hero: HeroBase):
	"""Handle hero respawn"""
	hero_respawned.emit(hero)

func remove_hero(hero: HeroBase):
	"""Remove a hero from deployment"""
	var index = deployed_heroes.find(hero)
	if index >= 0:
		deployed_heroes.remove_at(index)
		if is_instance_valid(hero):
			hero.queue_free()

func get_hero_at_position(position: Vector2, tolerance: float = 50.0) -> HeroBase:
	"""Get hero at specific position"""
	for hero in deployed_heroes:
		if hero.global_position.distance_to(position) <= tolerance:
			return hero
	return null

func clear_all_heroes():
	"""Remove all deployed heroes"""
	for hero in deployed_heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	deployed_heroes.clear()