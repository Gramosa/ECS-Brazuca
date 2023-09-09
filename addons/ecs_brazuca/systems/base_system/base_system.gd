extends Node

## This is a base class that other systems can inherit from in an Entity-Component-System (ECS) architecture.
## It provides functionality for organizing entities and their components based on component groups.
## The derived systems should extend this class and:
## - Define their own required component groups in the `_components_requireds` variable on _init.
## - Do NOT override the _init() function (Utilize super() after define the required components)
class_name BaseSystem

## An array of component groups names that entities must belong to in order to be added to the `entities` dictionary.
## Each component must be in at least one of these groups to be considered by the system.
var _components_requireds: Array[String] = []

## Important to know: an entity can not have two components with same name AND type, but it can have the same type with different names, or same name with different types.
## An entity can have any number of components, even components with same name and same group.
##
## The `entities` variable is a dictionary of lists with a specific nested structure:
##   - The first level is a dictionary where each key represents the entity id, by the built-in function get_instance_id().
##   - The second level is a list with a fixed length of 2: [entity_node, {}].
##   - The third level is a dictionary where each key represents a component group name.
##   - The fourth level is a list of component nodes belonging to the corresponding group.
##
## In other words, the structure can be represented as:
##   { entity_id1: [ entity_node, { component_group1: [ component1, component2, ... ], component_group2: [...], ... } ],
##     entity_id2: [ entity_node, { component_group1: [ component1, component2, ... ], component_group2: [...], ... } ],
##     ... }
##
## Let's consider an example node tree with entities and their components organized into component groups specified in `_components_requireds`:
##
## Example:
## Game
##   Player: CharacterBody2D
##     Health: HealthComponent
##     Damage: DamageComponent
##     ElementalDamage: DamageComponent
##   Enemy: Area2D
##     EnemyHealth: HealthComponent
##     EnemyMovement: MovementComponent
##
## Here's the resulting `entities` variable:
## {
##   Player(id): [
##     CharacterBody2D(node),
##     {
##       "HealthComponentGroup": [
##         Health(node)
##       ],
##       "DamageComponentGroup": [
##         Damage(node),
##         ElementalDamage(node)
##       ]
##     }
##   ],
##   Enemy(id): [
##     Area2D(node),
##     {
##       "HealthComponentGroup": [
##         EnemyHealth(node)
##       ],
##       "MovementComponentGroup": [
##         EnemyMovement(node)
##       ]
##     }
##   ]
## }
var entities: Dictionary = {}

func _init() -> void:
	add_to_group("Systems", true)

## Load the variable entities with the structure described up to entities variable
## Its recomended to add new entities to "entities" variable using this function, to maintain the dictionary structure
## Usually for internal use only, since each component will trigger the systems automatically when enter the tree.
func _update_entities_with_entity(entity: Node, component: Node, component_group: String) -> void:
	
	var entity_id: int = entity.get_instance_id()
	
	# Verify if the entity already exist, the system will not load the same entity twice
	if entity_id in entities and component_group in entities[entity_id][1]:
		if entities[entity_id][1][component_group].has(component):
			# Component already exists, skip adding it again
			return
	
	# Check if the entity is already present in the entities dictionary
	# If the entity is not present, create a new entry with an empty component dictionary
	# In other words, create the 1° and 2° level, and the 3° empty one
	if entity_id not in entities:
		entities[entity_id] = [entity, {}]
		
	# Check if the component group is already present in the entity's component dictionary
	# In other words, add the component_group to fill the third level if the component_group is not there
	if component_group not in entities[entity_id][1]:
		entities[entity_id][1][component_group] = []
		
	# Add the component to the component list of the corresponding component group (4th level)
	entities[entity_id][1][component_group].append(component)
	
## Utilize if a system be added at runtime, to populate the entities variable
func load_entities_from_group(component_group: String):
	# Get all the nodes belonging to the specified component group
	var members_from_group: Array = get_tree().get_nodes_in_group(component_group)
	for component in members_from_group:
		# Find the closest parent node of the component that is of type Node2D
		var entity = component._entity
		
		_update_entities_with_entity(entity, component, component_group)

# Called by each components inside "Components" group to each system in "Systems" group when the component is _ready(), anywhere in scene tree
# Used to add components at runtime
func _on_component_added(component: Node) -> void:
	for component_group in _components_requireds:
		if component.is_in_group(component_group):
			# Find the closest parent node of the component that is of type Node2D
			var entity: Node = component._entity
			
			_update_entities_with_entity(entity, component, component_group)

func _on_component_removed(component: Node) -> void:
	var entity: Node = component._entity
	var entity_id: int = entity.get_instance_id()
	
	# if the entity are not in entities, the system will ignore the component remotion
	if entity_id not in entities:
		return
	
	# Check for each group required by the system if the component is part of these group
	for component_group in _components_requireds:
		if component.is_in_group(component_group):
			# It is not compatible, if the component be part of a component_group and this component group be inside _components_requireds
			# but the component is not inside entities variable
			if component_group not in entities[entity_id][1]:
				push_error(
					"Behaviour not expected: The component {0} is from component group {1} who are required by the system {2}, but during remotion from scene its not inside the entities variable. Probably due wrong changes on entities variable".format([component.get_name(), component_group, self.get_name()])
				)
				return
			# Remove the component from the entities
			entities[entity_id][1][component_group].erase(component)
			
			# Check if the component group have no more entities, if so remove the group from the entity inside entities
			if entities[entity_id][1][component_group].is_empty():
				entities[entity_id][1].erase(component_group)
				
				# Check if the entity have no more any component group, if so remove the entity from the system
				if entities[entity_id][1].is_empty():
					entities.erase(entity_id)


## Checks if the specified entity can be operated on by the system.
## This function verifies if the entity meets the requirements to be processed by the system, considering the components associated with the system's component groups.
##
## The function checks two main conditions:
##   1. The system must have the entity stored in its entities dictionary, indicating that the entity is relevant to the system's operations.
##   2. The entity must have at least one component from the specified component group associated with the system.
##
## Parameters:
##   - entity: The entity node to check operability for.
##   - component_group: The name of the component group that the entity's component should belong to.
##   - specific_component_name (optional): The specific name of the component (within the component group) to check for.
## Example Usage: 
##   if can_system_operate_entity(source_entity, "DamageComponentGroup"):
##       # Perform operation on the entities
func can_system_operate_entity(entity: Node, component_group: String, specific_component_name: String="") -> bool:
	var entity_id: int = entity.get_instance_id()
	
	if entity_id not in entities:
		#push_warning("The entity {0} is not part of the system {1}, because this entity does not have any component from {2} groups. So the operation will be ignored".format([entity.get_name(), self.get_name(), _components_requireds]))
		return false
	
	if component_group not in entities[entity_id][1]:
		#push_warning("The entity {0} is part of the system {1}, but there is not a component from the specific group {3} required to fullfit an specific operation. So the operation will be ignored".format([entity.get_name(), self.get_name(), component_group]))
		return false
	
	if specific_component_name != "":
		# take all names of the components from component_group that belongs to entity
		var components_names = []
		for component in entities[entity_id][1][component_group]:
			components_names.append(component.get_name())
		
		# check if the given specific_component_name is part of the group
		if specific_component_name not in components_names:
			push_warning("The component {0}, that belongs to the entity {1} is not part of the group {2}".format([specific_component_name, entity.get_name(), component_group]))
			return false
	
	var number_of_components_from_same_group: int = len(entities[entity_id][1][component_group])
	if number_of_components_from_same_group == 0:
		push_warning("Behaviour not expected: The system {0} somehow have the entity {1} with component group {2}, but the group is empty".format([self.get_name(), entity.get_name(), component_group]))
		return false
	
	if number_of_components_from_same_group >= 2 and specific_component_name == "":
		print(specific_component_name)
		push_warning("The entity '{0}' has multiple components from the group '{1}'. The system '{2}' cannot determine which component to use for the operation. Please specify a specific component name. The operation will be ignored.".format([entity.get_name(), component_group, self.get_name()]))
		return false
	
	return true

## Work with can_system_operate_entity function, this function will return the component instead of true or false
## Usualy used by the system to take the reference of the component
func get_component_from_entity(entity: Node, component_group: String, specific_component_name: String = "") -> BaseComponent:
	var entity_id: int = entity.get_instance_id()
	if can_system_operate_entity(entity, component_group, specific_component_name) == true:
		## If passes the tests with specific_component_name equal to "", means there is only one component from the component_group
		if specific_component_name == "":
			return entities[entity_id][1][component_group][0]
		
		for component in entities[entity_id][1][component_group]:
			var component_name = component.get_name()
			if component_name == specific_component_name:
				return component
				
	return null

class CalcLink:
	var _value: Variant:
		set(new_value):
			if typeof(new_value) not in [TYPE_INT, TYPE_FLOAT]:
				push_error("The value {0} must be a numeric value (int or float)".format([new_value]))
				return
			_value = new_value
		
	var _tag: String
	
	func _init(value: Variant, tag: String = ""):
		_value = value
		_tag = tag

## Its an utility class, it was designed to perform mathematic operations in a flexible way (for now using sum, multiplication and division)
## Each chain have an operation, and was designed to have only one operation, and this operation tell how the links must be merged. You can think chains as () in a mathemmatic expression
## The links in the chain can be: int, float or another CalcChain
## For example, if there is the values A, B, C and D. And the Calc expected are: result = (A + B) * (C + D)
## It could be, Ex1:
## sub_chain1 = CalcChain.new("sum").add_multiple_numeric_links([A, B])
## sub_chain2 = CalcChain.new("sum").add_numeric_link(C).add_numeric_link(D)
## main_chain = CalcChain.new("multiplication").add_multiple_links([sub_chain1, sub_chain2])
## result = main_chain.get_calculated_chain()
## 
## Ex2:
## main_chain = CalcChain.new("multiplication").add_numeric_chain("sum", [A, B]).add_numeric_chain("sum", [C, D])
## result = main_chain.get_calculated_chain()
## And many others ways...
class CalcChain:
	const POSSIBLE_OPERATIONS: Array[String] = ["sum", "multiplication", "division"]
	
	func sum(value: float) -> float: return _chain_value + value
	func multiplication(value: float) -> float: return _chain_value * value
	func division(value: float) -> float: return _chain_value / value if value != 0 else _chain_value #Ignore if the link in divisior is 0
	
	## Actualy the function used to perform the operation
	var _operator: Callable
	
	## An array who contains links, so links together makes a chain
	var _chain: Array
	
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
	
	# Add a link in the _chain, it MUST be a CalcLink or another CalcChain
	# If the index be -1 its means the last position in the chain
	func add_link(link: Variant, index: int = -1) -> CalcChain:
		assert(link is CalcChain or link is CalcLink, \
		"The link {0} must be a CalcLink or another chain".format([link]))
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
	
	## Add a link using the value directly, its make possible to add a link without instancing it before
	func add_numeric_link(value: Variant, index: int = -1, tag: String = "") -> CalcChain:
		var link: CalcLink = CalcLink.new(value, tag)
		add_link(link, index)
		return self
	
	## add multiple links. Check add_link()
	func add_multiple_links(links: Array) -> CalcChain:
		if links.is_empty():
			push_error("'links' argument must have at least one link, but it's empty")
			
		for link in links:
			add_link(link)
			
		return self
	
	## Add multiple links direct, without instancing the links before. If tags does not have enought names to
	## match with values, new empty strings will be added. 
	## If tags have more names than values have items, the excedent will be ignored
	func add_multiple_numeric_links(values: Array[Variant], tags: Array[String] = []) -> CalcChain:
		var delta_lenght: int = len(values) - len(tags)
		# will be higher than 0 if more values was given than tags, its used to fill the rest with empty strings
		if delta_lenght > 0:
			var dummy_array: Array[String]
			dummy_array.resize(delta_lenght)
			dummy_array.fill("")
			tags.assign(dummy_array)
			
		for i in range(len(values)):
			add_numeric_link(values[i], -1, tags[i])
		
		return self
	
	## An shorthand to add a chain directly
	func add_chain(operation: String, links: Array, index: int = -1) -> CalcChain:
		add_link(CalcChain.new(operation).add_multiple_links(links), index)
		return self
	
	## An shorthand to add a chain directly, and without instancing its links child
	func add_numeric_chain(operation: String, values: Array[Variant], tags: Array[String] = [], index: int = -1) -> CalcChain:
		add_link(CalcChain.new(operation).add_multiple_numeric_links(values, tags), index)
		return self
	
	func remove_link_by_index(index: int) -> void:
		if index < -1:
			push_error("The index MUST be higher or equal to -1, given {0} instead".format([index]))
			
		elif index == -1:
			_chain.pop_back()
		elif len(_chain) >= index:
			_chain.remove_at(index)
		else:
			push_error("Invalid Index: The index value perpass the lenghth of the chain")
		is_chain_updated = false
	
	## First it will check in for every link in the chain, if recursivaly are true, it will then check for the children if not found in the main chain
	func remove_link_by_tag(tag: String, recursivaly: bool = false):
		var found_link = false
		for link in _chain:
			if link is CalcLink:
				if link._tag == tag:
					_chain.erase(link)
					found_link = true
					break
			
					
	
	func _get_link_value(link: Variant): #Return float or null
		if link is CalcLink:
			#_effects_names.append(null)
			return link._value
		elif link is CalcChain:
			#_effects_names.append(link.get_effects_names())
			return link.get_calculated_chain()
		else:
			push_error("Behaviour not expected, for some reason _chain have a value who are not CalcLink or CalcChain, found {0}".format([link]))
			return null
	
	func update_chain() -> void:
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
	
