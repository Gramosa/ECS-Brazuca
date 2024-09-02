@tool
@icon("damage_component_icon.svg")
extends BRZBaseComponent

class_name BRZDamageComponent

@export_group("Damage")
## The value of the Damage, negative values maeans healing
@export var damage: int

## The rate applied of the damage based on the damage, high ratio means more damage
@export_range(0.001, 1000) var damage_ratio: float = 1

#func get_class_name() -> String:
	#return "BRZDamageComponent"

func get_damage():
	return damage

func get_damage_ratio() -> float:
	return damage_ratio

func get_real_damage():
	return damage * damage_ratio

func verify_connections() -> void:
	pass
