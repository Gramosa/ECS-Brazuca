"""PARCIALMENTE FUNCIONAL, NÃO IMPLEMENTADO"""
@tool
extends Resource

class_name AbilityData

"""NAO IMPLEMENTADO"""

## Its tell how the system must deal when a duplicated effect are applied. 
enum DUPLICATED_BEHAVIOURS {IGNORE=0, REPLACE=1, SUM=2, MULTIPLICATION=3}

## The specific name of the effect, for tracking and organization, like Burn, Freeze and etc...
@export_placeholder("Effect Name") var effect_name: String

## Chose one of the existents effects, except for NOTHING, because well... its does nothing
var effect_target: String

## Its tell the system what position in the CalcFormula the effect will be added
@export var chain_tag: String = "BUFF"

## Chose one of the behaviours for the effects, this means, how the system must modify the property
@export var duplicated_behaviour: DUPLICATED_BEHAVIOURS = DUPLICATED_BEHAVIOURS.IGNORE
	
## The duration of the effect, if 0 the effect will not be applied, if less than 0 the effect will be considered permanent.
## A permanent effect are NOT removed automatically by the system with a cooldown
@export var effect_duraction: float = 0.0

## The actual numeric value used to modify the target property
@export_range(0.000001, 9999999) var effect_value: float:
	set(new_effect_value):
		
		effect_value = new_effect_value

"""
## Take the respective dictionary target, based on the effect_type
func get_effect_target() -> Dictionary:
	var effect_target: Dictionary = EFFECT_TARGETS[effect_type]
	# Verify if the keys have any null value, this means the effect is not implemented yet, so will be ignored and a warning raised
	if null not in effect_target.values():
		return effect_target
	else:
		push_warning("The effect {0} was not implemented yet, since there is at least one null value on the respective EFFECT_TARGETS. Operation ignored".format([effect_name]))
		return {}
"""
