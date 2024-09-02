"""AINDA EM ESTADO DE IMPLEMENTAÇÃO"""
extends Object

## A class designed to take and insert the information from the BRZErrContext, and act as a layer between the error call
## And the error output, also it allow modifying and logging the context before dispatching the context
## It uses a concept similar to the singleton and command pattern
class_name BRZErr

static func __log():
	pass

static func warning(context: BRZErrContext):
	context.set_type(BRZErrContext.TYPE.WARNING)
	push_warning(context)
	
static func soft_error(context: BRZErrContext):
	context.set_type(BRZErrContext.TYPE.SOFT_ERROR)
	push_error(context)

static func hard_error(context: BRZErrContext):
	context.set_type(BRZErrContext.TYPE.HARD_ERROR)
	push_error(context)
