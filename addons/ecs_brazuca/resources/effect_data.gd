"""PARCIALMENTE FUNCIONAL, NÃO IMPLEMENTADO"""
@tool
extends Resource

class_name EffectData

## You can create others behavious changing the values, for example:
## pseudo CONTINUOUS_HEALING would be damage < 0
## pseudo VELOCITY_BUFF would be velocity_ratio > 1
## pseudo DAMAGE_BUFF would be damage_change_ratio > 1
enum EFFECT_TYPES {NOTHING=0, CONTINUOUS_DAMAGE=1, RESISTANCE_DEBUFF=2, VELOCITY_DEBUFF=3, DAMAGE_DEBUFF=4}

"""NAO IMPLEMENTADO"""
## The behaviour expected when an effect are applied, how it must modify the target property.
## REPLACE: The base value of the property from the component are replaced, the same as property = new_value.
## MULTIPLY: Multiply the desired property by the value, the same as property *= new_value.
enum EFFECT_BEHAVIOURS {NOT_APPLY=0, REPLACE=1, SUM=2, MULTIPLY=3}

const EFFECT_TARGETS: Dictionary = {
	EFFECT_TYPES.NOTHING: {
		"component_target_group": null,
		"property": null,
		"allowed_behaviours": [EFFECT_BEHAVIOURS.NOT_APPLY]
	},
	EFFECT_TYPES.CONTINUOUS_DAMAGE: {
		"component_target_group": "HealthComponentGroup",
		"property": "health",
		"allowed_behaviours": [EFFECT_BEHAVIOURS.NOT_APPLY]
	},
	EFFECT_TYPES.RESISTANCE_DEBUFF: {
		"component_target_group": "HealthComponentGroup",
		"property": "resistance_ratio",
		"allowed_behaviours": [EFFECT_BEHAVIOURS.REPLACE, EFFECT_BEHAVIOURS.MULTIPLY]
	},
	EFFECT_TYPES.VELOCITY_DEBUFF: {
		"component_target_group": null,
		"property": null,
		"allowed_behaviours": [EFFECT_BEHAVIOURS.REPLACE, EFFECT_BEHAVIOURS.MULTIPLY]
	},
	EFFECT_TYPES.DAMAGE_DEBUFF: {
		"component_target_group": "DamageComponentGroup",
		"property": "damage_ratio",
		"allowed_behaviours": [EFFECT_BEHAVIOURS.REPLACE, EFFECT_BEHAVIOURS.MULTIPLY]
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
		
		## Modify effect_behaviour
		# Take first allowed behaviour and give to effect_behaviour
		effect_behaviour = get_effect_target()["allowed_behaviours"][0]
	
## Chose one of the behaviours for the effects, this means, how the system must modify the property
@export var effect_behaviour: EFFECT_BEHAVIOURS = EFFECT_BEHAVIOURS.REPLACE:
	set(new_effect_behaviour):
		# Does not change nothing if the values are the same
		if effect_behaviour == new_effect_behaviour:
			return
		
		# Verify if the behaviour are allowed by the effect_type
		if new_effect_behaviour not in get_effect_target()["allowed_behaviours"]:
			push_warning("Trying to give a not allowed behaviour ({0}) to an effect from type ({1}), check 'allowed_behaviours' list in EFFECT_TARGETS'".format([EFFECT_BEHAVIOURS.keys()[new_effect_behaviour], EFFECT_TYPES.keys()[effect_type]]))
			return
		
		effect_behaviour = new_effect_behaviour
	
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
