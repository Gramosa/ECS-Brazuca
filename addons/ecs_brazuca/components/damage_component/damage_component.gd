@tool
@icon("damage_component_icon.svg")
extends BrazucaBaseComponent

class_name BrazucaDamageComponent

@export_group("Damage")
## The value of the Damage, negative values maeans healing
@export var damage: int

## The rate applied of the damage based on the damage, high ratio means more damage
@export_range(0.001, 1000) var damage_ratio: float = 1

func _init() -> void:
	super()
	
	add_to_group("DamageComponentGroup", true)

func get_damage():
	return damage

func get_damage_ratio() -> float:
	return damage_ratio

func get_real_damage():
	return damage * damage_ratio

func verify_connections() -> void:
	pass
