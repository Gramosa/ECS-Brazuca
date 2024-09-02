extends RefCounted

## A class designed to have all the information that may be needed to handle and deal with errors
## This class is used by BRZErr, and is built based on the fluent/builder pattern
class_name BRZErrContext

enum TYPE {
	WARNING = 0,
	SOFT_ERROR = 1,
	HARD_ERROR = 2
}

enum CODE {
	GENERIC = -1,
	COMPONENT = 0,
	COMPONENT_NOT_FOUND = 1,
	COMPONENT_PROPERTY_NOT_FOUND = 2,
	
	SYSTEM = 100,
	
	SIGNAL = 200,
	SIGNAL_NOT_CONNECTED = 201
}

var type: TYPE
var code: CODE
var message: String = ""
var details: String = ""
var action_taken: String = ""
var proposed_solution: String = ""
var offending_items: Array = []

func _init(code: CODE = CODE.GENERIC) -> void:
	self.code = code

func _to_string() -> String:
	var txt = "BRZ {0}: {1}".format([TYPE.find_key(type), CODE.find_key(code)])
	txt += "\n" + (message if message != "" else "NO MESSAGE")
	txt += (" | " + details) if details != "" else ""
	txt += "\n" + (action_taken if action_taken != "" else "NO ACTION TAKEN")
	txt += (" | " + proposed_solution) if proposed_solution != "" else ""
	
	return txt

func set_type(type: TYPE) -> BRZErrContext:
	self.type = type
	return self

func set_code(code: CODE) -> BRZErrContext:
	self.code = code
	return self

func set_message(message: String) -> BRZErrContext:
	self.message = message
	return self

func set_details(details: String) -> BRZErrContext:
	self.details = details
	return self

func set_action_taken(action_taken: String) -> BRZErrContext:
	self.action_taken = action_taken
	return self

func set_proposed_solution(proposed_solution: String) -> BRZErrContext:
	self.proposed_solution = proposed_solution
	return self

func set_offending_items(offending_items: Array) -> BRZErrContext:
	self.offending_items = offending_items.duplicate()
	return self
