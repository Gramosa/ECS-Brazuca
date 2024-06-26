"""PARCIALMENTE FUNCIONAL, NÃO IMPLEMENTADO"""
@tool
extends Resource

class_name BrazucaAbilityData

## Its tell how the system must deal when an target path does not exist.
enum NOT_FOUND_BEHAVIOUR {IGNORE=0, RAISE_ERROR=1, AWAIT=2}

## Its tell how the system must deal when a duplicated effect are applied.
enum DUPLICATED_BEHAVIOUR {
	IGNORE=0, REPLACE=1, KEEP_HIGHER=2, KEEP_LOWER=3, SUM=4, DEC=5, MULT=6, DIV=7
}

## The specific name of the ability, for tracking and organization, like Burn, Freeze and etc...
## This will be the same name used for the CalcNode added in the formula
@export var name: String = ""

## The actual numeric value used to modify the target property
@export var value: float = 0.0

## The duration of the effect, if 0 the effect will not be applied, if less than 0 the effect will be considered permanent.
## A permanent effect are NOT removed automatically by the system with a cooldown
@export var duration: float = 0.0

## Its tell the system what position in the CalcFormula the effect will be added
@export var target_path: String = ""

## What must be done if the designed path does not exist in the formula
@export var not_found_behaviour: NOT_FOUND_BEHAVIOUR = NOT_FOUND_BEHAVIOUR.IGNORE

## This tell how the system must deal if the same ability already be applied
@export_group("Duplicated Behaviour")

## How the system must modify the property
@export var value_behaviour: DUPLICATED_BEHAVIOUR = DUPLICATED_BEHAVIOUR.IGNORE

## How the system must modify the duration
@export var duration_behaviour: DUPLICATED_BEHAVIOUR = DUPLICATED_BEHAVIOUR.IGNORE

