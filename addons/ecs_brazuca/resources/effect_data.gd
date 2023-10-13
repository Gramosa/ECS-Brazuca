"""PARCIALMENTE FUNCIONAL, NÃO IMPLEMENTADO"""
@tool
extends Resource

class_name EffectData

"""Ideias de effeitos: CONTINOUS_DAMAGE, VELOCITY"""
enum EFFECT_TYPES {NOTHING=0, RESISTANCE=1, VELOCITY=2, STRENGHT=3}

"""NAO IMPLEMENTADO"""
## Its tell how the system must deal when a duplicated effect are applied. 
enum DUPLICATED_BEHAVIOURS {NOTHING=0, IGNORE=1, REPLACE=2, SUM=3, MULTIPLICATION=4}

const EFFECT_TARGETS: Dictionary = {
	EFFECT_TYPES.NOTHING: {
		"component_target_group": null,
		"property": null,
	},
	EFFECT_TYPES.RESISTANCE: {
		"component_target_group": "HealthComponentGroup",
		"property": "resistance_ratio",
	},
	EFFECT_TYPES.VELOCITY: {
		"component_target_group": null,
		"property": null,
	},
	EFFECT_TYPES.STRENGHT: {
		"component_target_group": "DamageComponentGroup",
		"property": "damage_ratio",
	}
}

## The specific name of the effect, for tracking and organization, like Burn, Freeze and etc...
@export_placeholder("Effect Name") var effect_name: String

# Mental note: EFFECT_TYPES and effect_type are different, effect_type are just one of the possibles EFFECT_TYPES (Isso é obvio mas continuo me confundindo)
## Chose one of the existents effects, except for NOTHING, because well... its does nothing
@export var effect_type: EFFECT_TYPES = EFFECT_TYPES.NOTHING

## Its tell the system what position in the CalcChain the effect will be added
@export var chain_tag: String = "buff"

## Chose one of the behaviours for the effects, this means, how the system must modify the property
@export var duplicated_behaviour: DUPLICATED_BEHAVIOURS = DUPLICATED_BEHAVIOURS.NOTHING
	
## The duration of the effect, if 0 the effect will not be applied, if less than 0 the effect will be considered permanent.
## A permanent effect are NOT removed automatically by the system with a cooldown
@export var effect_duraction: float = 0.0

## The actual numeric value used to by the EffectSystem to calculate and modify the target property
## For example a damage of 1000 with damage_ratio of 1000 become 1,000,000
@export_range(0.000001, 9999999) var effect_value: float:
	set(new_effect_value):
		
		effect_value = new_effect_value

## Take the respective dictionary target, based on the effect_type
func get_effect_target() -> Dictionary:
	var effect_target: Dictionary = EFFECT_TARGETS[effect_type]
	# Verify if the keys have any null value, this means the effect is not implemented yet, so will be ignored and a warning raised
	if null not in effect_target.values():
		return effect_target
	else:
		push_warning("The effect {0} was not implemented yet, since there is at least one null value on the respective EFFECT_TARGETS. Operation ignored".format([effect_name]))
		return {}
