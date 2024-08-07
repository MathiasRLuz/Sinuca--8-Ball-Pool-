extends Node

@export var ball_scene : PackedScene

var ball_images := []
var cue_ball
const START_POS := Vector2(890,340)
const MAX_POWER := 8.0
const MOVE_THRESHOLD := 5.0
var taking_shot : bool
var cue_ball_potted : bool
var potted := []

# Called when the node enters the scene tree for the first time.
func _ready():
	load_images()
	new_game()
	$Mesa/buracos.body_entered.connect(potted_ball)

func load_images():
	for i in range(1,17,1):
		var filename = str("res://assets/ball_",i,".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)

func new_game():
	generate_balls()
	reset_cue_ball()
	show_cue()
	
func generate_balls():
	var count : int = 0
	var rows : int = 5
	var diameter = 36
	for col in range(5):
		for row in range(rows):
			var ball = ball_scene.instantiate()
			var pos = Vector2(250 + (col * diameter), 267 + (row * diameter) + (col * diameter / 2))			
			ball.position = pos
			ball.get_node("Sprite2D").texture = ball_images[count]
			count += 1
			ball.name = "ball_" + str(count)
			add_child(ball)
		rows -= 1
		
func remove_cue_ball():
	var old_b = cue_ball
	remove_child(old_b)
	old_b.queue_free()
	
func reset_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball)
	cue_ball.position = START_POS
	cue_ball.get_node("Sprite2D").texture = ball_images.back() # última imagem do array
	taking_shot = false
	
func show_cue():
	$Taco.position = cue_ball.position
	$Taco.show()
	$PowerBar.show()
	$PowerBar.position.x = cue_ball.position.x - (0.5 * $PowerBar.size.x)
	$PowerBar.position.y = cue_ball.position.y + $PowerBar.size.y
	$Taco.set_process(true)
	
func hide_cue():
	$Taco.set_process(false)
	$Taco.hide()
	$PowerBar.hide()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var moving := false
	for b in get_tree().get_nodes_in_group("bolas"):
		if (b.linear_velocity.length() > 0.0 and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
			
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
	if not moving:
		# check if the cue ball has been potted and reset it
		if cue_ball_potted:
			reset_cue_ball()
			cue_ball_potted = false
		
		if not taking_shot:
			taking_shot = true
			show_cue()
	else:
		if taking_shot:
			taking_shot = false
			hide_cue()

func _on_taco_shoot(power):
	cue_ball.apply_central_impulse(power)

func potted_ball(body):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	else:
		print(body.name)
		potted.append(body)
		body.hide()
