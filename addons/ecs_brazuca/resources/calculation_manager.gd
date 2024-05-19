extends Resource

#TODO: Move the CalcFormula from a inner class to actually a Resource outter class

## This class provide an intermediate step to perform calculations
## It was designed to be utilized by the systems
class_name CalculationManager

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
		
		for child in _children:
			if child._key == key:
				return child
		
		return null

class CalcFormula:
	var _head: CalcNode
	var calculator: Expression = Expression.new()
	
	func _init():
		_head = CalcNode.new('.')
	
	func to_expression() -> String:
		return str(_head)
	
	func evaluate() -> float:
		var formula_txt: String = to_expression()
		var error: Error = calculator.parse(formula_txt)
		if error != OK:
			push_error(calculator.get_error_text())
			return -1
		
		var value: float = calculator.execute()
		if calculator.has_execute_failed():
			push_error("Fail on executing the formula {0}".format([formula_txt]))
			return -1
		
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
		
		node._children.append(child)
		child._parent = weakref(node)
	
	func remove(path: String):
		if(path == "."):
			push_error("Cannot remove the root node, so the path cannot be '.'")
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
