extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export_node_path("CharacterBody2D") var other_guy_path
@onready var other_guy : CharacterBody2D = get_node(other_guy_path)
@export_node_path("FSM") var fsm_path

func _ready():
	$PlayerName.set_text("Player " + str(get_index() + 1))
	if fsm_path:
		var fsm = get_node(fsm_path)
		await fsm.ready
		fsm.set_host(self)

func show_state(host : Node):
	if host == self:
		$StateName.show()
	else:
		$StateName.hide()

func update_state(state: FSMState):
	$StateName.set_text(state.state_name)



