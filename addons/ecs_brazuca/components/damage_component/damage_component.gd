@icon("damage_component_icon.svg")
extends BaseComponent

class_name DamageComponent

@export_group("Damage")
## The value of the Damage, negative values maeans healing
@export var damage: int

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

func verify_connections() -> void:
	pass
