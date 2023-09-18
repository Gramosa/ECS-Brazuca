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
	var _value: Variant:
		set(new_value):
			if typeof(new_value) not in [TYPE_INT, TYPE_FLOAT]:
				push_error("The value {0} must be a numeric value (int or float)".format([new_value]))
				return
			_value = new_value
	
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
class CalcChain extends CalcBase:
	const POSSIBLE_OPERATIONS: Array[String] = ["sum", "multiplication", "division"]
	
	func sum(value: float) -> float: return _chain_value + value
	func multiplication(value: float) -> float: return _chain_value * value
	func division(value: float) -> float: return _chain_value / value if value != 0 else _chain_value #Ignore if the link in divisior is 0
	
	## Actualy the function used to perform the operation
	var _operator_function: Callable
	
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
	
	# Add a link in the _chain, it MUST be a CalcLink or another CalcChain
	# If the index be -1 its means the last position in the chain
	func add_link(link: Variant, index: int = -1) -> CalcChain:
		assert(link is CalcChain or link is CalcLink, \
		"The link {0} must be a CalcLink or another chain".format([link]))
		if index < -1:
			push_error("The index MUST be higher or equal to -1, given {0} instead".format([index]))
		elif index == -1:
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
	func remove_link_by_tag(tag: String, recursivaly: bool = false) -> bool:
		var found_link = false
		for link in _chain:
			if link._tag == tag:
				_chain.erase(link)
				found_link = true
				break
		
		if recursivaly:
			for link in _chain:
				if link is CalcChain:
					if link.remove_link_by_tag(tag, recursivaly):
						found_link = true
						break
		if found_link:
			is_chain_updated = false
			
		return found_link
	
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
			_chain_value = _operator_function.call(link_value)
		
		is_chain_updated = true
	
	func get_calculated_chain() -> float:
		if is_chain_updated == false:
			update_chain()
			
		return _chain_value
	
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
	func get_link_by_tag_bfs(tag: String) -> CalcBase:
		var queue: Array = _chain.duplicate()
		
		while queue.size() > 0:
			var current_link = queue.pop_front()
			if current_link._tag == tag:
				return current_link
			if current_link is CalcChain:
				queue += current_link._chain.duplicate()
		
		return null
