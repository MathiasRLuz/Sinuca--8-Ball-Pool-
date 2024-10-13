class_name Guard extends Path2D

signal dialogue_finished

@export var spritesheet : Texture2D
@export var loop := false
@export var speed := 0.1
@export var look_at_player := false
@export var npc_name: String
@export var npc_type : GlobalData.Npcs
@export var state_fala : GlobalData.Falas
@export var can_move := true
@export var nearest_table : Sprite2D
@export var kids_array : Array[Kid]
@onready var name_text: RichTextLabel = $PathFollow2D/StaticBody2D/Sprite2D/Dialogue/NinePatchRect/Name
@onready var text_text: RichTextLabel = $PathFollow2D/StaticBody2D/Sprite2D/Dialogue/NinePatchRect/Text
@onready var dialogue: Control = $PathFollow2D/StaticBody2D/Sprite2D/Dialogue
@onready var interact_icon: Control = $PathFollow2D/StaticBody2D/Sprite2D/InteractIcon
@onready var player = $"../../Player"
@onready var transition_node = $"../Transition"
@onready var sprite: Sprite2D = $PathFollow2D/StaticBody2D/Sprite2D
@onready var path_follow_2d: PathFollow2D = $PathFollow2D

@export var image_pre : Texture2D
@export var image_victory : Texture2D
@export var image_defeat : Texture2D
@export var icon : Texture2D

var objs_na_area := []
var falas := []
var current_dialogue_id = -1
var derrotado := false
var enfrentado := false
var pode_desafiar := true
var next_enemy_type: GlobalData.Npcs
var next_enemy_name: String
var next_enemy_image_pre : Texture2D
var next_enemy_image_victory : Texture2D
var next_enemy_image_defeat : Texture2D
var next_enemy_icon : Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_enemy_type = npc_type
	next_enemy_name = npc_name
	next_enemy_image_pre = image_pre
	next_enemy_image_victory = image_victory
	next_enemy_image_defeat = image_defeat
	next_enemy_icon = icon
	for kid in kids_array:
		if not GlobalData.defeated_enemies.count(kid.npc_name) > 0:
			next_enemy_name = kid.npc_name
			next_enemy_type = kid.npc_type
			next_enemy_image_pre = kid.image_pre
			next_enemy_image_victory = kid.image_victory
			next_enemy_image_defeat = kid.image_defeat
			next_enemy_icon = kid.icon
			break
	sprite.texture = spritesheet
	interact_icon.visible = false
	dialogue.visible = false
	$PathFollow2D.loop = loop
	falas = GlobalData.Texts[npc_type][state_fala]
	name_text.text = npc_name
	derrotado = GlobalData.defeated_enemies.count(npc_name) > 0		
	enfrentado = GlobalData.faced_enemies.count(npc_name) > 0
	if derrotado: 
		pode_desafiar = false
		for kid in kids_array:
			GlobalData.freed_kid(kid)
			kid.visible = false # devo teleportar elas para o lugar desejado
		$"../Jaula/Frente".frame_coords = Vector2(1,1)
		
	if GlobalData.current_enemy_name == npc_name:
		global_position = GlobalData.enemy_pos
		can_move = false
		sprite.frame_coords = Vector2(0,2) # down, up, left, right
		path_follow_2d.position = Vector2.ZERO
	
func talk():
	if derrotado:
		print("já fui derrotado")		
	elif enfrentado:
		print("Já fui enfrentado, mas ganhei")
		
	current_dialogue_id+=1
	if current_dialogue_id >= len(falas):
		dialogue_finished.emit()
		current_dialogue_id = -1
		dialogue.visible = false
		
		var _current_enemy = GlobalData.get_current_enemy() # [current_enemy,enemy_original_position,enemy_can_move,current_enemy_name,current_enemy_type]
		if not pode_desafiar: # voltar pra posição e rota normal
			return
		
		# save to global data
		
		print("Enfrentando ", next_enemy_name, " do tipo ", next_enemy_type)
		
		# transition scene
		transition_node._set_animation(transition_node.Animations.SPOT_PLAYER, 0.7,"transition_in") #PIXELS, SPOT_PLAYER, SPOT_CENTER, VER_CUT, HOR_CUT
		await get_tree().create_timer(2).timeout
		if _current_enemy[0] != null:
			_current_enemy[0].global_position = _current_enemy[1]
			_current_enemy[0].can_move = _current_enemy[2]
		GlobalData.set_new_enemy($".",global_position,can_move,next_enemy_name,next_enemy_type)
		GlobalData.set_battle_images(next_enemy_image_pre,next_enemy_image_victory,next_enemy_image_defeat,next_enemy_icon)
		# teleport to nearest table
		can_move = false
		player.global_position = nearest_table.global_position + Vector2(-25,-30)
		global_position = nearest_table.global_position + Vector2(40,0)
		path_follow_2d.global_position = Vector2.ZERO
		
		sprite.frame_coords = Vector2(0,2) # down, up, left, right
		player.sprite.animation = "walk_down"
		GlobalData.set_player_spawn(player.global_position,GlobalData.LookingDirection.DOWN)
		GlobalData.last_scene_before_battle = get_tree().current_scene.scene_file_path
		GlobalData.enemy_pos = global_position
		GlobalData.enemy_faced(next_enemy_name)
		get_tree().change_scene_to_file("res://scenes/sinuca.tscn")		
		return
		
	text_text.text = falas[current_dialogue_id][GameSettings.lang[GameSettings.currentLanguage]]
	dialogue.visible = true	

func _input(event):
	if objs_na_area.count(player) > 0:
		if event.is_action_pressed("interact"):
			talk()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:		
	
	if objs_na_area.count(player) > 0:
		interact_icon.visible = true
		if look_at_player:
			look_to(player.position)
	else:
		interact_icon.visible = false
		dialogue.visible = false
		
	z_index = int(path_follow_2d.global_position.y)
	
func look_to(pos):
	var look_dir = ($".".to_local(pos) - path_follow_2d.position).normalized()
	if abs(look_dir.x) > abs(look_dir.y): # olhando para os lados
		if look_dir.x > 0: # olhando para a direita
			sprite.frame_coords = Vector2(0,3) # down, up, left, right
		elif look_dir.x < 0: # olhando para a esquerda
			sprite.frame_coords = Vector2(0,2) # down, up, left, right
	elif abs(look_dir.x) < abs(look_dir.y): # olhando para cima/baixo
		if look_dir.y > 0: # olhando para baixo
			sprite.frame_coords = Vector2(0,0) # down, up, left, right
		elif look_dir.y < 0: # olhando para cima
			sprite.frame_coords = Vector2(0,1) # down, up, left, right
			
func _on_area_2d_body_entered(body: Node2D) -> void:
	#print(body.name, " entrou na area de ", name)
	objs_na_area.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	#print(body.name, " saiu da area de ", name)
	objs_na_area.erase(body)
