class_name FSM
extends Node

# Written by meloonics, 
# https://github.com/meloonics/
# MIT License

## A Class to allow for more complex behavior in any given node
##
## This class, once a host-node is assigned to it, will directly manipulate the host-node
## depending on the current state. [br]
## The FSM only runs, when it has at least one state (which needs to be linked to with default_state)
## and if it is assigned a host-node.
## The host-node can be changed on the fly by calling set_host(). [br]
## The FSM can register FSMState Nodes from anywhere in the tree, using external_states, but it assumes
## its direct children to be States assigned to it [br][br]
## 
## HOW TO USE [br]
##
## Attach script to a node (make a scene for frequent use) and attach node to the object you need the
## state machine for. Attach child nodes to fsm and attach script, that extends 'FSMState' for each state.
## See 'fsm_state.gd' for more info. 

## Any Node, that will be manipulated directly by the states of this FSM
var host : Node : set = set_host
## The path to a default-state, that the FSM will change to when starting up or when things go wrong. Necessary for the FSM to work.
@export_node_path("FSMState") var default_state_path

@onready var default_state : FSMState = get_node(default_state_path)

## Add paths to FSMState-Nodes to this if you need states, that aren't direct children of the FSM
@export var external_states : Array[NodePath]

## Amount of past states being tracked
@export_range(1, 100) var history_buffer_size : int = 10

## current FSMState-Object that is being run by the FSM.
var current_state : FSMState : set = change_state
## Array of past states
var state_history : Array[FSMState]
## List of FSMState-Objects for easy access
var state_list : Array[FSMState]
## Enum of attached FSMState-Objects, usually used for FSMState-Nodes to identify sibling-states. This variable is shared with all attached FSMStates.
var states : Dictionary = {"NONE" = -1, "LAST" = -2, "REVERT" = -3}

## gets emitted, once a host-node is connected or changed.
signal host_connected(new_host : Node)
## gets emitted, once a host-node is disconnected or changed.
signal host_disconnected(old_host: Node)
## gets emitted, when a new state started its 'enter()' method.
signal state_entering(state: FSMState)
## gets emitted, when a new state finished its 'enter()' method.
signal state_entered(state: FSMState)
## gets emitted, when a new state started its 'exit()' method.
signal state_exiting(state: FSMState)
## gets emitted, when a new state finished its 'exit()' method.
signal state_exited(state: FSMState)
## gets emitted any time a new state is registered to the FSM.
signal state_added(state: FSMState)
## gets emitted any time an attached state is unregistered.
signal state_removed(state: FSMState)


func _ready():
	_set_up_fsm()


func _set_up_fsm() -> void:
	for i in get_children():
		if i is FSMState:
			add_state(i)
	
	for i in external_states:
		var node = get_node(i)
		
		if node:
			if node is FSMState:
				add_state(node)
			else:
				printerr(str(self) + " Warning: " + str(node) + " is not a valid FSMState!")
		else:
			printerr(str(self) + " Warning: invalid NodePath " + str(i))

## Links the FSM to a host-node. The FSM will only operate with a valid host.
func set_host(n: Node) -> void:
	
	if host:
		emit_signal("host_disconnected", host)
	
	host = n
	
	if host:
		
		emit_signal("host_connected", host)
		
		for i in state_list:
			if i is FSMState:
				
				# pass host via dependency injection
				i.host = host
		
		change_state_to_default()
		

## adds a state to the state-list. The FSM can only handle states that are added via this method.
func add_state(state: FSMState) -> void:
	state.connect("transition_to", change_state_to)
	state.connect("transition_to_default", change_state_to_default)
	state.connect("transition_to_last", change_state_to_last)
#	state.connect("state_entering", on_state_entering)
#	state.connect("state_entered", on_state_entered)
#	state.connect("state_exiting", on_state_exiting)
#	state.connect("state_exited", on_state_exited)
	
	#safety measure, prevents the fsm from breaking if attached state nodes are freed.
	state.connect("state_exiting_tree", remove_state)
	# pass reference of state-enum to each state-object
	state.states = states
	
	# register state in the list and enum
	var state_name : StringName = _get_trimmed_name(state.name)
	var state_index : int = 0
	
	while states.values().has(state_index):
		state_index += 1
	
	state.state_name = state_name
	state.state_index = state_index
	
	states[state_name] = state_index
	state_list.append(state)
	
	# assign host if one exists already
	if host:
		state.host = host
	
	emit_signal("state_added", state)

## This function gets called automatically if an attached FSMState-Node gets freed. Use this to safely remove a state from the FSM.
func remove_state(state: FSMState) -> void:
	state.disconnect("transition_to", change_state_to)
	state.disconnect("transition_to_default", change_state_to_default)
	state.disconnect("transition_to_last", change_state_to_last)
#	state.disconnect("state_entering", on_state_entering)
#	state.disconnect("state_entered", on_state_entered)
#	state.disconnect("state_exiting", on_state_exiting)
#	state.disconnect("state_exited", on_state_exited)
	
	states.erase(state.state_name)
	state_list.erase(state)
	
	state.host = null
	
	emit_signal("state_removed", state)

## Changes states via index. Can be called to brute-force a state-transition, 
## but it is intended for the FSMState-Objects to handle the transition logic.
func change_state_to(index: int):
	change_state(state_list[index])

## Helper-Function to quickly transition to the default-state.
func change_state_to_default() -> void:
	change_state(default_state)

## Helper-Function to quicky transition to the last active state.
func change_state_to_last() -> void:
	if not state_history.is_empty():
		change_state(state_history.back())
	else:
		change_state_to_default()

func revert_state(state_amount: int) -> void:
	assert(state_amount >= 0 and state_amount <= state_history.size(), "FSM Error: Amount of states to revert is out of bounds")
	change_state(state_history[state_history.size() - state_amount - 1])

## Setter function for current_state.
func change_state(new_state : FSMState) -> void:
	var old_state : FSMState = current_state
	if old_state:
		_track_state(old_state)
		emit_signal("state_exiting", old_state)
		await old_state.exit()
		emit_signal("state_exited", old_state)
	current_state = new_state
	
	# only when the enter() function of the state has completely finished, the host
	# is considered "in that state"
	emit_signal("state_entering", current_state)
	await current_state.enter()
	emit_signal("state_entered", current_state)

func _physics_process(delta) -> void:
	#placeholder check. you can replace this with your own logic (e.g. prevent the fsm from running during cutscenes)
	if true: 
		
		if host:
			
			if current_state:
				
				# runs once per frame but only if the enter() function has finished.
				if current_state.state_active:
					current_state.update(delta)
				
				# runs once per frame but only when not entering or exiting the state.
				if current_state.can_transition():
					current_state.handle_transition()

func _track_state(state : FSMState) -> void:
	if state_history.size() == history_buffer_size:
		state_history.remove_at(0)
	state_history.append(state)

# This turns the name of the state-node into a usable enum entry for convenience.
# a state-node called "player_idle" turns into "IDLE", 
# be careful with your underscores when naming your state nodes.
func _get_trimmed_name(state_name : String) -> StringName:
	return state_name.substr(state_name.find("_") + 1).to_upper() as StringName



