"""PARCIALMENTE FUNCIONAL, NÃO IMPLEMENTADO"""
extends BaseSystem

class_name EffectSystem


## The effects already applied, if the duraction are higher than 0 a cooldown are created, in the end, the effect are removed
## if the duraction are less than 0, the system will take this like a permanent effect
var _aplied_effects: Dictionary = {}

## An array who store the effects who must be applied, the structure is simple:
## [[effect: EffectData, specific_target_component: BaseComponent]]
var _effects_to_apply: Array[Array] = []

func get_class_name():
	return "EffectSystem"

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	_components_requireds = ["EffectComponentGroup", "HealthComponentGroup", "DamageComponentGroup"]

func _process(delta: float) -> void:
	if _effects_to_apply.is_empty() == false:
		pass

func _apply_effect(target_entity_to_aply_effect: Node):
	pass

## Usually to apply an effect, the event must be trigged from this function. This function put the effect in a queue list to be aplied in the next call of _process().
## source_entity must have an EffectComponent and target_entity must have at least one component required by the system.
## effect_name is the actual name of the effect, the value of EffectData.effect_name. effect_name can be "all", "" or the specific effect name.
## If its "all", means all effects from the EffectComponent will be applied.
## If its "" and the EffectComponent have only one EffectData, it will take these EffectData, if it have more than one EffectData, thena  random effect are take.
## source_component_name and target_component_name are used if the source_entity or target_entity have more than one EffectComponent.
func queue_effect(source_entity: Node, target_entity: Node, effect_name: String = "", source_component_name: String = "", target_component_name: String = "") -> void:
	"""# The target component must have at least one component required by the system, does not check yet if the target entity have the component affected by the effect
	var target_component_id: int = target_entity.get_instance_id()
	if target_component_id not in entities:
		return"""
	# The target component must have at least one component required by the system, does not check yet if the target entity have the component affected by the effect
	
	# The source_entity must have at least one EffectComponent
	var source_effect_component = get_component_from_entity(source_entity, "EffectComponentGroup",source_component_name)
	if source_effect_component == null:
		return
	
	# Check if the EffectComponent does not have at least one EffectData, an empty EffectComponent cant apply any effect
	if source_effect_component.get_availibe_effects().is_empty() == true:
		push_warning("The EffectComponent {0} from entity {1} are empty, its impossible to apply any effect".format([]))
		return
	
	match effect_name:
		"all":
			for effect in source_effect_component.get_availibe_effects():
				_load_effects_to_apply(effect, target_entity, target_component_name)
		"":
			var random_effect = source_effect_component.get_availibe_effects().pick_random()
			_load_effects_to_apply(random_effect, target_entity, target_component_name)
		_:
			# Check if the effect really exists
			if effect_name not in source_effect_component.get_availibe_effects_names():
				push_error("The effect with effect_name {0} does not exist on the component {1} from entity {2}, chose a different effect_name".format([effect_name, source_effect_component.get_name(), source_entity.get_name()]))
				return
				
			var specific_effect = source_effect_component.get_effect_by_name(effect_name)
			_load_effects_to_apply(specific_effect, target_entity, target_component_name)
	

func _load_effects_to_apply(effect: EffectData, target_entity: Node, target_component_name: String = ""):
	# Just take some properties from the effect
	var effect_type: EffectData.EFFECT_TYPES = effect.effect_type
	var effect_name: String = effect.effect_name
	
	# Check if the effect type is NOTHING
	if effect_type == EffectData.EFFECT_TYPES.NOTHING:
		push_warning("Trying to utilize the effect {0}, but it have effect_type equal to NOTHING, well nothing will happen".format(effect_name))
	
	# Take the respective dictionary from the EFFECT_TARGETS dictionary
	var effect_target: Dictionary = effect.get_effect_target()
	
	# Verify if the keys have any null value, this means the effect is not implemented yet, so will be ignored and a warning raised
	if null in effect_target.values():
		push_warning("The effect {0} was not implemented yet, since there is at least one null value on the respective EFFECT_TARGETS. Aplication ignored".format([effect_name]))
	
	# Take the component who will be affected, based on the effect who will be aplied
	var target_component = get_component_from_entity(target_entity, effect_target["component_target_group"], target_component_name)
	if target_component == null:
		return
		
	_effects_to_apply.append([effect, target_component])
