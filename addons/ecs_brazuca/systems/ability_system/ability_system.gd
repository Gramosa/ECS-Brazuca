"""NÃO FUNCIONAL, NÃO IMPLEMENTADO"""
"""Falta possibilitar a remoção do efeito aplicado"""
"""Para fazer isso funcionar o registro do CalcChain atrelado a uma propriedade especifica deveria ser registrado antes da aplicação do efeito."""
"""O rastreio do tempo deve ser feito cabrini quantas para cada efeito, para cada propriedade de cada componente. Ideia: Rergistrar o Timer diretamentev em CalcLink e ele mesmo se remover de seus pais quando o tempo acabar"""
extends BaseSystem

class_name AbilitySystem

## A dictionary designed to map and track components and they properties, its may works together with _entities variable, but its not harded dependend, since its does not register the entity
## When a component are affected by an effect for the first time, its registered here, and the property in question have an CalcChain assigned to it.
## If the duraction are higher than 0 a cooldown are created, in the end, the effect are removed
## If the duraction are equal to -1, the system will take this like a permanent effect, its the structure of _map_effects
## 
## Lets consider an entity who have two components, a HealthComponent and a DamageComponent. And an effect was registered to affect the resistance_ratio and damage_ratio of them
## Here's the resulting `_map_effects` variable:
## {
##     HealthComponent(id) {
##         "resistance_ratio": [CalcChainA (instance)]
##     },
##     DamageComponent(id) {
##         "damage_ratio": [CalcChainB (instance)]
## }
##
var _map_effects: Dictionary = {}

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	_components_requireds = ["AbilityComponentGroup", "HealthComponentGroup", "DamageComponentGroup"]

func is_property_registered(component_id: int, property: String) -> bool:
	if component_id not in _map_effects:
		return false
	
	if typeof(_map_effects[component_id]) != TYPE_DICTIONARY:
		push_error("Behaviour not expected: the component id {0} does not have a dictionary as value in _map_effects".format([component_id]))
		return false
	
	if property not in _map_effects[component_id]:
		return false
	
	return true

func _validate_effect_aplication():
	pass

# This function is responsible for registering the properties and components on _map_effects.
func register_property(component: BaseComponent, property: String, calc_chain: CalculationManager.CalcChain) -> void:
	if property not in component:
		push_error("The property '{0}' does not exist on component '{1}', so this property cannot be registered".format([property, component.get_name()]))
		return
	
	var component_id: int = component.get_instance_id()
	if component_id not in _map_effects:
		_map_effects[component_id] = {}
	
	if property not in _map_effects[component_id]:
		"""Por enquanto o valor base da propriedade é adicionado como primeiro elemento da corrente"""
		var property_value: float = component.get(property)
		## Add the base value taken from the component to the respective chain
		var base_value: CalculationManager.CalcLink = CM.CalcLinkFactory.numeric_link(property_value, "base_value")
		calc_chain.add_link(base_value, 0)
		_map_effects[component_id][property] = calc_chain

# This function is responsible for registering the properties and components on _map_effects.
func _register_property_on_map_effect(component: BaseComponent, property: String, calc_chain: CalculationManager.CalcChain) -> void:
	if property not in component:
		push_error("The property '{0}' does not exist on component '{1}', so this property cannot be registered".format([property, component.get_name()]))
		return
	
	var component_id: int = component.get_instance_id()
	if component_id not in _map_effects:
		_map_effects[component_id] = {}
	
	if property not in _map_effects[component_id]:
		"""Por enquanto o valor base da propriedade é adicionado como primeiro elemento da corrente"""
		var property_value: float = component.get(property)
		## Add the base value taken from the component to the respective chain
		calc_chain.add_numeric_link(property_value, "base_value", 0)
		_map_effects[component_id][property] = calc_chain

func _unregister_property_on_map_effect(component: BaseComponent, property: String) -> void:
	if property not in component:
		push_error("The property '{0}' does not exist on component '{1}', so this property cannot be registered".format([property, component.get_name()]))
		return
	
	var component_id: int = component.get_instance_id()
	if component_id not in _map_effects:
		push_error("The component '{0}', are not registered on _map_effects. So you cannot unregister it".format([component.get_name()]))
		return
	
	if property not in _map_effects[component_id]:
		push_error("The component {0} are registered but the property {1} are not. So you cannot unregister it".format([property]))
		return
	
	_map_effects[component_id].erase(property)
	if _map_effects[component_id].is_empty():
		_map_effects.erase(component_id)
	
func _modify_property(component: BaseComponent, property: String, effect: EffectData):
	var component_id: int = component.get_instance_id()
	var respective_chain: CalculationManager.CalcChain = _map_effects[component_id][property]
	var effect_link: CalculationManager.CalcLink = respective_chain.get_link_by_tag_bfs(effect.effect_name)
	## Check if the effect was not applied yet
	if effect_link == null:
		effect_link = CM.CalcLink.new(effect.effect_value, effect.effect_name)
	else:
		var old_value: float = effect_link._value
		
	if effect_link == null:
		effect_link = CM.CalcLink.new(effect.effect_value, effect.effect_name)
		respective_chain.get_link_by_tag_bfs(effect.chain_tag)\
			.add_link(effect_link)
		
		#Create the timer and add in scene
		var effect_timer: Timer = Timer.new()
		effect_timer.set_wait_time(effect.effect_duraction)
		add_child(effect_timer)
		
		#Connect the signal and start the timer
		effect_timer.timeout.connect(_on_effect_time_timeout.bind(effect_timer), CONNECT_ONE_SHOT)
		effect_timer.start()
		
	else:
		match effect.duplicated_behaviour:
			EffectData.DUPLICATED_BEHAVIOURS.IGNORE:
				return
			EffectData.DUPLICATED_BEHAVIOURS.REPLACE:
				"""É preciso mudar o estado das correntes que tem esse link para 'não atualizado'"""
				effect_link._value = effect.effect_value
			_:
				push_error("Behaviour not implemented yet")
				return
		
		component.update_property(property, respective_chain.get_calculated_chain())
	

## Usually to apply an effect, the event must be trigged from this function.
## source_entity must have an AbilityComponent and target_entity must have at least one component required by the system.
## effect_name is the actual name of the effect, the value of EffectData.effect_name.
## source_component_name and target_component_name are used if the source_entity or target_entity have more than one component from the same type.
func apply_effect(source_entity: Node, target_entity: Node, effect_name: String, source_component_name: String = "", target_component_name: String = "") -> void:
	# The source_entity must have at least one AbilityComponent
	var source_ability_component: AbilityComponent = get_component_from_entity(source_entity, "AbilityComponentGroup", source_component_name)
	if source_ability_component == null:
		return
	
	# Check if the AbilityComponent does not have at least one EffectData, an empty AbilityComponent cant apply any effect
	if source_ability_component.get_availibe_effects() == []:
		return
		
	var effect: EffectData = source_ability_component.get_effect_by_name(effect_name)
	if effect == null:
		return
		
	# Take the respective dictionary from the EFFECT_TARGETS dictionary
	var effect_target: Dictionary = effect.get_effect_target()
	if effect_target == {}:
		return
	
	# Take the component who will be affected, based on the effect who will be aplied
	var target_component: BaseComponent = get_component_from_entity(target_entity, effect_target["component_target_group"], target_component_name)
	if target_component == null:
		push_warning("Effect Aplication: The effect ({0}) of type ({1}) could not solve, due not found the target component".format([effect.effect_name, EffectData.EFFECT_TYPES.keys()[effect.effect_type]]))
		return
	
	var target_property: String = effect.get_effect_target()["property"]
	
	"""Talvez no futuro separar o registro da aplicação"""
	_register_property_on_map_effect(target_component, target_property, CM.CalcChainFactory.stat_mod_ratio())
	if is_property_registered(target_component.get_instance_id(), target_property):
		_modify_property(target_component, target_property, effect)
	
"""Implementar efeito aleatorio e/ou aplicar todos os efeitos"""

func _on_effect_time_timeout(timer: Timer) -> void:
	print("effect timeout" + str(timer.get_instance_id()))
	# Remove the timer, since its not needed anymore
	timer.queue_free()

func remove_effect(effect_name: String, target_entity: Node) -> void:
	var entity_id: int = target_entity.get_instance_id()
