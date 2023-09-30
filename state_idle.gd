extends FSMState


func update(delta: float) -> void:
	host.velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * host.SPEED
	host.move_and_slide()

func _transition() -> int:
	if Input.is_action_just_pressed("ui_accept"):
		return states.CHANGE_CHAR
	
	if not host.velocity.is_zero_approx():
		return states.MOVE
	
	return states.NONE
