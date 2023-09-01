"""NÃO FUNCIONAL, NÃO IMPLEMENTADO"""
"""Falta possibilitar a remoção do efeito aplicado"""
extends BaseSystem

class_name EffectSystem

## The effects already applied, if the duraction are higher than 0 a cooldown are created, in the end, the effect are removed
## If the duraction are less than 0, the system will take this like a permanent effect, its the structure
var map_effects: Dictionary = {}

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	_components_requireds = ["EffectComponentGroup", "HealthComponentGroup", "DamageComponentGroup"]

## The effect chain makes possible calculate the effects in any order (for now using sum and multiplication)
## Each chain have an operation, and this operation tell how the links must be merged. You can thin chains as () in a mathemmatic expression
## For example, if there is the effects A, B, C and D. And the calculation expected are result = (A + B) * (C + D)
## It could be:
## sub_chain1 = EffectChain.new("sum")
## sub_chain1.add_link(A)
## sub_chain1.add_link(B)
##
## sub_chain2 = EffectChain.new("sum")
## sub_chain2.add_multiple_links([C, D])
##
## main_chain = EffectChain.new("multiplication")
## main_chain.add_multiple_links([sub_chain1, sub_chain2])
## result = main_chain.get_calculated_chain()
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
	func add_link(link: Variant) -> EffectChain:
		assert(link is EffectData or link is EffectChain or typeof(link) in [TYPE_INT, TYPE_FLOAT], \
		"The link {0} must be a numeric value, EffectData or another chain".format([link]))
		
		_chain.append(link)
		is_chain_updated = false
		return self
	
	## add multiple links. Check add_link()
	func add_multiple_links(links: Array) -> EffectChain:
		if links.is_empty():
			push_error("'links' argument must have at least one link, but it's empty")
			
		for link in links:
			add_link(link)
			
		return self
	
	# An shorthand to add a chain
	func add_chain(operation: String, links: Array) -> EffectChain:
		add_link(EffectChain.new(operation).add_multiple_links(links))
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

	# Create sub-chain 1: (a + b) * c
	var sub_chain_1: EffectChain = EffectChain.new("multiplication")
	sub_chain_1.add_chain("sum", [a, b])
	sub_chain_1.add_link(c)

	# Create main chain: ((a + b) * c) / (d - e)
	var main_chain: EffectChain = EffectChain.new("division")
	main_chain.add_link(sub_chain_1)
	main_chain.add_chain("sum", [d, -e])

	# Print results
	print("Calculated Chain Value:", main_chain.get_calculated_chain())
	print("Effects Names:", main_chain.get_effects_names())

func test2() -> void:
	var data: EffectData = EffectData.new()
	data.effect_name = "FOGO"
	var chain = EffectChain.new("sum")
	chain.add_link(data)
	chain.get_calculated_chain()

## Usually to apply an effect, the event must be trigged from this function. This function put the effect in a queue list to be aplied in the next call of _process().
## source_entity must have an EffectComponent and target_entity must have at least one component required by the system.
## effect_name is the actual name of the effect, the value of EffectData.effect_name.
## source_component_name and target_component_name are used if the source_entity or target_entity have more than one component from the same type.
func apply_effect(source_entity: Node, target_entity: Node, effect_name: String, source_component_name: String = "", target_component_name: String = "") -> void:
	# The source_entity must have at least one EffectComponent
	var source_effect_component = get_component_from_entity(source_entity, "EffectComponentGroup",source_component_name)
	if source_effect_component == null:
		return
	
	# Check if the EffectComponent does not have at least one EffectData, an empty EffectComponent cant apply any effect
	if source_effect_component.get_availibe_effects().is_empty() == true:
		push_warning("The EffectComponent {0} from entity {1} are empty, its impossible to apply any effect".format([source_effect_component.get_name(), source_entity.get_name()]))
		return
	
	# Check if the effect really exists
	if effect_name not in source_effect_component.get_availibe_effects_names():
		push_error("The effect with effect_name {0} does not exist on the component {1} from entity {2}, chose a different effect_name".format([effect_name, source_effect_component.get_name(), source_entity.get_name()]))
		return
		
	var specific_effect: EffectData = source_effect_component.get_effect_by_name(effect_name)
	# Take the properties from the EffectData
	var effect_type: EffectData.EFFECT_TYPES = specific_effect.effect_type
	
	# Check if the effect type is NOTHING
	if effect_type == EffectData.EFFECT_TYPES.NOTHING:
		push_warning("Trying to utilize the effect {0}, but it have effect_type equal to NOTHING, well nothing will happen".format(effect_name))
		return
		
	# Take the respective dictionary from the EFFECT_TARGETS dictionary
	var effect_target: Dictionary = specific_effect.get_effect_target()
	
	# Verify if the keys have any null value, this means the effect is not implemented yet, so will be ignored and a warning raised
	if null in effect_target.values():
		push_warning("The effect {0} was not implemented yet, since there is at least one null value on the respective EFFECT_TARGETS. Operation ignored".format([effect_name]))
		return
	
	# Take the component who will be affected, based on the effect who will be aplied
	var target_component: BaseComponent = get_component_from_entity(target_entity, effect_target["component_target_group"], target_component_name)
	if target_component == null:
		return
	

func apply_random_effect(source_entity: Node, target_entity: Node, source_component_name: String = "", target_component_name: String = ""):
	# The source_entity must have at least one EffectComponent
	var source_effect_component = get_component_from_entity(source_entity, "EffectComponentGroup",source_component_name)
	if source_effect_component == null:
		return
	
	# Check if the EffectComponent does not have at least one EffectData, an empty EffectComponent cant apply any effect
	if source_effect_component.get_availibe_effects().is_empty() == true:
		push_warning("The EffectComponent {0} from entity {1} are empty, its impossible to apply any effect".format([source_effect_component.get_name(), source_entity.get_name()]))
		return

	var random_effect: EffectData = source_effect_component.get_availibe_effects().pick_random()
	#_load_effects_to_apply(random_effect, target_entity, target_component_name)
	pass

func apply_all_effects(source_entity: Node, target_entity: Node, source_component_name: String = "", target_component_name: String = ""):
	# The source_entity must have at least one EffectComponent
	var source_effect_component = get_component_from_entity(source_entity, "EffectComponentGroup",source_component_name)
	if source_effect_component == null:
		return
	
	# Check if the EffectComponent does not have at least one EffectData, an empty EffectComponent cant apply any effect
	if source_effect_component.get_availibe_effects().is_empty() == true:
		push_warning("The EffectComponent {0} from entity {1} are empty, its impossible to apply any effect".format([source_effect_component.get_name(), source_entity.get_name()]))
		return

	for effect in source_effect_component.get_availibe_effects():
		#_load_effects_to_apply(effect, target_entity, target_component_name)
		pass

## This function actually is responsible to apply the effect, its means change directly the affected component.
## For internal purposes only, externally the effects is better applied with queue_effect()
## queued_effect are a Array with first item being the EffectData and the second the target component
func _apply_effect(queued_effect: Array) -> void:
	var effect: EffectData = queued_effect[0]
	var target_component: BaseComponent = queued_effect[1]
	
	"""Talvez mudar no futo para um array, e permitir mais de uma modificação por efeito, desde que o alvo seja o mesmo componente"""
	# Take the name of the propertie to be modified, and the value it must have
	var target_propertie: String = effect.get_effect_target()["propertie"]
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
