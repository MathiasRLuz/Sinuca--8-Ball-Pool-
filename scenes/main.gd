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

var mesa_aberta : bool = true
var jogador_atual : int = 0 # 0 jogador, 1 bot
var grupo_jogador : int = 0 # 0 indefinido, 1 menores, 2 maiores
var grupo_maior := [9,10,11,12,13,14,15]
var grupo_menor := [1,2,3,4,5,6,7]
var foi_falta : bool = false
var primeira_bola_batida: int = 0
var moveram: bool = false
var derrubou_a_8_por_ultimo: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()  # Garante que a semente do gerador de números aleatórios seja diferente a cada execução
	jogador_atual = randi() % 2  # Retorna 0 ou 1 aleatoriamente
	load_images()
	new_game()
	$Mesa/buracos.body_entered.connect(potted_ball)

func proximo_jogador():
	jogador_atual = 1 - jogador_atual
	print("Jogador atual: ", jogador_atual)
	$jogador_atual.text = str(jogador_atual)
	ajusta_texto_grupo()
	
func ajusta_texto_grupo():
	var grupo_texto = "indefinido"
	if jogador_atual == 0:
		if grupo_jogador == 1:
			grupo_texto = "menores"
		elif grupo_jogador == 2: 
			grupo_texto = "maiores"
	if jogador_atual == 1:
		if grupo_jogador == 2:
			grupo_texto = "menores"
		elif grupo_jogador == 1: 
			grupo_texto = "maiores"
	$grupo_atual.text = grupo_texto
	
func remove_bola(bola):	
	print("Remover bola " + str(bola))
	if bola>8:
		grupo_maior.erase(bola)
		print(grupo_maior)
	else:
		grupo_menor.erase(bola)
		print(grupo_menor)
	for b in get_tree().get_nodes_in_group("bolas"):
		if b.name == str(bola):
			var b_sprite = Sprite2D.new()
			add_child(b_sprite)
			b_sprite.texture = b.get_node("Sprite2D").texture
			b_sprite.position = Vector2(180 + 50 * (14-grupo_maior.size()-grupo_menor.size()),725)
			b.queue_free()

func falta(grupo_favorecido):
	if grupo_favorecido == 1:
		if grupo_menor.size() < 1:
			# grupo menor vence
			if grupo_jogador == 1: fim_de_partida(0)
			else: fim_de_partida(1)
		else:
			remove_bola(grupo_menor[0])
	else:	
		if grupo_maior.size() < 1:
			# grupo maior vence
			if grupo_jogador == 2: fim_de_partida(0)
			else: fim_de_partida(1)
		else:
			remove_bola(grupo_maior[0])	

func fim_de_partida(jogador_vencedor): # 0 jogador, 1 bot
	if jogador_vencedor == 0:
		print("Parabens, você venceu")
		$"Fim de jogo".text = "Jogador 0 venceu"
	else:
		print("Você perdeu")
		$"Fim de jogo".text = "Jogador 1 venceu"
	set_process(false)


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
			ball.name = str(count)
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
	cue_ball.get_node("Area2D").connect("body_entered", Callable(self, "_on_CueBall_area_entered"))
	cue_ball.continuous_cd = true  # Ativa o CCD

func _on_CueBall_area_entered(body):
	if body.is_in_group("bolas") && primeira_bola_batida == 0 && body.name != "Bola":
		primeira_bola_batida = body.name.to_int()
	
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

func nova_tacada():
	if potted.size() == 0 || foi_falta:
		proximo_jogador()
	
	potted = []
	taking_shot = true
	show_cue()
	primeira_bola_batida = 0
	foi_falta = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var moving := false
	for b in get_tree().get_nodes_in_group("bolas"):
		if (b.linear_velocity.length() > 0.0 and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
			
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
			moveram = true
			
	if not moving:
		
		# check if the cue ball has been potted and reset it
		if cue_ball_potted:
			if derrubou_a_8_por_ultimo: # a branca caiu depois de ter derrubado a 8
				fim_de_partida(1-jogador_atual)
			if grupo_jogador != 0: foi_falta = true
			reset_cue_ball()
			cue_ball_potted = false
		else:
			if derrubou_a_8_por_ultimo:
				fim_de_partida(jogador_atual)
		
		if moveram: # bolas pararam após a tacada			
			if bateu_primeiro_em_bola_proibida(primeira_bola_batida):
				if grupo_jogador != 0: foi_falta = true
			
		if not taking_shot:			
			if foi_falta:
				print("Foi falta")
				verifica_favorecido_por_falta()
			nova_tacada()
		
		moveram = false	
	else:
		if taking_shot:
			taking_shot = false
			hide_cue()

func verifica_favorecido_por_falta():
	if jogador_atual == 0: 
		# jogador fez falta
		if (grupo_jogador == 1): #jogador no grupo das menores
			falta(2)		
		elif (grupo_jogador == 2): #jogador no grupo das maiores
			falta(1)
	else: 
		#bot fez falta
		if (grupo_jogador == 1): #jogador no grupo das menores
			falta(1)		
		elif (grupo_jogador == 2): #jogador no grupo das maiores
			falta(2)

func _on_taco_shoot(power):
	cue_ball.apply_central_impulse(power)

func define_grupos(bola):
	if bola>8:
		if jogador_atual == 0:
			grupo_jogador = 2
		else:
			grupo_jogador = 1
	else:
		if jogador_atual == 0:
			grupo_jogador = 1
		else:
			grupo_jogador = 2
	print("Grupo do jogador: " + str(grupo_jogador))
	ajusta_texto_grupo()

func bola_8_derrubada():	
	if jogador_atual == 0: # vez do player
		if grupo_jogador == 1: # o grupo do jogador são as menores
			if grupo_menor.size() > 0: # jogador perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(1) # bot vence
			else:
				derrubou_a_8_por_ultimo = true
		elif grupo_jogador == 2: # o grupo do jogador são as maiores
			if grupo_maior.size() > 0: # jogador perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(1) # bot vence
			else:
				derrubou_a_8_por_ultimo = true
	else: # vez do bot
		if grupo_jogador == 1: # o grupo do jogador são as menores, grupo do bot são as maiores
			if grupo_maior.size() > 0: # bot perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(0) # jogador vence
			else:
				derrubou_a_8_por_ultimo = true
		elif grupo_jogador == 2: # o grupo do jogador são as maiores, grupo do bot são as menores
			if grupo_menor.size() > 0: # bot perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(0) # jogador vence
			else:
				derrubou_a_8_por_ultimo = true

func potted_ball(body):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	else:
		print(body.name)
		var bola = body.name.to_int()
		if grupo_jogador == 0: # grupos indefinidos
			if bola == 8:
				return
			else:
				define_grupos(bola)
		if bola == 8:
			bola_8_derrubada()
		elif bola>8: # grupo maiores
			grupo_maior.erase(bola)			
			print(grupo_maior)
		else: # grupo menores
			grupo_menor.erase(bola)
			print(grupo_menor)
		if bola_adversaria(bola):
			foi_falta = true
		potted.append(body)
		var b_sprite = Sprite2D.new()
		add_child(b_sprite)
		b_sprite.texture = body.get_node("Sprite2D").texture
		b_sprite.position = Vector2(180 + 50 * (14-grupo_maior.size()-grupo_menor.size()),725)
		body.queue_free()

func bateu_primeiro_em_bola_proibida(bola):
	if bola == 8:
		if jogador_atual == 0:
			# vez do jogador
			if grupo_jogador == 1:
				if grupo_menor.size() == 0:
					# só resta a 8 para o jogador
					return false
			if grupo_jogador == 2:
				if grupo_maior.size() == 0:
					# só resta a 8 para o jogador
					return false
		else:
			# vez do bot
			if grupo_jogador == 2:
				if grupo_menor.size() == 0:
					# só resta a 8 para o jogador
					return false
			if grupo_jogador == 1:
				if grupo_maior.size() == 0:
					# só resta a 8 para o jogador
					return false
	if bola == 0: #não bateu em nenhuma
		return true
		
	if bola_adversaria(bola):
		return true
	else:
		return false

func bola_adversaria(bola):
	if jogador_atual == 0: 
		# jogador fez tacada
		if (grupo_jogador == 1): #jogador no grupo das menores
			if bola < 8: return false
			else: return true
		elif (grupo_jogador == 2): #jogador no grupo das maiores
			if bola > 8: return false
			else: return true
	else: 
		#bot fez tacada
		if (grupo_jogador == 1): #jogador no grupo das menores, bot no grupo das maiores
			if bola > 8: return false
			else: return true	
		elif (grupo_jogador == 2): #jogador no grupo das maiores, bot no grupo das menores
			if bola < 8: return false
			else: return true
	
