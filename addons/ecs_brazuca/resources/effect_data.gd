"""NÃO IMPLEMENTADO AINDA"""
@tool
extends Resource

class_name EffectData

## You can create others behavious changing the values, for example:
## pseudo CONTINUOUS_HEALING would be damage < 0
## pseudo VELOCITY_BUFF would be velocity_ratio > 1
## pseudo DAMAGE_BUFF would be damage_change_ratio > 1
enum EffectTypes {NOTHING=0, CONTINUOUS_DAMAGE=1, STUN=2, DAMAGE_DEBUFF=3, RESISTENCE_DEBUFF=4}

## Fixed structures to each effect type, "any" are keys common to every effect
## MUST add a new structure to each EffectType
const effects_structures: Dictionary = {
	"any": {
		"duraction": 0.0
	},
	EffectTypes.CONTINUOUS_DAMAGE: {
		"damage_per_second": 1
	},
	EffectTypes.STUN: {
		"valocity_ratio": 0.0
	},
	EffectTypes.DAMAGE_DEBUFF: {
		"damage_change_ratio": 0.0
	},
	EffectTypes.RESISTENCE_DEBUFF: {
		"resistence_change_ratio": 0.0
	}
}

## The specific name of the effect, just for visual behaviour and/or organization, like Burn, Freeze and etc... 
@export_placeholder("The name of the effect") var effect_name: String

## Chose one of the existents effects, expect for NOTHING, because well... its does nothing
@export var effect_type: EffectTypes = EffectTypes.NOTHING:
	set(new_effect_type):
		#Does not change nothing if the values are the same
		if effect_type == new_effect_type:
			return
			
		# Add the base data, to every effect type, no matter what
		effects_data = effects_structures["any"].duplicate()
		# Merge the base dictionary with the correct structure
		effects_data.merge(effects_structures[new_effect_type].duplicate())
		
		effect_type = new_effect_type

"""Mudar no futuro para tornar impossível mudar a estrutura esperada do dicionário"""
## Change the values according, does NOT add new keys or change values types
@export var effects_data: Dictionary
