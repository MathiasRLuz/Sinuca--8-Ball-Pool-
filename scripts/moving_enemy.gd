class_name Enemy extends Path2D

signal dialogue_finished

@export var sprite_frames : SpriteFrames
@export var loop := false
@export var speed := 0.1
@export var look_at_player := false
@export var npc_name: String
@export var npc_type : GlobalData.Npcs
@export var state_fala : GlobalData.Falas
@export var can_move := true
@export var nearest_table : Sprite2D

@onready var name_text: RichTextLabel = $PathFollow2D/StaticBody2D/AnimatedSprite2D/Dialogue/NinePatchRect/Name
@onready var text_text: RichTextLabel = $PathFollow2D/StaticBody2D/AnimatedSprite2D/Dialogue/NinePatchRect/Text
@onready var dialogue: Control = $PathFollow2D/StaticBody2D/AnimatedSprite2D/Dialogue
@onready var interact_icon: Control = $PathFollow2D/StaticBody2D/AnimatedSprite2D/InteractIcon
@onready var player = $"../Player"
@onready var transition_node = $"../Transition"
@onready var sprite: AnimatedSprite2D = $PathFollow2D/StaticBody2D/AnimatedSprite2D
@onready var path_follow_2d: PathFollow2D = $PathFollow2D

var is_waiting := false
var objs_na_area := []
var character_direction : Vector2
var char_last_pos: Vector2
var falas := []
var current_dialogue_id = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interact_icon.visible = false
	dialogue.visible = false
	char_last_pos = path_follow_2d.position
	sprite.sprite_frames = sprite_frames
	$PathFollow2D.loop = loop
	falas = GlobalData.Texts[npc_type][state_fala]
	name_text.text = npc_name
	
func talk():
	current_dialogue_id+=1
	if current_dialogue_id >= len(falas):
		dialogue_finished.emit()
		current_dialogue_id = -1
		dialogue.visible = false
		
		# save to global data
		var _current_enemy = GlobalData.get_current_enemy() # [current_enemy,enemy_original_position,enemy_can_move]
		# transition scene
		transition_node._set_animation(transition_node.Animations.SPOT_PLAYER, 0.7,"transition_in") #PIXELS, SPOT_PLAYER, SPOT_CENTER, VER_CUT, HOR_CUT
		await get_tree().create_timer(2).timeout
		
		if _current_enemy[0] != null:
			_current_enemy[0].position = _current_enemy[1]
			_current_enemy[0].can_move = _current_enemy[2]
		GlobalData.set_new_enemy($".",position,can_move)
		
		
		
		# teleport to nearest table
		can_move = false
		player.position = nearest_table.position + Vector2(-25,-30)
		position = nearest_table.position + Vector2(40,0)
		path_follow_2d.position = Vector2.ZERO
		
		sprite.animation = "walk_left"
		player.sprite.animation = "walk_down"
		
		transition_node._set_animation(transition_node.Animations.PIXELS, 0.7,"transition_out")		
		
		return
	text_text.text = falas[current_dialogue_id][GameSettings.lang[GameSettings.currentLanguage]]
	dialogue.visible = true	

func _input(event):
	if objs_na_area.count(player) > 0:
		if event.is_action_pressed("interact"):
			talk()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:		
	
	if objs_na_area.count(player) > 0:
		interact_icon.visible = true
		sprite.stop()
		if look_at_player:
			look_to($"../Player".position)
	else:
		interact_icon.visible = false
		dialogue.visible = false
		if can_move: move_enemy(delta)
		
	z_index = int(path_follow_2d.global_position.y)
	
func look_to(pos):
	var look_dir = ($".".to_local(pos) - path_follow_2d.position).normalized()
	if abs(look_dir.x) > abs(look_dir.y): # olhando para os lados
		if look_dir.x > 0: # olhando para a direita
			sprite.animation = "walk_right"
		elif look_dir.x < 0: # olhando para a esquerda
			sprite.animation = "walk_left"	
	elif abs(look_dir.x) < abs(look_dir.y): # olhando para cima/baixo
		if look_dir.y > 0: # olhando para baixo
			sprite.animation = "walk_down"
		elif look_dir.y < 0: # olhando para cima
			sprite.animation = "walk_up"	
			
func move_enemy(delta):
	path_follow_2d.progress_ratio += delta * speed	
	character_direction = (path_follow_2d.position - char_last_pos).normalized()
	if abs(character_direction.x) <= 0.05 && abs(character_direction.y) <= 0.05:
		# parado
		sprite.stop()
	elif character_direction.x < 0 && abs(character_direction.y) <= 0.05:
		sprite.animation = "walk_left"
	elif character_direction.x > 0 && abs(character_direction.y) <= 0.05: 
		sprite.animation = "walk_right"
	elif character_direction.y < 0: 
		sprite.animation = "walk_up"
	elif character_direction.y > 0: 
		sprite.animation = "walk_down"
	sprite.play()	
	char_last_pos = path_follow_2d.position

func _on_area_2d_body_entered(body: Node2D) -> void:
	#print(body.name, " entrou na area de ", name)
	objs_na_area.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	#print(body.name, " saiu da area de ", name)
	objs_na_area.erase(body)
