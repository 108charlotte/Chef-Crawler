extends Node2D

const TILE_SIZE = 16

const LEVEL_SIZES = [
	Vector2(30, 30), 
	Vector2(35, 35),
	Vector2(40, 40),  
	Vector2(45, 45),
	Vector2(50, 50)
]

const LEVEL_ROOM_COUNTS = [5, 7, 9, 12, 15]
const LEVEL_ENEMY_COUNTS = [5, 8, 12, 18, 26]

const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8
const PLAYER_START_HP = 5

const WALKABLE_TILES = [Tile.Path, Tile.Door, Tile.Floor, Tile.Open_Door]

enum Tile {
	Floor, 
	Top_Wall, 
	Left_Wall, 
	Right_Wall, 
	Bottom_Wall, 
	Left_Bottom_Corner, 
	Right_Bottom_Corner, 
	Left_Top_Corner, 
	Right_Top_Corner, 
	Stone_Wall, 
	Door, 
	Path, 
	Open_Door, 
	Ladder, 
	Crown, 
	Skull, 
	Goo, 
	Bone, 
	Cauldron, 
	Cobweb, 
	Egg, 
	Fish, 
	Apple, 
	Pear, 
	Meat, 
	Stick, 
	Carrot, 
	Ham, 
	Cheese, 
	Scroll, 
}

var EnemyScene := preload("res://enemy.tscn")
var DeadEnemyScene := preload("res://dead_enemy.tscn")

class Enemy extends RefCounted: 
	var sprite_node
	var tile
	var full_hp
	var hp
	var dead = false
	
	func _init(game, enemy_level, x, y, enemy_scene): 
		full_hp = 1 + enemy_level * 2
		hp = full_hp
		tile = Vector2(x, y)
		sprite_node = enemy_scene.instantiate()
		sprite_node.frame = enemy_level
		sprite_node.position = tile * TILE_SIZE
		game.add_child(sprite_node)
		sprite_node.play("default")
	
	func remove(dead_enemy_scene, game): 
		if not sprite_node or not sprite_node.is_inside_tree():
			return

		var dead_sprite = dead_enemy_scene.instantiate()
		dead_sprite.position = sprite_node.position
		sprite_node.get_parent().add_child(dead_sprite)

		sprite_node.queue_free()

		await game.get_tree().create_timer(1.0).timeout
		if dead_sprite and dead_sprite.is_inside_tree():
			dead_sprite.queue_free()
			sprite_node = null
	
	func take_damage(game, dmg): 
		if dead: 
			return
		hp = max(0, hp - dmg)
		sprite_node.get_node("HPBar").size.x = TILE_SIZE * hp / full_hp
		
		if hp == 0: 
			dead = true
			game.score += 10 * full_hp
	
	func act(game): 
		var my_point = game.enemy_pathfinding.get_closest_point(Vector2(tile.x, tile.y))
		var player_point = game.enemy_pathfinding.get_closest_point(Vector2(game.player_tile.x, game.player_tile.y))
		var path = game.enemy_pathfinding.get_point_path(my_point, player_point)
		if path && path.size() > 1: 
			var move_tile = Vector2(path[1].x, path[1].y)
		
			if move_tile == game.player_tile: 
				game.damage_player(1)
			else: 
				var blocked = false
				for enemy in game.enemies: 
					if enemy.tile == move_tile: 
						blocked = true
						break
				if !blocked: 
					tile = move_tile

var level_num = 0
var map = []
var rooms = []
var level_size
var enemies = []

@onready var tile_map = $TileMap
@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var level = get_node("../Stats/Level")
@onready var scoreElement = get_node("../Stats/Score")
@onready var game = get_node(".")
@onready var hpElement = get_node("../Stats/HP")

var player_tile
var score = 0
var enemy_pathfinding
var player_hp = PLAYER_START_HP

func _ready(): 
	level_num = 0
	score = 0
	
	randomize()
	build_level()

func _input(event): 
	if !event.is_pressed(): 
		return
	if event.is_action("Left"): 
		try_move(-1, 0)
	elif event.is_action("Right"): 
		try_move(1, 0)
	elif event.is_action("Up"): 
		try_move(0, -1)
	elif event.is_action("Down"): 
		try_move(0, 1)

func try_move(dx, dy): 
	var x = player_tile.x + dx
	var y = player_tile.y + dy
	var tile_type = Tile.Stone_Wall
	if x >= 0 && x < level_size.x && y >= 0 && y < level_size.y: 
		tile_type = map[x][y]
	
	if tile_type == Tile.Door: 
		set_tile(x, y, Tile.Open_Door)
	elif tile_type == Tile.Crown: 
		print("Victory! You found the crown!")
		show_victory_screen()
	elif tile_type == Tile.Ladder:
		player_tile = Vector2(x, y)
		level_num += 1
		score += 20
		if level_num < LEVEL_SIZES.size():
			build_level()
		else:
			score += 1000
	elif tile_type in WALKABLE_TILES and tile_type != Tile.Stone_Wall:
		var blocked = false
		for enemy in enemies: 
			if enemy.tile.x == x && enemy.tile.y == y: 
				enemy.take_damage(self, 1)
				if enemy.dead: 
					await enemy.remove(DeadEnemyScene, game)
					enemies.erase(enemy)
				blocked = true
				break
		if !blocked: 
			player_tile = Vector2(x, y)
	
	for enemy in enemies: 
		enemy.act(self)
		
	update_visuals()

func show_victory_screen(): 
	set_process_input(false)
	get_tree().change_scene_to_file("res://victory.tscn")

func build_level(): 
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	for enemy in enemies: 
		enemy.remove(DeadEnemyScene, game)
	enemies.clear()

	level_size = LEVEL_SIZES[level_num]
	
	print("Building map with size: ", level_size)

	for x in range(int(level_size.x)):
		var column = []
		for y in range(int(level_size.y)):
			column.append(Tile.Stone_Wall)
		map.append(column)
	
	for x in range(int(level_size.x)):
		for y in range(int(level_size.y)):
			set_tile(x, y, Tile.Stone_Wall)
	
	var free_regions = [Rect2(Vector2(2,2), level_size)]
	var num_rooms = LEVEL_ROOM_COUNTS[level_num]
	for i in range(num_rooms): 
		add_room(free_regions)
		if free_regions.is_empty(): 
			break
	
	connect_rooms()

	var start_room = rooms.front()
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	player_tile = Vector2(player_x, player_y)
	
	update_visuals()

	var graph = build_stone_graph()
	var start_id = tile_to_id(player_tile.x, player_tile.y)
	enemy_pathfinding = build_enemy_pathfinding_graph()
	
	var num_enemies = LEVEL_ENEMY_COUNTS[level_num]
	for i in range(num_enemies): 
		var room = rooms[1 + randi() % (rooms.size() - 1)]
		var x = int(room.position.x + 1 + randi() % int(room.size.x - 2))
		var y = int(room.position.y + 1 + randi() % int(room.size.y - 2))
	
		var blocked = false
		for enemy in enemies: 
			if enemy.tile.x  == x && enemy.tile.y == y: 
				blocked = true
				break
		
		if x >= 0 and x < map.size() and y >= 0 and y < map[x].size():
			if !blocked && map[x][y] in WALKABLE_TILES: 
				var enemy = Enemy.new(self, randi() % 2, x, y, EnemyScene)
				enemies.append(enemy)

	var reachable_room_set = {}

	for x in range(int(level_size.x)):
		for y in range(int(level_size.y)):
			var tile_id = tile_to_id(x, y)
			if graph.has_point(tile_id):
				var path = graph.get_point_path(start_id, tile_id)
				if path.size() > 0:
					for room in rooms:
						if room.has_point(Vector2(x, y)):
							reachable_room_set[room] = true

	var reachable_rooms = reachable_room_set.keys()

	if reachable_rooms.size() > 0:
		var end_room = reachable_rooms[randi() % reachable_rooms.size()]
		var ladder_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2)
		var ladder_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2)
		set_tile(ladder_x, ladder_y, Tile.Ladder)
		if level_num == LEVEL_SIZES.size() - 1:
			set_tile(ladder_x, ladder_y, Tile.Crown)
	else:
		print("🚨 No reachable rooms for ladder placement")

	level.text = "Level: " + str(level_num + 1)

func clear_path(tile): 
	var new_point = enemy_pathfinding.get_available_point_id()
	enemy_pathfinding.add_point(new_point, Vector2(tile.x, tile.y))
	var points_to_connect = []
	
	if tile.x > 0 && map[tile.x - 1][tile.y] in WALKABLE_TILES:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector2(tile.x - 1, tile.y)))
	if tile.y > 0 && map[tile.x][tile.y - 1] in WALKABLE_TILES: 
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector2(tile.x, tile.y - 1)))
	if tile.x < level_size.x - 1 && map[tile.x + 1][tile.y] in WALKABLE_TILES: 
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector2(tile.x + 1, tile.y)))
	if tile.y < level.size.y - 1 && map[tile.x][tile.y + 1] in WALKABLE_TILES: 
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector2(tile.x, tile.y + 1)))
	
	for point in points_to_connect: 
		enemy_pathfinding.connect_points(point, new_point) 

func update_visuals(): 
	player.position = player_tile * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	scoreElement.text = "Score: " + str(score)
	
	for enemy in enemies: 
		if enemy.sprite_node and enemy.sprite_node.is_inside_tree():
			enemy.sprite_node.position = enemy.tile * TILE_SIZE
	
	hpElement.text = "HP: " + str(player_hp)
	
func tile_to_id(x: int, y: int) -> int:
	return x + y * int(level_size.x)
	
func connect_rooms(): 
	var stone_graph = AStar2D.new()
	for x in range(int(level_size.x)): 
		for y in range(int(level_size.y)): 
			if map[x][y] in WALKABLE_TILES: 
				var id = tile_to_id(x, y)
				stone_graph.add_point(id, Vector2(x, y))
				
				if x > 0 && map[x-1][y] in WALKABLE_TILES: 
					var left_id = tile_to_id(x - 1, y)
					if stone_graph.has_point(left_id): 
						stone_graph.connect_points(id, left_id)

				if y > 0 && map[x][y-1] in WALKABLE_TILES: 
					var up_id = tile_to_id(x, y - 1)
					if stone_graph.has_point(up_id):
						stone_graph.connect_points(id, up_id)
	
	var room_graph = AStar2D.new()
	for i in range(rooms.size()): 
		var center = rooms[i].position + rooms[i].size / 2
		room_graph.add_point(i, center)

	var attempts = 0
	while not is_everything_connected(room_graph):
		add_random_connection(stone_graph, room_graph)
		attempts += 1
		if attempts > 100:
			print("❌ Failed to connect rooms after 100 attempts.")
			break

func is_everything_connected(graph): 
	var points = graph.get_point_ids()
	var start = points[points.size() - 1]
	for point in points: 
		var path = graph.get_point_path(start, point)
		if !path: 
			return false
	
	return true
	
func add_random_connection(stone_graph, room_graph): 
	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)
	
	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])
	
	# Place doors first so they show up in the graph
	set_tile(start_position.x, start_position.y, Tile.Door)
	set_tile(end_position.x, end_position.y, Tile.Door)

	# Rebuild the graph AFTER placing doors
	stone_graph = build_stone_graph()

	# Now convert positions to IDs using the updated graph
	var closest_start_point = tile_to_id(start_position.x, start_position.y)
	var closest_end_point = tile_to_id(end_position.x, end_position.y)
	
	if closest_start_point == -1 or closest_end_point == -1:
		print("No closest point found for start or end position!")
		return
	
	if not stone_graph.has_point(closest_start_point) or not stone_graph.has_point(closest_end_point):
		print("❌ Point not in stone_graph!")
		return
	
	var path = stone_graph.get_point_path(closest_start_point, closest_end_point)
	
	if path.is_empty():
		print("🚨 No path between points:")
		print("start_pos:", start_position, "→ point ID:", closest_start_point)
		print("end_pos:", end_position, "→ point ID:", closest_end_point)
		print("Tiles at start:", map[start_position.x][start_position.y])
		print("Tiles at end:", map[end_position.x][end_position.y])
		print("Is start in graph?", stone_graph.has_point(closest_start_point))
		print("Is end in graph?", stone_graph.has_point(closest_end_point))
		return

	assert(path)
	
	set_tile(start_position.x, start_position.y, Tile.Door)
	set_tile(end_position.x, end_position.y, Tile.Door)
	
	for path_point in path: 
		if map[path_point.x][path_point.y] == Tile.Door:
			print("✅ Path includes door at", path_point)
		else: 
			set_tile(path_point.x, path_point.y, Tile.Path)
	
	room_graph.connect_points(start_room_id, end_room_id)

func build_stone_graph() -> AStar2D:
	var graph = AStar2D.new()
	for x in range(int(level_size.x)): 
		for y in range(int(level_size.y)): 
			if map[x][y] in WALKABLE_TILES or map[x][y] == Tile.Stone_Wall: 
				var id = tile_to_id(x, y)
				graph.add_point(id, Vector2(x, y))

				if x > 0:
					var left_id = tile_to_id(x - 1, y)
					if graph.has_point(left_id): 
						graph.connect_points(id, left_id)

				if y > 0:
					var up_id = tile_to_id(x, y - 1)
					if graph.has_point(up_id):
						graph.connect_points(id, up_id)
	return graph

func get_least_connected_point(graph): 
	var point_ids = graph.get_point_ids()
	var least
	var tied_for_least = []
	
	for point in point_ids: 
		var count = graph.get_point_connections(point).size()
		if least == null or count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)
		
	return tied_for_least[randi() % tied_for_least.size()]

func get_nearest_unconnected_point(graph, target_point): 
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_point_ids()
	
	var nearest
	var tied_for_nearest = []
	
	for point in point_ids: 
		if point == target_point: 
			continue
		
		var path = graph.get_point_path(point, target_point)
		if path: 
			continue
		
		var dist = (graph.get_point_position(point) - target_position).length()
		if !nearest || dist < nearest: 
			nearest = dist
			tied_for_nearest = [point]
		elif dist == nearest: 
			tied_for_nearest.append(point)
		
	return tied_for_nearest[randi() % tied_for_nearest.size()]

func pick_random_door_location(room): 
	var options = []

	# Top and bottom walls
	for x in range(room.position.x + 1, room.end.x - 1):
		options.append(Vector2(x, room.position.y))  # Top
		options.append(Vector2(x, room.end.y - 1))   # Bottom

	# Left and right walls
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector2(room.position.x, y))       # Left
		options.append(Vector2(room.end.x - 1, y))         # Right

	if options.is_empty():
		print("🚨 No door options for room:", room)
		return room.position + room.size / 2  # fallback
	
	return options[randi() % options.size()]
				
func add_room(free_regions): 
	if free_regions.is_empty():
		print("❌ No free regions left! Aborting room generation.")
		return
	
	var region = free_regions[randi() % free_regions.size()]
	var size_x = MIN_ROOM_DIMENSION
	if region.size.x > MIN_ROOM_DIMENSION: 
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION)
	
	var size_y = MIN_ROOM_DIMENSION
	if region.size.y > MIN_ROOM_DIMENSION: 
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION)
		
	size_x = min(size_x, MAX_ROOM_DIMENSION)
	size_y = min(size_y, MAX_ROOM_DIMENSION)
	
	var start_x = region.position.x
	if region.size.x > size_x: 
		start_x += randi() % int(region.size.x - size_x)
	
	var start_y = region.position.y
	if region.size.y > size_y: 
		start_y += randi() % int(region.size.y - size_y)
		
	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	for x in range(start_x, start_x + size_x): 
		set_tile(x, start_y, Tile.Top_Wall)
		set_tile(x, start_y + size_y - 1, Tile.Bottom_Wall)
	
	for y in range(start_y + 1, start_y + size_y - 1): 
		set_tile(start_x, y, Tile.Left_Wall)
		set_tile(start_x + size_x - 1, y, Tile.Right_Wall)
	
	set_tile(start_x, start_y, Tile.Left_Top_Corner)
	set_tile(start_x + size_x - 1, start_y, Tile.Right_Top_Corner)
	set_tile(start_x, start_y + size_y - 1, Tile.Left_Bottom_Corner)
	set_tile(start_x + size_x - 1, start_y + size_y - 1, Tile.Right_Bottom_Corner)

	for x in range(start_x + 1, start_x + size_x - 1):
		for y in range(start_y + 1, start_y + size_y - 1):
			set_tile(x, y, Tile.Floor)
			
			
	cut_regions(free_regions, room)
	
func cut_regions(free_regions, region_to_remove): 
	var removal_queue = []
	var addition_queue = []
	
	for region in free_regions: 
		if region.intersects(region_to_remove): 
			removal_queue.append(region)
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
			if leftover_left >= MIN_ROOM_DIMENSION: 
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
				
			if leftover_right >= MIN_ROOM_DIMENSION: 
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
			
			if leftover_above >= MIN_ROOM_DIMENSION: 
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
				
			if leftover_below >= MIN_ROOM_DIMENSION: 
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y), Vector2(region.size.x, leftover_below)))
		
	for remove_region in removal_queue: 
		free_regions.erase(remove_region)
	
	for add_region in addition_queue: 
		free_regions.append(add_region)

func damage_player(dmg): 
	player_hp = max(0, player_hp - dmg)
	if player_hp == 0: 
		get_tree().change_scene_to_file("res://lose.tscn")

func build_enemy_pathfinding_graph() -> AStar2D:
	var graph = AStar2D.new()
	for x in range(int(level_size.x)): 
		for y in range(int(level_size.y)): 
			if map[x][y] in [Tile.Floor, Tile.Open_Door, Tile.Path]:
				var id = tile_to_id(x, y)
				graph.add_point(id, Vector2(x, y))

				if x > 0:
					var left_id = tile_to_id(x - 1, y)
					if graph.has_point(left_id): 
						graph.connect_points(id, left_id)

				if y > 0:
					var up_id = tile_to_id(x, y - 1)
					if graph.has_point(up_id):
						graph.connect_points(id, up_id)
	return graph
		
func set_tile(x, y, id):
	x = int(x)
	y = int(y)
	if x < 0 or x >= map.size() or typeof(map[x]) != TYPE_ARRAY or y < 0 or y >= map[x].size():
		print("Invalid map coordinate: (", x, ",", y, ")")
		return
	
	if id < 0 or id >= Tile.size():
		push_error("🚨 Invalid Tile ID: %s" % id)
		return

	map[x][y] = id
	var coords = Vector2i(x, y)

	tile_map.erase_cell(0, coords)
	tile_map.set_cell(0, coords, id, Vector2i(0,0))
	
	# Only try to update pathfinding if it's already initialized
	if id == Tile.Floor and enemy_pathfinding != null: 
		clear_path(Vector2(x, y))
