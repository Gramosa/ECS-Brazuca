"""NÃO IMPLEMENTADO AINDA"""
@tool
extends Resource

class_name EffectData

## You can create others behavious changing the values, for example:
## pseudo CONTINUOUS_HEALING would be damage < 0
## pseudo VELOCITY_BUFF would be velocity_ratio > 1
## pseudo DAMAGE_BUFF would be damage_change_ratio > 1
enum EFFECT_TYPES {NOTHING=0, CONTINUOUS_DAMAGE=1, VELOCITY_DEBUFF=2, DAMAGE_DEBUFF=3, RESISTENCE_DEBUFF=4}

## Fixed structures to each effect type, "any" are keys common to every effect
## MUST add a new structure to each EffectType
const EFFECTS_STRUCTURES: Dictionary = {
	EFFECT_TYPES.NOTHING: {
		# Well its really nothing
	},
	EFFECT_TYPES.CONTINUOUS_DAMAGE: {
		"damage_per_second": 1,
	},
	EFFECT_TYPES.VELOCITY_DEBUFF: {
		"valocity_ratio": 0.0
	},
	EFFECT_TYPES.DAMAGE_DEBUFF: {
		"damage_ratio": 0.0
	},
	EFFECT_TYPES.RESISTENCE_DEBUFF: {
		"resistence_ratio": 0.0
	}
}

const EFFECTS_TARGETS: Dictionary = {
	EFFECT_TYPES.CONTINUOUS_DAMAGE: {
		"component_target_group": "HealthComponentGroup",
		"properties": null
	}
}

## The specific name of the effect, just for visual behaviour and/or organization, like Burn, Freeze and etc... 
@export_placeholder("Effect Name") var effect_name: String

# Mental note: EFFECT_TYPES and effect_type are different, effect_type are just one of the possibles EFFECT_TYPES (Isso é obvio mas continuo me confundindo)
## Chose one of the existents effects, except for NOTHING, because well... its does nothing
@export var effect_type: EFFECT_TYPES = EFFECT_TYPES.NOTHING:
	set(new_effect_type):
		# Does not change nothing if the values are the same
		if effect_type == new_effect_type:
			return
		
		effect_type = new_effect_type
		
		## Modify effects_data
		# Give the specific dictionary structure to effects_data
		effects_data = EFFECTS_STRUCTURES[effect_type].duplicate()

## The duration of the effect, if 0 the effect will not be applied, if less than 0 the effect will be considered permanent.
## A permanent effect are NOT removed automatically by the system with a cooldown
@export var effect_duraction: float = 0.0

## Change the values according, does NOT change values types. You can not add new keys, even if you try
## Beware with ratio properties, because it can become a very low or high values.
## For example a damage of 1000 with damage_ratio of 1000 become 1,000,000
@export var effects_data: Dictionary:
	set(new_effects_data):
		# Verify if the keys from new_effects_data does not match with the structure described by
		# EFFECTS_STRUCTURES based on the given effect_type
		if new_effects_data.keys() != EFFECTS_STRUCTURES[effect_type].keys():
			push_warning("You cannot change the structure of the dictionary effects_data, each effect have a specific structure, that was not developed to be changed from editor")
			return
		
		effects_data = new_effects_data
