extends FSMState

#note that both the 'state_idle' and the 'state_move' node have the same script, since they're functionally identical

func update(delta: float) -> void:
	host.velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * host.SPEED
	host.move_and_slide()

func _transition() -> int:
	if Input.is_action_just_pressed("ui_accept"):
		return states.CHANGE_CHAR
	
	if host.velocity.is_zero_approx():
		return states.IDLE
	
	return states.NONE
