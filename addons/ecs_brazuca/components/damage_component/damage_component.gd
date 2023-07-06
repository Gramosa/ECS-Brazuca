@icon("damage_component_icon.svg")
extends BaseComponent

class_name DamageComponent

@export_group("Damage")
## The value of the Damage, negative values maeans healing
@export var damage: int

## The rate applied of the damage based on the damage, high ratio means more damage
@export_range(0.01, 100) var damage_ratio: float = 1

@export_group("Effect")
## If true effects can be applied according a EffectComponent
@export var apply_effect: bool = false

## The effects applied, only works if apply_effect is true
@export var effect_component: EffectComponent

func _init() -> void:
	super()
	
	add_to_group("DamageComponentGroup", true)

func get_damage():
	return damage

func get_damage_ratio() -> float:
	return damage_ratio

func verify_connections() -> void:
	pass
