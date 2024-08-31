extends Node

@export var ball_scene : PackedScene
@onready var shapecast = $ShapeCast2D
var apply_max_force: bool = false
var force_first_player: bool = false
var ball_images := []
var cue_ball
const START_POS := Vector2(890,340)
const MAX_POWER := 40
const MOVE_THRESHOLD := 5.0
var taking_shot : bool
var cue_ball_potted : bool
var potted := []
var all_potted := []
var ball_radius = 18.0
var mesa_aberta : bool = true
var jogador_atual : int = 0 # 0 jogador, 1 bot
var grupo_jogador : int = 0 # 0 indefinido, 1 menores, 2 maiores
var grupo_maior := [9,10,11,12,13,14,15]
var grupo_menor := [1,2,3,4,5,6,7]
var foi_falta : bool = false
var primeira_bola_batida: int = 0
var moveram: bool = false
var derrubou_a_8_por_ultimo: bool = false
var buracos := []
var jogador_ja_tinha_grupo: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	hide_cue()
	all_potted = []
	randomize()  # Garante que a semente do gerador de números aleatórios seja diferente a cada execução
	if force_first_player: jogador_atual = 1
	else: jogador_atual = randi() % 2  # Retorna 0 ou 1 aleatoriamente
	for hole in $Mesa/buracos.get_children():
		buracos.append(hole)
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
	all_potted.append(bola)
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
			ball.continuous_cd = true
			add_child(ball)
		rows -= 1
		
func remove_cue_ball():
	var old_b = cue_ball
	shapecast.reparent($".")
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
	shapecast.reparent(cue_ball)

func _on_CueBall_area_entered(body):
	if body.is_in_group("bolas") && primeira_bola_batida == 0 && body.name != "Bola":
		primeira_bola_batida = body.name.to_int()
		
func get_better_ball():
	var permitted_balls := []
	var ball_nearest_to_hole = null
	var ball_nearest_to_hole_distance = INF
	var clear_shot_balls := []
	var best_collision_point = null
	var smallest_angle = INF
	for b in get_tree().get_nodes_in_group("bolas"):
		if b.name != "Bola":
			if is_ball_permitted(b.name.to_int()):
				var ball = [b.name.to_int(), b.position]
				permitted_balls.append(ball)
	for b in permitted_balls:
		for hole in buracos:	
			var hole_position = hole.to_global(hole.get_child(0).position)			
			var pocket_direction = (hole_position - b[1]).normalized()
			var contact_point = b[1] - pocket_direction * 2*ball_radius
			var white_to_ball = (contact_point - cue_ball.position).normalized()
			#var white_to_ball = (b[1] - cue_ball.position).normalized()
			# Calcule o ângulo entre os dois vetores
			var angle_radians = pocket_direction.angle_to(white_to_ball)
			# Converta para graus, se necessário
			var angle_degrees = rad_to_deg(angle_radians)
			#print("Ball: ", b[0], " Hole: ", hole.name, " Angle: ", angle_degrees)
			if check_clear_shot(b[0],contact_point): #&& abs(angle_degrees) > 90:
				clear_shot_balls.append(b)
				if abs(angle_degrees) < smallest_angle:
					$Line2D2.clear_points()
					$Line2D2.add_point(contact_point)
					$Line2D2.add_point(hole_position)
					$Line2D2.visible = true
					best_collision_point = contact_point
					ball_nearest_to_hole = b
					smallest_angle = abs(angle_degrees)
	return ([ball_nearest_to_hole,clear_shot_balls,best_collision_point])

func check_clear_shot(ball_number, contact_point: Vector2):
	# Defina a posição de origem do shapecast2D	
	shapecast.position = Vector2.ZERO
	# Calcule o vetor de direção e distância para o shapecast2d
	shapecast.target_position = shapecast.to_local(contact_point)
	# Habilite o RayCast2D para começar a detectar colisões
	shapecast.enabled = true
	shapecast.force_shapecast_update()	
	# Verifique se há uma colisão
	if shapecast.is_colliding():
		# Obtenha o objeto colidido
		var collider = shapecast.get_collider(0)
		# qual será a primeira colisão
		#print(shapecast.position,shapecast.target_position,collider.name)
		shapecast.enabled = false
		if collider.name == str(ball_number):
			return true
	else:
		shapecast.enabled = false
		return false
	
func get_nearest_hole(ball_position):
	var nearest_distance = INF
	var nearest_hole = null
	for hole in buracos:
		var distance = ball_position.distance_to(hole.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_hole = hole
	return [nearest_hole,nearest_distance]

func is_ball_permitted(ball):
	if all_potted.has(ball):
		return false
	if grupo_jogador == 0: #todas permitidas, menos 8
		if ball != 8:
			return true
	else:
		if jogador_atual == 0:
			if grupo_jogador == 1: # jogador com as menores
				if grupo_menor.size() > 0:
					if ball < 8:
						return true
				else:
					if ball == 8:
						return true
			if grupo_jogador == 2: # jogador com as maiores
				if grupo_maior.size() > 0:
					if ball > 8:
						return true
				else:
					if ball == 8:
						return true
		else:
			if grupo_jogador == 2: # jogador com as maiores, bot com as menores
				if grupo_menor.size() > 0:
					if ball < 8:
						return true
				else:
					if ball == 8:
						return true
			if grupo_jogador == 1: # jogador com as menores, bot com as maiores
				if grupo_maior.size() > 0:
					if ball > 8:
						return true
				else:
					if ball == 8:
						return true
	
func vez_bot():
	var better_ball = get_better_ball() # [ball_nearest_to_hole,clear_shot_balls,best_collision_point]
	print("Betterball: ",better_ball)
	if better_ball[2] != null:
		$Taco.position = cue_ball.position
		$Taco.show()
		var dir = better_ball[2] - cue_ball.position
		$Taco.look_at(better_ball[2])
		$Line2D.clear_points()
		$Line2D.add_point(cue_ball.position)
		$Line2D.add_point(better_ball[2])
		$Line2D.visible = true
		await get_tree().create_timer(5).timeout
		var power = MAX_POWER * dir.normalized() * $Taco.power_multiplier * 0.8
		cue_ball.apply_central_impulse(power)
		$Line2D.visible = false
		$Line2D2.visible = false
	else:
		# verifica as bolas permitidas
		var permitted_balls := []
		var ball_nearest_to_hole = null
		var ball_nearest_to_hole_distance = INF
		var clear_shot_balls := []
		var best_collision_point = null
		var smallest_angle = INF
		for b in get_tree().get_nodes_in_group("bolas"):
			if b.name != "Bola":
				if is_ball_permitted(b.name.to_int()):
					var ball = [b.name.to_int(), b.position]
					permitted_balls.append(ball)
					
		# calcular 4 posições projetadas da bola branca nas tabelas (vetores em 0, 90, 180 e 270 graus, com comprimento x2)
		
		
		for b in permitted_balls:
			# para cada bola permitida, cria vetor da bola até as 4 posições da bola branca projetada
			pass

func show_cue():
	$Taco.position = cue_ball.position
	$Taco.show()
	$PowerBar.show()
	$PowerBar.position.x = cue_ball.position.x - (0.5 * $PowerBar.size.x)
	$PowerBar.position.y = cue_ball.position.y + $PowerBar.size.y
	$Taco.set_process(true)	
	
func inicia_vez():
	if jogador_atual == 1:
		vez_bot()
	else:
		show_cue()
			
func hide_cue():
	$Taco.set_process(false)
	$Taco.hide()
	$PowerBar.hide()

func nova_tacada():
	if not jogador_ja_tinha_grupo and grupo_jogador != 0:
		jogador_ja_tinha_grupo = true
	if potted.size() == 0 || foi_falta:
		proximo_jogador()
	
	potted = []
	taking_shot = true
	inicia_vez()
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
				return
			if grupo_jogador != 0: foi_falta = true
			reset_cue_ball()
			cue_ball_potted = false
		else:
			if derrubou_a_8_por_ultimo:
				fim_de_partida(jogador_atual)
				return
		
		if moveram: # bolas pararam após a tacada
			print("Primeira bola ", primeira_bola_batida)
			if (primeira_bola_batida == 0 and grupo_jogador != 0) or (jogador_ja_tinha_grupo and primeira_bola_batida != 0 and bateu_primeiro_em_bola_proibida(primeira_bola_batida)):
				foi_falta = true
			
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
	if apply_max_force: 
		power = power.normalized() * MAX_POWER * $Taco.power_multiplier
		print("Power: ",power.length())
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
				return
			else:
				derrubou_a_8_por_ultimo = true
		elif grupo_jogador == 2: # o grupo do jogador são as maiores
			if grupo_maior.size() > 0: # jogador perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(1) # bot vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		else: # sem grupos definidos, jogador perde
			fim_de_partida(1) # bot vence
			return
	else: # vez do bot
		if grupo_jogador == 1: # o grupo do jogador são as menores, grupo do bot são as maiores
			if grupo_maior.size() > 0: # bot perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(0) # jogador vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		elif grupo_jogador == 2: # o grupo do jogador são as maiores, grupo do bot são as menores
			if grupo_menor.size() > 0: # bot perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(0) # jogador vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		else: # sem grupos definidos, bot perde
			fim_de_partida(0) # jogador vence
			return

func potted_ball(body):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	else:
		print(body.name)
		var bola = body.name.to_int()
		if bola == 8:
			bola_8_derrubada()
		if grupo_jogador == 0: # grupos indefinidos
			define_grupos(bola)		
		if bola>8: # grupo maiores
			grupo_maior.erase(bola)			
			print(grupo_maior)
		else: # grupo menores
			grupo_menor.erase(bola)
			print(grupo_menor)
		if bola_adversaria(bola):
			foi_falta = true
		potted.append(body)
		all_potted.append(bola)
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
	
