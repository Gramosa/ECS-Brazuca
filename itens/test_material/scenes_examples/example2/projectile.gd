extends Area2D

const VELOCITY: float = 500.0
const MAX_DISTANCE: float = 200.0

@onready var damage_system: DamageSystem = get_tree().get_root().get_node("Example2/DamageSystem")
var _direction: Vector2
var _caster: Node

#Usado para limitar a distancia viajada pelo projetil
var start_position: Vector2
var distance_traveled: float = 0.0

func _ready() -> void:
	start_position = self.global_position

func setup(direction: Vector2, caster: Node) -> void:
	_direction = direction
	_caster = caster

func _process(delta: float) -> void:
	self.position += _direction * VELOCITY * delta
	
	# Verifica se o projetil alcancou a distancia maxima
	distance_traveled = abs(self.global_position - start_position).length()
	if distance_traveled >= MAX_DISTANCE:
		_destroy_spell()

func _destroy_spell():
	self.queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area != _caster:
		damage_system.do_damage(self, area)
	pass
