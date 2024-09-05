extends Node2D #extends Sprite2D

@export var dice_faces : Array[Texture2D] = []

var _current_texture_index: int = -1
var _animation_time: float = 0.0
var _total_animation_time: float = 1.0  # Duração da animação em segundos
var _is_rolling: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:	
#	var texture = $"../SubViewport".get_texture()
#	$".".texture = texture

func _process(delta: float):
	var index = -1
	if _is_rolling:		
		if _animation_time < _total_animation_time:
			_animation_time += delta
			index = randi() % dice_faces.size()
			$".".texture = dice_faces[index]
		else:
			# Quando a animação acabar, assegura que a última textura seja aplicada
			index = randi() % dice_faces.size()
			$".".texture = dice_faces[index]
			print("----------------- ", index+1)
			_is_rolling = false

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if not _is_rolling:
			start_roulette()

func start_roulette():
	_current_texture_index = -1
	_animation_time = 0.0
	#dice_faces.shuffle()
	_is_rolling = true
	
