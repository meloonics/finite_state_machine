class_name FSMState
extends Node

# Written by meloonics, 
# https://github.com/meloonics/
# MIT License

# HOW TO USE:
# Extend this script and override the update(), transition(), _enter() and _exit() functions to your liking

#some info to identify the states a little better later on
var state_name : StringName
var state_index : int

# these are the state's states so to say :P
var state_active : bool = false: set = set_state_active
var is_exiting : bool = false
var is_entering : bool = false

# reference to sibling states passed on by parent fsm
var states : Dictionary

#reference to host-node, so it can be directly manipulated
var host : Node

#needs to be set to 0 or a positive number and transition_revert needs to be emitted in order for the FSM to revert to a past state.
var revert_amount : int = -1

# communication with parent fsm
signal transition_to
signal transition_to_default
signal transition_to_last
signal transition_revert
signal state_entering(state: FSMState)
signal state_entered(state: FSMState)
signal state_exiting(state: FSMState)
signal state_exited(state: FSMState)
signal state_exiting_tree(state: FSMState)

# do not override this function! use _enter() instead!
func enter():
	is_entering = true
	revert_amount = -1
	emit_signal("state_entering", self)
	assert(states.size() > 2, 
		"State Error in " + name + 
		".gd: states reference has no states!")
	await _enter()
	is_entering = false
	set_state_active(true)

# set up your animations here
func _enter():
	pass

# do not override this function! use _exit() instead!
func exit():
	is_exiting = true
	emit_signal("state_exiting", self)
	await _exit()
	is_exiting = false
	set_state_active(false)

# virtual_method
func _exit():
	pass

# put your state logic here, this only runs after enter() is finished.
func update(_delta: float) -> void:
	pass

func handle_transition() -> void:
	var trans = _transition()
	match trans:
		states.NONE:
			pass
		states.LAST:
			emit_signal("transition_to_last")
		states.REVERT:
			assert(revert_amount >= 0, "Invalid amount of state-reverts, Needs to be 0 or positive!")
			emit_signal("transition_revert", revert_amount)
		_:
			emit_signal("transition_to", trans)

# called once a physics-frame. put your transition-logic here
# if you don't wanna change states, you must pass 'states.NONE'
func _transition() -> int:
	return states.NONE
# NOTE:
# Here's an example on how to revert to the second-to last state in this function:
# 
# revert_amount = 1 # first, set how many states you want to revert.
# return states.REVERT # then return the REVERT-Constant.
#
# revert_amount = 0 is identical to 'states.LAST'. 
# You can basically go to the last element of the array, then move revert_amount steps backwards.


# this prevents the state from updating while the enter-animation is still running.
func set_state_active(active: bool):
	state_active = active
	if state_active:
		emit_signal("state_entered", self)
	else:
		emit_signal("state_exited", self)

# the state only sends transition requests, when it's not in a transition already.
func is_busy() -> bool:
	return is_exiting or is_entering

# if this node gets freed for some reason, the attached fsm will unregister it.
func _exit_tree():
	emit_signal("state_exiting_tree", self)
