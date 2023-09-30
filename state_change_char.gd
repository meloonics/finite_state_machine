extends FSMState

func _enter():
	get_parent().set_host(host.other_guy)

func transition() -> int:
	return states.LAST
