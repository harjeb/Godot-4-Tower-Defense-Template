extends Node2D
class_name ItemDrop

signal item_picked_up(item_id: String)

@export var item_id: String = ""
@export var pickup_range: float = 32.0
@export var auto_pickup_delay: float = 0.5

var pickup_ready: bool = false
var auto_pickup_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $PickupArea
@onready var collision: CollisionShape2D = $PickupArea/CollisionShape2D

func _ready():
	# 设置初始状态
	pickup_ready = false
	auto_pickup_timer = auto_pickup_delay
	
	# 连接信号
	if area:
		area.body_entered.connect(_on_pickup_area_entered)
		area.area_entered.connect(_on_pickup_area_entered_area)
	
	# 设置视觉效果
	setup_visual()
	
	# 添加浮动动画
	add_floating_animation()

func _process(delta):
	if auto_pickup_timer > 0:
		auto_pickup_timer -= delta
		if auto_pickup_timer <= 0:
			pickup_ready = true

func setup_visual():
	if item_id == "":
		return
		
	# 设置精灵纹理和颜色
	if sprite:
		# 创建占位符纹理（因为实际的宝石资源可能不存在）
		var texture = PlaceholderTexture2D.new()
		texture.size = Vector2(24, 24)
		sprite.texture = texture
		
		# 根据宝石类型设置颜色
		if item_id in Data.gems:
			var gem_data = Data.gems[item_id]
			if gem_data.has("element"):
				sprite.modulate = ElementSystem.get_element_color(gem_data.element)
			
			# 根据宝石等级调整大小
			if gem_data.has("level"):
				var level = gem_data.level
				match level:
					1:
						sprite.scale = Vector2(0.8, 0.8)
					2:
						sprite.scale = Vector2(1.0, 1.0)
					3:
						sprite.scale = Vector2(1.2, 1.2)
		else:
			sprite.modulate = Color.WHITE
	
	# 设置碰撞形状
	if collision:
		var shape = CircleShape2D.new()
		shape.radius = pickup_range
		collision.shape = shape

func add_floating_animation():
	if not sprite:
		return
		
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", -8, 1.0)
	tween.tween_property(sprite, "position:y", 8, 1.0)
	
	# 添加旋转动画
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(sprite, "rotation_degrees", 360, 3.0)

func _on_pickup_area_entered(body: Node2D):
	# 目前暂时自动拾取所有物品
	if pickup_ready:
		pickup_item()

func _on_pickup_area_entered_area(area: Area2D):
	# 可以用于特定的拾取逻辑
	pass

func pickup_item():
	if not pickup_ready or item_id == "":
		return
	
	var inventory_manager = get_inventory_manager()
	if inventory_manager and inventory_manager.add_item(item_id, 1):
		# 播放拾取效果
		play_pickup_effect()
		
		# 发出信号
		item_picked_up.emit(item_id)
		
		# 移除物品
		pickup_ready = false
		var tween = create_tween()
		tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)

func play_pickup_effect():
	# 创建拾取特效
	var effect_color = Color.WHITE
	if item_id in Data.gems and Data.gems[item_id].has("element"):
		effect_color = ElementSystem.get_element_color(Data.gems[item_id].element)
	
	LootSystem.create_pickup_effect(global_position, effect_color)

func get_inventory_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("InventoryManager")
	return null

func get_item_info() -> Dictionary:
	if item_id in Data.gems:
		return Data.gems[item_id]
	return {}

func set_item_data(new_item_id: String):
	item_id = new_item_id
	setup_visual()

# 可以通过代码创建ItemDrop实例
static func create_item_drop(item_id: String, position: Vector2) -> Node2D:
	var item_drop_script = preload("res://Scenes/items/ItemDrop.gd")
	var item_drop = item_drop_script.new()
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
	
	# 等待节点准备完成后设置
	item_drop.call_deferred("setup_visual")
	
	return item_drop