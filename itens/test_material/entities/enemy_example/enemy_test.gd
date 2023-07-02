extends Area2D

@onready var damage_system: Node = get_node("%DamageSystem")

# Variables for the movement, not related to the ECS
var velocity: int = randi_range(50, 150)
var direction: Vector2 = Vector2(1, 0)
var start_position: Vector2
var max_distance: float = 400.0

func _on_area_entered(area: Area2D) -> void:
	"""Desenvolver no futuro uma maneira de rastreiar a entidade"""
	var entity = area.get_parent() #PlayerTest>Area2D
	if entity.get_name() == "Enemies":
		entity = area
	
	"""Mudar no futuro a maneira de chamar a função do_damage, provavelmente usando sinais"""
	damage_system.do_damage(self, entity)

func _ready():
	start_position = self.global_position

func _process(delta: float) -> void:
	change_direction()
	self.global_position += direction * velocity * delta

# Change the direction when the player reach the max distance
func change_direction():
	var distance_traveled: float = self.global_position.x - start_position.x
	# Check if the enemy traveled the max and then change direction, when the enemy come back the distance_traveled will be 0 whe he reach the start_position again
	if distance_traveled >= max_distance or distance_traveled < 0:
		direction.x *= -1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("testar"):
		var chance_of_delete = 0.1
		var delete_rate = randf()
		if chance_of_delete > delete_rate:
			self.queue_free()

func _on_health_component_health_depleted() -> void:
	queue_free()
