extends Node

static func roll_drop(enemy_data: Dictionary) -> String:
	if not enemy_data.has("drop_table"):
		return ""
	
	var drop_table = enemy_data.drop_table
	var base_chance = drop_table.base_chance
	
	if randf() <= base_chance:
		var items = drop_table.items
		if items.size() > 0:
			return items[randi() % items.size()]
	
	return ""

static func create_drop_item(item_id: String, position: Vector2) -> ItemDrop:
	var item_drop = preload("res://Scenes/items/ItemDrop.gd").new()
	item_drop.name = "ItemDrop_" + item_id
	item_drop.item_id = item_id
	item_drop.position = position
	
	# 创建必要的子节点
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	item_drop.add_child(sprite)
	
	var area = Area2D.new()
	area.name = "PickupArea"
	item_drop.add_child(area)
	
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	area.add_child(collision)
	
	return item_drop

static func _on_pickup_area_entered(body: Node, drop_item: Node2D):
	# 这个函数暂时留空，等后续实现玩家拾取逻辑
	pass

static func _on_pickup_area_entered_area(area: Area2D, drop_item: Node2D):
	# 这个函数也暂时留空，等后续实现拾取逻辑
	pass

static func pickup_item(drop_item: Node2D) -> bool:
	if not drop_item.has_meta("item_id") or not drop_item.get_meta("pickup_ready"):
		return false
	
	var item_id = drop_item.get_meta("item_id")
	var inventory_manager = get_inventory_manager()
	
	if inventory_manager and inventory_manager.add_item(item_id, 1):
		# 播放拾取效果
		var tween = drop_item.create_tween()
		tween.parallel().tween_property(drop_item, "scale", Vector2.ZERO, 0.3)
		tween.parallel().tween_property(drop_item, "modulate:a", 0.0, 0.3)
		tween.tween_callback(drop_item.queue_free)
		
		drop_item.set_meta("pickup_ready", false)
		return true
	
	return false

static func get_inventory_manager() -> InventoryManager:
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		var inventory_manager = tree.get_nodes_in_group("inventory_manager")
		if inventory_manager.size() > 0:
			return inventory_manager[0] as InventoryManager
		
		# 尝试从根节点查找
		var root = tree.root
		return root.get_node_or_null("InventoryManager") as InventoryManager
	
	return null

static func create_pickup_effect(position: Vector2, color: Color = Color.WHITE) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.current_scene:
		return
	
	# 创建简单的拾取特效
	var effect = Node2D.new()
	effect.position = position
	tree.current_scene.add_child(effect)
	
	# 添加多个粒子来模拟拾取效果
	for i in range(5):
		var particle = Sprite2D.new()
		var texture = PlaceholderTexture2D.new()
		texture.size = Vector2(4, 4)
		particle.texture = texture
		particle.modulate = color
		effect.add_child(particle)
		
		# 随机方向和速度
		var angle = randf() * PI * 2
		var speed = randf_range(50, 100)
		var direction = Vector2(cos(angle), sin(angle))
		
		var tween = effect.create_tween()
		tween.parallel().tween_property(particle, "position", direction * speed, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
	
	# 清理特效
	var cleanup_tween = effect.create_tween()
	cleanup_tween.tween_delay(0.6)
	cleanup_tween.tween_callback(effect.queue_free)
