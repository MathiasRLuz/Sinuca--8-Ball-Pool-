extends Node

@export var ball_scene : PackedScene
@export var force_victory := false

@onready var shapecast = $ShapeCast2D
@onready var shapecast2: ShapeCast2D = $ShapeCast2D2
@onready var raycast: RayCast2D = $RayCast2D
@onready var raycast2: RayCast2D = $RayCast2D2


var ball_images := []
var cue_ball
const START_POS := Vector2(216,86.5)
@export var MAX_POWER := 40
const MOVE_THRESHOLD := 5.0
var taking_shot : bool
var cue_ball_potted : bool
var potted := []
var all_potted := []
var ball_radius = 5.6
var mesa_aberta : bool = true

var jogador_atual : int = 0 # 0 jogador, 1 bot
var apply_max_force: bool = false
var force_first_player: int = 1 # -1 random, 0 bot, 1 jogador
var grupo_jogador : int = 0 # indefinido, 1 menores, 2 maiores

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
	if force_first_player!=-1: jogador_atual = force_first_player
	else: jogador_atual = randi() % 2  # Retorna 0 ou 1 aleatoriamente
	for hole in $Mesa/buracos.get_children():
		buracos.append(hole)
	#load_images()
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
			b_sprite.hframes = b.get_node("Sprite2D").hframes
			b_sprite.vframes = b.get_node("Sprite2D").vframes
			b_sprite.frame = b.get_node("Sprite2D").frame
			b_sprite.scale = b.get_node("Sprite2D").scale
			b_sprite.position = potted_ball_position()
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
		GlobalData.enemy_defeated(GlobalData.current_enemy_name)
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
	var diameter = 2 * ball_radius
	var ball_positions = []
	var ball8_pos : Vector2
	var ball15_pos : Vector2
	for col in range(5):
		for row in range(rows):			
			var pos = Vector2(50 + (col * diameter) - (col * 2), START_POS.y - 4 * ball_radius + (row * diameter) + (float(col * diameter) / 2.0))
			count += 1
			if count == 11:
				ball8_pos = pos
			else:
				ball_positions.append(pos)
		rows -= 1
	count = 0
	ball_positions.shuffle()	
	for i in range(15):
		var ball = ball_scene.instantiate()		
		#ball.get_node("Sprite2D").texture = ball_images[count]
		ball.get_node("Sprite2D").frame = i+1
		if count == 7:
			ball.position = ball8_pos
			ball15_pos = ball_positions[i]
		elif i<14:
			ball.position = ball_positions[i]
		else:
			ball.position = ball15_pos
		count += 1
		ball.name = str(count)
		ball.continuous_cd = true
		add_child(ball)	
		
func remove_cue_ball():
	var old_b = cue_ball
	shapecast.reparent($".")
	remove_child(old_b)
	old_b.queue_free()
	
func reset_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball)
	cue_ball.position = START_POS
	cue_ball.get_node("Sprite2D").frame = 0
	#cue_ball.get_node("Sprite2D").texture = ball_images.back() # última imagem do array
	taking_shot = false
	cue_ball.set_contact_monitor(true)
	cue_ball.max_contacts_reported = 256
	cue_ball.connect("body_entered", Callable(self, "_on_CueBall_area_entered"))
	cue_ball.continuous_cd = true  # Ativa o CCD
	shapecast.reparent(cue_ball)

func _on_CueBall_area_entered(body):
	if body.is_in_group("bolas") && primeira_bola_batida == 0 && body.name != "Bola":
		primeira_bola_batida = body.name.to_int()
		
func get_better_ball():
	var permitted_balls := []
	var best_ball = null
	var best_score = -INF
	var best_collision_point = null	
	var best_hole_position = Vector2.ZERO
	var direct_shot := false
	for b in get_tree().get_nodes_in_group("bolas"):
		if b.name != "Bola":
			if is_ball_permitted(b.name.to_int()):
				var ball = b
				permitted_balls.append(ball)
	
	for b in permitted_balls: 
		for hole in buracos:
			var hole_position = hole.to_global(hole.get_child(0).position)
			var pocket_direction = (hole_position - b.position).normalized()
			var contact_point = b.position - pocket_direction * 2* ball_radius
			var white_to_ball = (contact_point - cue_ball.position).normalized()
			
			var angle_radians = pocket_direction.angle_to(white_to_ball)
			var angle_degrees = rad_to_deg(angle_radians)
			if check_clear_shot(b.name,contact_point):	
				var score = 0
				
				# Critério 1: Ângulo (quanto menor, melhor)
				score += (180 - abs(angle_degrees)) * 2  # Multiplicador de 2 para dar mais peso
				
				# Critério 2: Distância da bola branca até a bola alvo (quanto menor, melhor)
				var distance_to_ball = cue_ball.position.distance_to(b.position)
				score += (1 / distance_to_ball) * 100  # Inverso da distância multiplicado para dar peso
				
				# Critério 3: Distância da bola alvo até a caçapa (quanto menor, melhor)
				var distance_to_hole = b.position.distance_to(hole_position)
				score += (1 / distance_to_hole) * 100 * 2
				
				# Critério 4: Interferências (penalizar se houver outras bolas no caminho)
				var clear_path = check_clear_path(b, hole)
				if not clear_path[0]:
					var penalidade = 250 * clear_path[1]
					print("Penalidade colisões: ", penalidade)
					score -= penalidade  # Penalidade se houver interferência
				print(b.name," - ",hole.name," - ",score)
				# Avaliar se esta jogada é melhor que as anteriores
				if score > best_score:
					best_score = score
					best_ball = b
					best_collision_point = contact_point
					best_hole_position = hole_position
					# linha vermelha
					$Line2D2.clear_points()
					$Line2D2.add_point(contact_point)
					$Line2D2.add_point(hole_position)
					$Line2D2.visible = true
					direct_shot = true
	
	if best_ball == null:
		var best_contact_point = Vector2.ZERO
		var possible_points := []
		
		# nenhum tiro direto
		# calcular 4 posições projetadas da bola branca nas tabelas (vetores em 0, 90, 180 e 270 graus, com comprimento x2)
		var cue_ball_projections = calculate_cue_ball_projections()
		var cue_ball_position = cue_ball.position
		var debug = false
		for b in permitted_balls:
			if debug: print("Bola: ", b.name)
			# para cada bola permitida, cria vetor do ponto de mira da bola em cada buraco até as 4 posições da bola branca projetada
			for projected_cue_ball in cue_ball_projections:
				for hole in buracos:	
					if debug: print("Buraco: ", hole.name)
					var hole_position = hole.to_global(hole.get_child(0).position)			
					var pocket_direction = (hole_position - b.position).normalized()
					var contact_point = b.position - pocket_direction * 2* ball_radius
					var direction = projected_cue_ball - contact_point	
					raycast.target_position = direction * 10000  # Lança o raycast numa grande distância
					raycast.global_position = contact_point # Posição do RayCast2D na bola
					raycast.force_raycast_update()
					if raycast.is_colliding():
						# Obtenha o ponto de tabela
						var collision_point = raycast.get_collision_point()
						
						# corrigir best_collision_point
						# descobrir em qual parede está tabelando
						if collision_point.x>1120: # direita
							collision_point -= Vector2(ball_radius,0)
							if debug: print("Tabelando na direita ", collision_point)							
						elif collision_point.x<80: # esquerda
							collision_point += Vector2(ball_radius,0)							
							if debug: print("Tabelando na esquerda ", collision_point)							
						elif collision_point.y>595: # baixo
							collision_point -= Vector2(0,ball_radius)
							if debug: print("Tabelando em baixo ", collision_point)							
						elif collision_point.y<80: # cima
							collision_point += Vector2(0,ball_radius)
							if debug: print("Tabelando em cima ", collision_point)							
						
						if check_clear_shot("paredes",collision_point):
							if debug: print("Caminho livre até o ponto de tabela")
							# se a bola branca tem caminho direto até o ponto de tabela
							cue_ball.position = collision_point
							
							if check_clear_shot(b.name,contact_point):	
								
								# linha vermelha
								$Line2D2.clear_points()
								$Line2D2.add_point(contact_point)
								$Line2D2.add_point(hole_position)
								$Line2D2.visible = true
								# linha roxa
								$Line2D3.clear_points()
								$Line2D3.add_point(collision_point)
								$Line2D3.add_point(contact_point)
								$Line2D3.visible = true	
								await get_tree().create_timer(1).timeout
								
								var tabela_to_ball = (contact_point - collision_point).normalized()
								
								var angle_radians = pocket_direction.angle_to(tabela_to_ball)
								var angle_degrees = rad_to_deg(angle_radians)
								if debug: print("Angle: ", angle_degrees)
								var score = 0
								
								# Critério 1: Ângulo (quanto menor, melhor)
								score += (180 - abs(angle_degrees)) * 2  # Multiplicador de 2 para dar mais peso
								
								# Critério 2: Distância da bola branca até a bola alvo (quanto menor, melhor)
								var distance_to_ball = cue_ball.position.distance_to(collision_point) + collision_point.distance_to(b.position)
								score += (1 / distance_to_ball) * 100  # Inverso da distância multiplicado para dar peso
								
								# Critério 3: Distância da bola alvo até a caçapa (quanto menor, melhor)
								var distance_to_hole = b.position.distance_to(hole_position)
								score += (1 / distance_to_hole) * 100 * 2
								
								# Critério 4: Interferências (penalizar se houver outras bolas no caminho)
								var clear_path = check_clear_path(b, hole)
								if not clear_path[0]:
									var penalidade = 250 * clear_path[1]
									if debug: print("Penalidade colisões: ", penalidade)
									score -= penalidade  # Penalidade se houver interferência
								if debug: print(b.name," - ",hole.name," - ",score)
								# Avaliar se esta jogada é melhor que as anteriores
								if score > best_score:
									best_score = score
									best_ball = b
									best_collision_point = collision_point
									best_hole_position = hole_position
									best_contact_point = contact_point
		if best_ball != null and not direct_shot:
			print("Tabelando no ponto de contato")
			# linha vermelha
			$Line2D2.clear_points()
			$Line2D2.add_point(best_contact_point)
			$Line2D2.add_point(best_hole_position)
			$Line2D2.visible = true
			# linha roxa
			$Line2D3.clear_points()
			$Line2D3.add_point(best_collision_point)
			$Line2D3.add_point(best_contact_point)
			$Line2D3.visible = true
		else:
				# mirar apenas para acertar uma bola do grupo
				for b in permitted_balls:
						if check_clear_shot(b.name,b.position,false):
							possible_points.append(b.position)
				if possible_points.size() > 0:
					print("Mirando para acertar uma bola permitida")
					best_collision_point = possible_points.pick_random()
				else:
					# mirar na tabela apenas para acertar uma bola do grupo
					for b in permitted_balls:
						print("Bola: ", b.name)
						# para cada bola permitida, cria vetor do ponto de mira da bola em cada buraco até as 4 posições da bola branca projetada
						for projected_cue_ball in cue_ball_projections:
							var direction = projected_cue_ball - b.position	
							raycast.target_position = direction * 10000  # Lança o raycast numa grande distância
							raycast.global_position = b.position # Posição do RayCast2D na bola
							raycast.force_raycast_update()
							if raycast.is_colliding():
								# Obtenha o ponto de tabela
								var collision_point = raycast.get_collision_point()
								
								# corrigir best_collision_point
								# descobrir em qual parede está tabelando
								if collision_point.x>1120: # direita
									collision_point -= Vector2(ball_radius,0)
									print("Tabelando na direita ", collision_point)							
								elif collision_point.x<80: # esquerda
									collision_point += Vector2(ball_radius,0)							
									print("Tabelando na esquerda ", collision_point)							
								elif collision_point.y>595: # baixo
									collision_point -= Vector2(0,ball_radius)
									print("Tabelando em baixo ", collision_point)							
								elif collision_point.y<80: # cima
									collision_point += Vector2(0,ball_radius)
									print("Tabelando em cima ", collision_point)							
								
								if check_clear_shot("paredes",collision_point):
									print("Caminho livre até o ponto de tabela")
									# se a bola branca tem caminho direto até o ponto de tabela
									cue_ball.position = collision_point
									possible_points.append(collision_point)					
					print("Bot não sabe onde mirar")
					if possible_points.size() > 0:
						best_collision_point = possible_points.pick_random()
					else:
						print("mirou em qualquer parede")
						var parede = randi() % 4
						var rng = RandomNumberGenerator.new()
						match parede:
							0: #cima							
								best_collision_point = Vector2(rng.randf_range(80, 1120),80)
							1: #baixo
								best_collision_point = Vector2(rng.randf_range(80, 1120),595)
							2: #direita
								best_collision_point = Vector2(1120,rng.randf_range(80, 595))
							3: #esquerda
								best_collision_point = Vector2(80,rng.randf_range(80, 595))
		cue_ball.position = cue_ball_position
		
			
	return [best_ball, best_hole_position,best_collision_point,best_score,direct_shot]

func calculate_cue_ball_projections():
	var ball_positions = []
	var directions = [
		Vector2(1, 0),   # 0° - Direita
		Vector2(0, -1),  # 90° - Cima
		Vector2(-1, 0),  # 180° - Esquerda
		Vector2(0, 1)    # 270° - Baixo
	]
	raycast2.enabled = true
	for direction in directions:
		raycast2.target_position = direction * 10000  # Lança o raycast numa grande distância
		raycast2.global_position = cue_ball.global_position  # Posição do RayCast2D na bola branca
		
		raycast2.force_raycast_update()
		if raycast2.is_colliding():
			var collision_point = raycast2.get_collision_point()
			var distance = cue_ball.global_position.distance_to(collision_point)
			var projected_position = cue_ball.position + direction * distance * 2
			ball_positions.append(projected_position)

	raycast2.enabled = false
	print("Projections: ", ball_positions)
	return ball_positions

func calculate_shot_power(ball, hole_position, contact_point):
	var distance_white_to_ball = cue_ball.position.distance_to(contact_point)
	var distance_ball_to_hole = contact_point.distance_to(hole_position)
	
	# Configurações de física da mesa
	var friction_coefficient = 0.05  # Depende do material da mesa
	var mass_of_ball = ball.mass  # Massa típica de uma bola de sinuca (em kg)
	
	# Calcular a força necessária baseada na distância
	var power = distance_white_to_ball + distance_ball_to_hole
	
	# Ajustar a força com base no coeficiente de atrito
	power *= (1 + friction_coefficient)
	
	# Ajustar a força com base no ângulo
	var shot_direction = (contact_point - cue_ball.position).normalized()
	var pocket_direction = (hole_position - contact_point).normalized()
	var angle_radians = shot_direction.angle_to(pocket_direction)
	var angle_factor = 1.0 + 0.5 * abs(angle_radians / PI)
	
	power *= angle_factor
	
	# Ajuste final de força baseado na massa e nas configurações do jogo
	# Multiplicar por um fator para ajustar para o comportamento desejado
	var final_power = power * mass_of_ball   # O multiplicador depende da escala do seu jogo
	return final_power

func check_clear_path(ball,pocket):
	shapecast2.reparent(ball)
	var pocket_position = pocket.to_global(pocket.get_child(0).position)	
	# Defina a posição de origem do shapecast2D	
	shapecast2.position = Vector2.ZERO
	# Calcule o vetor de direção e distância para o shapecast2d
	shapecast2.target_position = shapecast2.to_local(pocket_position)
	# Habilite o ShapeCast2D para começar a detectar colisões
	shapecast2.enabled = true
	shapecast2.force_shapecast_update()	
	# Verifique se há uma colisão
	if shapecast2.is_colliding():
		# Obtenha o objeto colidido
		var collisions = shapecast2.get_collision_count()		
		var collider = shapecast2.get_collider(0)
		var nome = collider.name
		if nome == "Area2D": nome = collider.get_parent().name
		print(ball.name, " colisões: ", collisions, " - primeira colisão: ", nome)
		# qual será a primeira colisão
		shapecast2.enabled = false
		shapecast2.reparent($".")
		if nome == "buracos":
			return [true,collisions]
		else: return [false,collisions]
	else:
		shapecast2.enabled = false
		shapecast2.reparent($".")
		return [false,0]

func check_clear_shot(ball_name, contact_point: Vector2, check_distance: bool = true):
	var tolerancia = 0.05 # porcentagem de distancia (entre o ponto de colisão real e o contact_point calculado) excedente ao raio da bola
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
		# qual será o ponto da primeira colisão
		var colision_point = shapecast.get_collision_point(0)
		var distancia = colision_point.distance_to(contact_point) # distancia entre o ponto de colisão real e o contact_point calculado
		shapecast.enabled = false	
		if (not check_distance and collider.name == ball_name) or (check_distance and distancia<=ball_radius*(1+tolerancia) and collider.name == ball_name):
			print("Has clear shot on ", ball_name, ", colliding in ", colision_point)
			return true
		else: 
			print(ball_name, " primeira colisão: ", collider.name, " Distancia: ", distancia)
			return false
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
	print("INICIO VEZ BOT")
	var better_ball = await get_better_ball() # ([best_ball, best_hole_position,best_collision_point,best_score,direct_shot])
	
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
		
		# Camera lenta na tabela
		#if better_ball[4]: Engine.set_time_scale(1)
		#else: Engine.set_time_scale(0.1)
		
		var power = MAX_POWER * dir.normalized() * $Taco.power_multiplier 
		# se tiro direto calcula a força, senão usa força maxima nas tabelas
		if better_ball[4]: power *= calculate_shot_power(better_ball[0],better_ball[1],better_ball[2])/200 
		print("POWER > ", power.length())
		cue_ball.apply_central_impulse(power)		
		$Line2D.visible = false
		$Line2D2.visible = false
		$Line2D3.visible = false
	else:		
		print("Não sei oq fazer")		
	print("FIM VEZ BOT")

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
	
func _input(event):
	if event.is_action_pressed("interact"):	
		if force_victory: GlobalData.enemy_defeated(GlobalData.current_enemy_name) # força vitória do jogador
		get_tree().change_scene_to_file(GlobalData.last_scene_before_battle)

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
	# definir força manualmente
	#power = 80 *power.normalized() 
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
		if body.get_node("Sprite2D"):
			b_sprite.texture = body.get_node("Sprite2D").texture
			b_sprite.hframes = body.get_node("Sprite2D").hframes
			b_sprite.vframes = body.get_node("Sprite2D").vframes
			b_sprite.frame = body.get_node("Sprite2D").frame
			b_sprite.scale = body.get_node("Sprite2D").scale
			b_sprite.position = potted_ball_position()
		body.queue_free()

func potted_ball_position():
	return Vector2(180 + 15 * (14-grupo_maior.size()-grupo_menor.size()),200)
	
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
