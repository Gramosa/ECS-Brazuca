extends Resource

## This class provide a bunch of classes used to perform calculations, 
## It was designed to be utilized by the systems
class_name CalculationManager

## This class provide a bunch of classes used to perform calculations, 
class CalcBase:
	var _tag: String
	func _init(tag: String = ""):
		_tag = tag

class CalcLink extends CalcBase:
	var _value: float
	var _timer: Timer = Timer.new()
	
	func _init(value: float, tag: String = ""):
		_value = value
		_tag = tag
	
	func duplicate() -> CalcLink:
		var new_link = CalcLink.new(_value, _tag)
		return new_link

## Its an utility class, who designs an DAG (directed acyclic graph), that was designed to perform mathematic operations in a flexible way (for now using sum, multiplication and division)
## Each chain have an operation, and was designed to have only one operation, and this operation tell how the links must be merged. You can think chains as () in a mathemmatic expression
## The links in the chain can be: a Calclink or another CalcChain
## For example, if there is the CalcLinks A, B, C and D. And the Calc expected are: result = (A + B) * (C + D)
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
## In fact it are a
class CalcChain extends CalcBase:
	const POSSIBLE_OPERATIONS: Array[String] = ["sum", "multiplication", "division"]
	
	func sum(value: float) -> float: return _chain_value + value
	func multiplication(value: float) -> float: return _chain_value * value
	func division(value: float) -> float: return _chain_value / value if value != 0 else _chain_value #Ignore if the link in divisior is 0
	
	## Actualy the function used to perform the operation
	var _operator_function: Callable
	
	## An array who contains links, so links together makes a chain
	var _chain: Array[CalcBase]
	
	## Actually all chains who may hold this chain as child
	var _parents: Array[CalcChain]
	
	# The value calculated of the chain and subchains
	var _chain_value: float
	
	## Will be true if the chain was calculated, and the chain was not changed.
	## Used to avoid performing the same operation again, if it was already made
	var is_chain_updated: bool
	
	## Every link in the chain are united by the specified operation, this operation define what function are used for operation
	var _operation: String:
		set(new_operation):
			assert(new_operation in POSSIBLE_OPERATIONS, "The operation {0} must be inside POSSIBLE_OPERATIONS".format([new_operation]))
			_set_is_update_recursivaly(false)
			match new_operation:
				"sum":
					_operator_function = sum
				"multiplication":
					_operator_function = multiplication
				"division":
					_operator_function = division
				_:
					push_error("Behaviour not expected, the operation must be sum, multiplication or division, not {0}".format(_operation))
			
			_operation = new_operation
			
	func _init(operation: String, tag: String = "") -> void:
		_operation = operation
		_tag = tag
	
	static func can_register_parent_chain(child_chain: CalcChain, parent_chain: CalcChain) -> bool:
		if child_chain == parent_chain:
				push_error("The chain {0} cannot be a parent of himself".format([child_chain._tag]))
				return false
				
		if child_chain in parent_chain._parents:
			push_error("Circular parenting: The chain {0} cannot be added as a child, because it are already parent of the chain {1}.".format([child_chain._tag, parent_chain._tag]))
			return false
		else:
			for grandparent in parent_chain._parents:
				if not can_register_parent_chain(child_chain, grandparent):
					return false
		return true
	
	func duplicate(as_simbling : bool = false) -> CalcChain:
		var new_chain = CalcChain.new(_operation, _tag)
		if as_simbling:
			for parent in _parents:
				parent.add_link(new_chain)
				
		for link in _chain:
			new_chain.add_link(link.duplicate())
			
		new_chain._chain_value = _chain_value
		new_chain.is_chain_updated = is_chain_updated
		
		return new_chain
	
	## Actually with this implemnentation, its possible to child chains set parents to false.
	## update_chain is responsible for setting children recursivaly to true
	func _set_is_update_recursivaly(status: bool) -> void:
		if status == true:
			push_error("You cannot infer parent chain are updated, because there is no track for simbling chains")
			return
		is_chain_updated = status
		if _parents.is_empty() == false:
			for parent_chain in _parents:
				parent_chain._set_is_update_recursivaly(status)
	
	# Add a link in the _chain, it MUST be a CalcLink or another CalcChain
	# If the index be -1 its means the last position in the chain
	func add_link(link: CalcBase, index: int = -1) -> CalcChain:
		assert(link is CalcChain or link is CalcLink, \
		"The link {0} must be a CalcLink or another chain".format([link._tag]))
		
		if link is CalcChain:
			if can_register_parent_chain(link, self) == false:
				return null
		
		if index < -1 or index > len(_chain):
			push_error("Invalid Index: Index {0} from chain {1} is out of the range".format([index, self._tag]))
			return null
		
		if index == -1:
			_chain.append(link)
		else:
			_chain.insert(index, link)
		
		_set_is_update_recursivaly(false) # must be set before updating _parents
		if link is CalcChain:
			link._parents.append(self) # Add himself as a parent of the link
		
		return self
	
	## add multiple links. Check add_link()
	func add_multiple_links(links: Array[CalcBase]) -> CalcChain:
		if links.is_empty():
			push_error("'links' argument must have at least one link, but it's empty")
			
		for link in links:
			add_link(link)
			
		return self
	
	## Add a link using the value directly, its make possible to add a link without instancing it before
	func add_numeric_link(value: float, tag: String="", index: int = -1) -> CalcChain:
		add_link(CalcLink.new(value, tag), index)
		return self
	
	## Create multiple links directly, without instancing the links before. If tags does not have enought names to
	## match with values, new empty strings will be added. 
	## If tags have more names than 'values' have items, the excedent will be ignored
	func add_multiple_numeric_links(values: Array[float], tags: Array[String] = []) -> CalcChain:
		var delta_lenght: int = len(values) - len(tags)
		# will be higher than 0 if more values was given than tags, its used to fill the rest with empty strings
		if delta_lenght > 0:
			var dummy_array: Array[String]
			dummy_array.resize(delta_lenght)
			dummy_array.fill("")
			tags.assign(dummy_array)
		
		for i in range(len(values)):
			add_numeric_link(values[i], tags[i])
		
		return self
	
	"""Corrigir depois"""
	func remove_link_by_index(index: int) -> void:
		if index < -1 or index > len(_chain):
			push_error("Invalid Index: Index {0} from chain {1} is out of the range".format([index, self._tag]))
			return
		elif index == -1:
			_chain.pop_back()
		else:
			_chain.remove_at(index)
		
		_set_is_update_recursivaly(false)
	
	func _get_link_value(link: CalcBase): #Return float or null
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
			push_warning("The chain {0} are empty, it must have at least one item".format([_tag]))
			return
		
		_chain_value = _get_link_value(_chain[0])
		if _chain_value == null:
			return
		var _chain_without_first = _chain.slice(1)
		for link in _chain_without_first:
			var link_value: float = _get_link_value(link)
			if link_value == null:
				continue
			_chain_value = _operator_function.call(link_value)
		
		is_chain_updated = true
	
	func get_calculated_chain() -> float:
		if is_chain_updated == false:
			update_chain()
			
		return _chain_value
	
	func get_link_by_tag(tag: String) -> CalcBase:
		for link in _chain:
			if link._tag == tag:
				return link
			
		return null
	
	## This method will take a link recursivaly using the DFS alghoritm (Depth-first Search).
	## This means, it will search on subchains first (if one are encountered).
	func get_link_by_tag_dfs(tag: String) -> CalcBase:
		for link in _chain:
			if link._tag == tag:
				return link
			if link is CalcChain:
				var found_link = link.get_link_by_tag_dfs(tag)
				if found_link != null:
					return found_link
			
		return null
	
	## This method take a link usign the BFS alghortim (Breadth-first Search)
	## This means, it will search the link in the current chain first (neighbor nodes), and then search the sub chains
	## It is expected to be faster than dfs since does not utilize recursion
	func get_link_by_tag_bfs(tag: String) -> CalcBase:
		var queue: Array = _chain.duplicate()
		
		while queue.size() > 0:
			var current_link = queue.pop_front()
			if current_link._tag == tag:
				return current_link
			if current_link is CalcChain:
				queue += current_link._chain.duplicate()
		
		return null
	
	## First it will check in for every link in the chain, if recursivaly are true, it will then check for the children if not found in the main chain
	func remove_link_by_tag(tag: String) -> CalcChain:
		var link_to_remove: CalcBase
		
		link_to_remove = get_link_by_tag(tag)
		
		if link_to_remove != null:
			_chain.erase(link_to_remove)
			if link_to_remove is CalcChain:
				link_to_remove._parents.erase(self)
			
			_set_is_update_recursivaly(false)
		else:
			push_warning("link with tag {0} not found on the chain {1}, try 'remove_link_from_subchain'".format([tag, self._tag]))
		
		return self
	
	func remove_link_from_subchain(subchain_tag: String, tag: String) -> CalcChain:
		var subchain: CalcBase = get_link_by_tag_bfs(subchain_tag)
		if subchain is CalcChain:
			subchain.remove_link_by_tag(tag)
		elif subchain is CalcLink:
			push_error("The link {0} exists on {1} chain, but it is a CalcLink. Must be a CalcChain".format([subchain_tag, self._tag]))
		elif subchain == null:
			push_error("The subchain {0} does not exists on chain {1}".format([subchain_tag, self._tag]))
		
		return self

"""Nudar os nomes dos metodos no futuro, por algo mais descritivo"""
class CalcChainFactory:
	## An shorthand to create a chain directly filled with links/chains
	static func calc_chain(operation: String, links: Array[CalcBase], chain_tag: String = "") -> CalcChain:
		var chain = CalcChain.new(operation, chain_tag)
		for link in links:
			chain.add_link(link)
		return chain
	
	static func numeric_calc_chain(
	operation: String, 
	values: Array[float], 
	chain_tag: String = "", 
	links_tags: Array[String] = []) -> CalcChain:
		var links: Array[CalcBase]
		links.assign(CalcLinkFactory.multiple_numeric_links(values, links_tags))
		return calc_chain(operation, links, chain_tag)
	
	# tags ignored: div
	# (([buff*]/[debuff*]) * multiplication_main)
	static func stat_mod_ratio() -> CalcChain:
		var buff: CalcChain = CalcChain.new("multiplication", "buff").add_numeric_link(1)
		var debuff: CalcChain = CalcChain.new("multiplication", "debuff").add_numeric_link(1)
		
		var new_chain: CalcChain = CalcChain.new("multiplication", "multiplication_main")\
		.add_link(calc_chain("division", [buff, debuff], "div"))
		return new_chain
	
	# tags ignored: div
	# ([sum_main+] * ([buff*]/[debuff*]) * multiplication_main)
	static func stat_mod_ratio_plus() -> CalcChain:
		#W Allow sum values direct on the base value before doing the stat_mod_ratio operation
		var plus_chain: CalcChain = CalcChain.new("sum", "sum_main")
		var new_chain: CalcChain = stat_mod_ratio().add_link(plus_chain, 0)
		
		return new_chain

class CalcLinkFactory:
	## Create a link using the value directly
	static func numeric_link(value: float, tag: String="") -> CalcLink:
		return CalcLink.new(value, tag)
	
	## Create multiple links directly, without instancing the links before. If tags does not have enought names to
	## match with values, new empty strings will be added. 
	## If tags have more names than 'values' have items, the excedent will be ignored
	static func multiple_numeric_links(values: Array[float], tags: Array[String] = []) -> Array[CalcLink]:
		var delta_lenght: int = len(values) - len(tags)
		# will be higher than 0 if more values was given than tags, its used to fill the rest with empty strings
		if delta_lenght > 0:
			var dummy_array: Array[String]
			dummy_array.resize(delta_lenght)
			dummy_array.fill("")
			tags.assign(dummy_array)
		
		var links: Array[CalcLink]
		for i in range(len(values)):
			links.append(numeric_link(values[i], tags[i]))
		
		return links
	
	
