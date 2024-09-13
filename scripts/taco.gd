extends Sprite2D
signal shoot
var power : float = 0.0
var power_direction : int = 1
@export var power_multiplier : int
@onready var raycast = $"../RayCast2D"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_pos := get_global_mouse_position()	
	look_at(mouse_pos)
	# check for mouse clicks
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		power += power_direction * 30	* delta	
		if power >= get_parent().MAX_POWER:
			power_direction = -1
		elif power <= 0:
			power_direction = 1 
	else:
		power_direction = 1 
		if power > 0 :
			var dir = mouse_pos - position
			dir = dir.normalized()
			#power = get_parent().MAX_POWER
			power *= power_multiplier
			print((power * dir).length())
			shoot.emit(power * dir)
			power = 0
	
