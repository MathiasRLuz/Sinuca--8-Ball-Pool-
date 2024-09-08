extends CanvasLayer

@onready var transition: ColorRect = $Fill
@onready var animation: AnimationPlayer = $Fill/Animation

enum Animations {PIXELS, SPOT_PLAYER, SPOT_CENTER, VER_CUT, HOR_CUT}
@export var transition_type: Animations
@export_range (0.5, 2.0) var duration = 1.0

func _set_animation(_transition_type, _duration,_animation_name):
	transition.material.set_shader_parameter("type", _transition_type)
	animation.speed_scale = _duration
	animation.play(_animation_name)
