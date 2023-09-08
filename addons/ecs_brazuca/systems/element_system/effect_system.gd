"""NÃO FUNCIONAL, NÃO IMPLEMENTADO"""
"""Falta possibilitar a remoção do efeito aplicado"""
extends BaseSystem

class_name EffectSystem

## A dictionary designed to map and track components and they properties, its may works together with _entities variable, but its not harded dependend, since its does not register the entity
## When a component are affected by an effect for the first time, its registered here, and the property in question have an EffectChain assigned to it.
## If the duraction are higher than 0 a cooldown are created, in the end, the effect are removed
## If the duraction are equal to -1, the system will take this like a permanent effect, its the structure of _map_effects
## 
## Lets consider an entity who have two components, a HealthComponent and a DamageComponent. And an effect was registered to affect the resistance_ratio and damage_ratio of them
## Here's the resulting `_map_effects` variable:
## {
##     HealthComponent(id) {
##         "resistance_ratio": EffectChainA (instance)
##     },
##     DamageComponent(id) {
##         "damage_ratio": EffectChainB (instance)
## }
##
var _map_effects: Dictionary = {}

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	_components_requireds = ["EffectComponentGroup", "HealthComponentGroup", "DamageComponentGroup"]

## The effect chain makes possible calculate the effects in any order (for now using sum, multiplication and division)
## Each chain have an operation, and this operation tell how the links must be merged. You can think chains as () in a mathemmatic expression
## The links in the chain can be: int, float, EffectData or another EffectChain
## For example, if there is the effects A, B, C and D. And the calculation expected are: result = (A + B) * (C + D)
## It could be, Ex1:
## sub_chain1 = EffectChain.new("sum").add_multiple_links([A, B])
## sub_chain2 = EffectChain.new("sum").add_multiple_links([C, D])
##
## main_chain = EffectChain.new("multiplication").add_multiple_links([sub_chain1, sub_chain2])
## result = main_chain.get_calculated_chain()
## 
## Ex2:
## main_chain = EffectChain.new("multiplication").add_chain("sum", [A, B]).add_chain("sum", [C, D])
## And many others ways...
class EffectChain:
	const POSSIBLE_OPERATIONS: Array[String] = ["sum", "multiplication", "division"]
	
	func sum(value: float) -> float: return _chain_value + value
	func multiplication(value: float) -> float: return _chain_value * value
	func division(value: float) -> float: return _chain_value / value if value != 0 else _chain_value #Ignore if the link in divisior is 0
	
	## Actualy the function used to perform the operation
	var _operator: Callable
	
	## An array who contains links, so links together makes a chain
	var _chain: Array
	var _effects_names: Array
	
	# The value calculated of the chain and subchains
	var _chain_value: float
	## Will be true if the chain was calculated, and the chain was not changed.
	## Used to avoid performing the same operation again, if it was already made
	var is_chain_updated: bool
	## Every link in the chain are united by the specified operation, this operation define what function are used for operation
	var _operation: String:
		set(new_operation):
			assert(new_operation in POSSIBLE_OPERATIONS, "The operation {0} must be inside POSSIBLE_OPERATIONS".format([new_operation]))
			is_chain_updated = false
			match new_operation:
				"sum":
					_operator = sum
				"multiplication":
					_operator = multiplication
				"division":
					_operator = division
				_:
					push_error("Behaviour not expected, the operation must be sum, multiplication or division, not {0}".format(_operation))
			
			_operation = new_operation
			
	func _init(operation: String) -> void:
		_operation = operation
	
	# Add a link in the _chain, it MUST be an int, float, EffectData or another EffectChain
	# If the index be -1 its means the last position in the chain
	func add_link(link: Variant, index: int = -1) -> EffectChain:
		assert(link is EffectData or link is EffectChain or typeof(link) in [TYPE_INT, TYPE_FLOAT], \
		"The link {0} must be a numeric value, EffectData or another chain".format([link]))
		if index < -1:
			push_error("The index MUST be higher or equal to -1, given {0} instead".format([index]))
		
		if index == -1:
			_chain.append(link)
		elif len(_chain) >= index:
			_chain.insert(index, link)
		else:
			push_error("Invalid Index: The index value perpass the lenghth of the chain")
		is_chain_updated = false
		return self
	
	## add multiple links. Check add_link()
	func add_multiple_links(links: Array, index: int = -1) -> EffectChain:
		if links.is_empty():
			push_error("'links' argument must have at least one link, but it's empty")
			
		for link in links:
			add_link(link)
			
		return self
	
	# An shorthand to add a chain
	func add_chain(operation: String, links: Array, index: int = -1) -> EffectChain:
		add_link(EffectChain.new(operation).add_multiple_links(links), index)
		return self
	
	func _get_link_value(link: Variant): #Return float or null
		if typeof(link) in [TYPE_INT, TYPE_FLOAT]:
			_effects_names.append(null)
			return link
		elif link is EffectData:
			_effects_names.append(link.effect_name)
			return link.effect_value
		elif link is EffectChain:
			_effects_names.append(link.get_effects_names())
			return link.get_calculated_chain()
		else:
			push_error("Behaviour not expected, for some reason _chain have a non numeric value, EffectData or EffectChain, found {0}".format([link]))
			return null
	
	func update_chain() -> void:
		"""Adicionar uma maneira de lidar com efeitos iguais"""
		
		if _chain.is_empty():
			push_warning("The chain are empty, it must have at least one item")
			return
		
		_chain_value = _get_link_value(_chain[0])
		if _chain_value == null:
			return
		var _chain_without_first = _chain.slice(1)
		for link in _chain_without_first:
			var link_value: float = _get_link_value(link)
			if link_value == null:
				continue
			_chain_value = _operator.call(link_value)
		
		is_chain_updated = true
	
	func get_calculated_chain() -> float:
		if is_chain_updated == false:
			update_chain()
			
		return _chain_value
		
	# It will return the effects names from subchains too, the position of the name will match with the effect in _chain
	func get_effects_names() -> Array:
		if is_chain_updated == false:
			update_chain()
		
		return _effects_names
	

func test() -> void:
	var a: int = 2
	var b: int = 3
	var c: int = 4
	var d: int = 5
	var e: int = 6
	
	# (a + b) * c
	var sub_chain_1: EffectChain = EffectChain.new("multiplication")
	sub_chain_1.add_chain("sum", [a, b])
	sub_chain_1.add_link(c)

	# ((a + b) * c) / (d - e)
	var main_chain: EffectChain = EffectChain.new("division")
	main_chain.add_link(sub_chain_1)
	main_chain.add_chain("sum", [d, -e])
	
	# Print results
	#print("Calculated Chain Value:", main_chain.get_calculated_chain())
	#print("Effects Names:", main_chain.get_effects_names())

func test2() -> void:
	"""
	var data: EffectData = EffectData.new()
	data.effect_name = "FOGO"
	data.effect_value = 1"""
	
	var chain = EffectChain.new("multiplication")
	chain.add_link(1)
	for i in range(1, 100):
		chain.add_link(i)
	print(chain.get_calculated_chain())
	

# This function is responsible for populating the _map_effects
func _update_map_effect_with_component(component: BaseComponent, effect: EffectData, effect_chain: EffectChain):
	var property_target: String = effect.get_effect_target()["property"]
	if property_target not in component:
		push_error("The effect '{0}' can't be applied to the property '{1}' of component '{2}', since this compononet does not have the property".format([effect.effect_name, property_target, component.get_name()]))
		return
	
	var component_id: int = component.get_instance_id()
	if component_id not in _map_effects:
		_map_effects[component_id] = {}
	
	if property_target not in _map_effects[component_id]:
		"""Por enquanto o valor base da propriedade é adicionado como primeiro elemento da corrente"""
		var property_value: float = component.get(property_target)
		effect_chain.add_link(property_value, 0)
		_map_effects[component_id][property_target] = effect_chain
	

## Usually to apply an effect, the event must be trigged from this function. This function put the effect in a queue list to be aplied in the next call of _process().
## source_entity must have an EffectComponent and target_entity must have at least one component required by the system.
## effect_name is the actual name of the effect, the value of EffectData.effect_name.
## source_component_name and target_component_name are used if the source_entity or target_entity have more than one component from the same type.
func apply_effect(source_entity: Node, target_entity: Node, effect_name: String, source_component_name: String = "", target_component_name: String = "") -> void:
	# The source_entity must have at least one EffectComponent
	var source_effect_component: EffectComponent = get_component_from_entity(source_entity, "EffectComponentGroup",source_component_name)
	if source_effect_component == null:
		return
	
	# Check if the EffectComponent does not have at least one EffectData, an empty EffectComponent cant apply any effect
	if source_effect_component.get_availibe_effects() == []:
		return
		
	var effect: EffectData = source_effect_component.get_effect_by_name(effect_name)
	if effect == null:
		return
		
	# Take the respective dictionary from the EFFECT_TARGETS dictionary
	var effect_target: Dictionary = effect.get_effect_target()
	if effect_target == {}:
		return
	
	# Take the component who will be affected, based on the effect who will be aplied
	var target_component: BaseComponent = get_component_from_entity(target_entity, effect_target["component_target_group"], target_component_name)
	if target_component == null:
		return
	
	_update_map_effect_with_component(target_component, effect, EffectChain.new("sum"))

"""Implementar efeito aleatorio e/ou aplicar todos os efeitos"""

## This function actually is responsible to apply the effect, its means change directly the affected component.
## For internal purposes only, externally the effects is better applied with queue_effect()
## queued_effect are a Array with first item being the EffectData and the second the target component
func _apply_effect(queued_effect: Array) -> void:
	var effect: EffectData = queued_effect[0]
	var target_component: BaseComponent = queued_effect[1]
	
	"""Talvez mudar no futo para um array, e permitir mais de uma modificação por efeito, desde que o alvo seja o mesmo componente"""
	# Take the name of the property to be modified, and the value it must have
	var target_propertie: String = effect.get_effect_target()["property"]
	# Since for now only one property are modified by the effect, it will take the unique value from effect_value
	var propertie_value = effect.effect_value
	
	# Apply the effect, modifing the respective property
	target_component.set(target_propertie, propertie_value)
	
	# Create the timer for the effect, and add it to scene
	var effect_time: Timer = Timer.new()
	effect_time.set_wait_time(effect.effect_duraction)
	add_child(effect_time)
	
	# Conect the signal, when the effect_time reach to zero and start it
	effect_time.timeout.connect(_on_effect_time_timeout.bind(effect_time))
	effect_time.start()
	
	#_effects_to_apply.erase(queued_effect)

func _on_effect_time_timeout(timer: Timer) -> void:
	print("effect timeout" + str(timer.get_instance_id()))
	# Remove the timer, since its not needed anymore
	timer.queue_free()

func remove_effect(effect_name: String, target_entity: Node) -> void:
	var entity_id: int = target_entity.get_instance_id()
