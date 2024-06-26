extends Resource

## This class provide an intermediate step to perform calculations
## It was designed to be utilized by the systems
class_name CalcFormula

@export var signature: String = ""

var _head: CalcNode
var _calculator: Expression = Expression.new()

## Build a tree from a start signature, which looks like a math formula but onty with the keys
## Ex: (A + B) - C will be:
## [root]
## +-->[A]
## |   +-->[+B]
## +-->[-C]
## Nested arrays that does not have the key between '(' are created with a dummy key
## Ex: ((A + B) / C) + D
## root
##   dummy0
##     A
##       +B
##     /C
##   +D
func build_from_signature() -> bool:
	
	if(__check_parentesis(signature) == false):
		push_error("Invalid signature {0}, wrong use of parentesis!".format([signature]))
		return false

	const OPERATORS: PackedStringArray = ['+', '-', '*', '/', '^']
	var tokens: PackedStringArray = __tokenize_signature(signature)
	
	#helper variables
	var current_node: CalcNode = _head
	var stack: Array[CalcNode] = [current_node]
	var operator: String = ""
	var have_children: bool = false
	var dummy_counter: int = 0
	
	for token in tokens:
		if token in OPERATORS:
			if operator == "":
				operator = token
			else:
				push_error("Consecutive operators in the signature {0}!".format([signature]))
				return false
		elif token == '(':
			current_node = CalcNode.new("dummy" + str(dummy_counter), "", operator)
			stack.back().add_child(current_node) # it may always work, since each dummy node have an unic incremental key
			stack.push_back(current_node)
			
			have_children = true
			dummy_counter += 1
		elif token == ')':
			if not stack.is_empty():
				stack.pop_back()
			else:
				push_error("Behaviour not expected, the stack is empty for signature {0}".format([signature]))
				return false
		else:
			if have_children:
				#TODO: Validate for simblings with the same key.
				stack.back()._key = token
				stack.back()._value = token
				
				have_children = false
				dummy_counter -= 1
			else:
				current_node = CalcNode.new(token, token, operator)
				if not stack.back().add_child(current_node):
					push_error("Could not add the node {0} as child of {1}, for the signaturte {2}".format([token, stack.back()._key, signature]))
					return false
			
			operator = ""
		
	if stack.size() != 1:
		push_error("Behaviour not expected, in the end it expects only the head node to be at the stack, for the siganture {0}".format([signature]))
		return false
	
	if operator != "":
		push_error("Found a standalone operator at end of the signature {0}".format([signature]))
		return false
	
	return true

static func __check_parentesis(string: String) -> bool:
	var count: int = 0
	for letter in string:
		if letter == '(':
			count += 1
		elif letter == ')':
			count -= 1
			if count < 0:
				return false
	
	return true if count == 0 else false

static func __tokenize_signature(signature: String) -> PackedStringArray:
	const SEP: PackedStringArray = ['+', '-', '*', '/', '^', '(', ')']
	var tokens: PackedStringArray = []
	var token: String = ""
	
	signature = signature.replace("**", '^')
	
	for i in signature:
		if i == ' ':
			continue
		
		if i not in SEP:
			token += i
		else:
			if token != '':
				tokens.append(token)
				token = ''
			tokens.append(i)
	
	if token != '':
		tokens.append(token)
	
	return tokens

## This class is the branches/leafs used by the CalcFormula to build the tree
## Each CalcNode MUST have an unic key at same level, so two siblings cannot have the same key (but the tree can have the same key at different levels)
## 
class CalcNode:
	var _key: String #if necessary change to StringName in future
	var _value: String
	var _operator: String
	var _children: Array[CalcNode]
	var _parent: WeakRef # WeakRef<CalcNode>, to avoid memory leaks
	
	func _init(key: String, value: String='', operator: String=''):
		_key = key
		_value = value
		_operator = operator
		_children = []
	
	func _to_string():
		var txt: String = _operator
		var have_parentesis: bool = false
		
		if (_operator != "" and _value[0] == '-') or not _children.is_empty():
			have_parentesis = true
		
		if have_parentesis:
			txt += '('
			
		txt += _value
		for child in _children:
			txt += str(child)
		
		if have_parentesis:
			txt += ')'
		
		return txt
	
	#Verify if some node is an ancestor, maybe it can lead to problem if its needed to diferentiate
	#between not having any parent, or the parent being no more availible. In both cases the result is false
	func has_ancestor(node: CalcNode) -> bool:
		if(node._parent == null):
			return false
		
		var ancestor: CalcNode = _parent.get_ref()
		while(ancestor != null):
			if(ancestor == node):
				return true
			ancestor = ancestor._parent.get_ref()
		return false
	
	func get_child(key: String) -> CalcNode:
		if key == '.':
			return self
		elif key == '..':
			# Beware of recursive or loop calls, it can lead to attempt of retrieving a parent of a null node
			return _parent.get_ref()
		
		for child in _children:
			if child._key == key:
				return child
		
		return null
	
	func add_child(child: CalcNode) -> bool:
		for sibling in _children:
			if child._key == sibling._key:
				return false
		
		_children.append(child)
		child._parent = weakref(self)
		return true

func _init():
	_head = CalcNode.new('root')

func to_expression() -> String:
	return str(_head)

func evaluate() -> float:
	var formula_txt: String = to_expression()
	var error: Error = _calculator.parse(formula_txt)
	if error != OK:
		push_error("Parse error of expression '{0}': ".format([formula_txt]) + _calculator.get_error_text())
		return 0
	
	var value: float = _calculator.execute()
	if _calculator.has_execute_failed():
		push_error("Fail on executing the formula {0}: ".format([formula_txt]) + _calculator.get_error_text())
		return 0
	
	return value

func get_from_path(path: String) -> CalcNode:
	if path.is_empty():
		push_error("The patch cannot be an empty string!")
		return null
	
	var indexes: PackedStringArray = path.split('/', false)
	var node: CalcNode = _head
	
	for i in indexes:
		if node == null:
			break
		
		node = node.get_child(i)
	
	return node

func add(path: String, child: CalcNode):
	var node: CalcNode = get_from_path(path)
	if node == null:
		push_error("Path '{0}' not found in CalcFormula '{1}'".format([path, self]))
		return
	
	if node == child:
		push_error("The node '{0}', from the path '{1}' cannot be a child of himself".format([node._key, path]))
		return
	
	if node.has_ancestor(child):
		push_error("Attempt of inserting the node '{0}' as child of node '{1}', \
		but its already an ancestor, that would lead in circular reference.".format([child._key, node._key])\
		)
		return
	
	if not node.add_child(child):
		push_error("Child with key '{0}' already exists under node '{1}'".format([child._key, node._key]))

func remove(path: String):
	if(path == "root"):
		push_error("Cannot remove the root node, so the path cannot be 'root'")
		return
	
	var path_and_endpoint: PackedStringArray = path.rsplit('/', true, 1)
	if path_and_endpoint.size() == 1:
		path_and_endpoint.insert(0, ".")
	
	var node: CalcNode = get_from_path(path_and_endpoint[0])
	if node == null:
		push_error("Path '{0}' not found in CalcFormula '{1}'".format([path_and_endpoint[0], self]))
		return
	
	var endpoint: CalcNode = node.get_child(path_and_endpoint[1])
	if endpoint == null:
		push_error("Path '{0}' dont have the node '{1}'".format([path_and_endpoint[0], path_and_endpoint[1]]))
		return
	
	node._children.erase(endpoint)
	endpoint._parent = null

#TODO: Permitir atualizar o operator tambem
func update(path: String, value: String):
	var node: CalcNode = get_from_path(path)
	if node == null:
		push_error("Path '{0}' not found in CalcFormula '{1}'".format([path, self]))
		return
	
	node._value = value
