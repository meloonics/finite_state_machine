# Finite State Machine for Godot 4.x
A demo for a finite state machine in Godot 4.x. Including a short demo and two scripts for you to use and abuse.

This finite state machine is capable of manipulating any node you assign to it during `_physics_process`. The components (host-node, fsm-node, state-nodes) do not have any dependencies on each other, meaning that you can put the fsm and its states anywhere in the scene-tree if need be. You can add and remove states on the fly and even replace the host-node at runtime. Wanna make a game where you play as a poltergeist posessing things? No problem! Wanna design a sleeping enemy, that only attacks when the player is running? Easy! 
The FSM comes with a bunch of signals to communicate its changes to the rest of the scene. That way you can compose complex interactions and make NPC reactions to player behavior easy!

## How to use

### The FSM
You better make a scene consisting of a generic node with `fsm.gd` attached to it. The FSM-Object requires at least 1 state and 1 state, that is marked as `default_state`. For convenience, you can mark the scene as a unique name for easier access inside a scene.
Once you got that set up, you can call `%FSM.set_host(self)` from basically any node you want and the fsm will manage the different states of that node.

### Making states
Create a new script, that starts with `extends FSMState`. Pick a descriptive name for the Node, that the script will be attached to. There are four important methods for you to customize:
#### `update(delta)`
this is basically equivalent to `physics_process`. Override this method to implement state-logic.
#### `_transition()`
this method is also called once every physics frame. Here you'll put your transition logic. You also need to always return an integer value. There are a few constants to go over, `states.NONE` is important if you don't wanna change states in this frame. it should be at the end of any `_transition()`-method, unless you have states, that only last for one frame. `states.LAST` makes the fsm revert to the last active state. That's useful if you have states for playing animations or complex things (such as the player transforming) that require multiple state changes. `states.REVERT`, similarly to `states.LAST` allows you to revert to any past state the fsm has been keeping track of. You can set the amount of states you wanna keep track of in `fsm.gd`.
#### `_enter()`
This gets called once a state becomes active. Only when this method of a state is finished, the FSM will consider itself 'in that state'. You can use this to set animations, change sprites or whatever. 
#### `_exit()`
Similar to `_enter()` but gets called, once the fsm receives a transition request. Only after state A finished its `_exit()` method, the `_enter()` method of state B will begin. 

### Upsides
* You have a bunch of reusable states that you can compose complex node behavior with.
* Assertions make sure, that the most common bugs are found quickly.
* A flexible FSM can help you keep your code DRY

### Downsides
* Having one script for each state might be undesirable, depending on how your project is structured. 
* This project might not be accessible to people newer to Godot and programming. 
* I suck at commenting my code in a understandable way. No complaints or refunds!
* Might be overkill for most scenarios. You need to figure out yourself if it's worth using an FSM over if-else-switch-case-branching

Hope this helps. you can use this out of the box or extend it, or take inspiration from it to make your own, even more awesome state-machines!
