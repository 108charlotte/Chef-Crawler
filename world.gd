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

const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

enum Tile {
	Wall = 26, 
	Inside_Floor = 0, 
	Door = 45,  
	Textured_Dirt = 49, 
	Stone_Wall = 40
}

var level_num = 0
var map = []
var rooms = []
var level_size

@onready var tile_map = $TileMap/TileMapLayer
@onready var player = $Player

var player_tile
var score = 0

func _ready(): 
	randomize()
	build_level()

	# Place player at center of tilemap grid
	var map_center = level_size / 2
	var player_pos = tile_map.map_to_local(Vector2i(map_center)) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	player.position = player_pos

func build_level(): 
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	var screen_size = get_viewport_rect().size
	var tiles_x = ceil(screen_size.x / TILE_SIZE)
	var tiles_y = ceil(screen_size.y / TILE_SIZE)

	level_size = Vector2(tiles_x, tiles_y)
	
	print("Building map with size: ", level_size)

	for x in range(int(level_size.x)): 
		var row = []
		for y in range(int(level_size.y)): 
			row.append(Tile.Stone_Wall)
			tile_map.set_cell(Vector2i(x, y), Tile.Stone_Wall, Vector2i(0, 0))
		map.append(row)
	
	var free_regions = [Rect2(Vector2(2,2), level_size)]
	var num_rooms = LEVEL_ROOM_COUNTS[level_num]
	for i in range(num_rooms): 
		add_room(free_regions)
		if free_regions.is_empty(): 
			break
	
	connect_rooms()

func connect_rooms(): 
	var stone_graph = AStar2D.new()
	var point_id = 0
	for x in range(level_size.x): 
		for y in range(level_size.y): 
			if map[x][y] == Tile.Stone_Wall: 
				stone_graph.add_point(point_id, Vector2(x, y))
				
				if x > 0 && map[x-1][y] == Tile.Stone_Wall: 
					var left_point = stone_graph.get_closest_point(Vector2(x - 1, y))
					stone_graph.connect_points(point_id, left_point)
				
				if y > 0 && map[x][y-1] == Tile.Stone_Wall: 
					var above_point = stone_graph.get_closest_point(Vector2(x, y - 1))
					stone_graph.connect_points(point_id, above_point)
				
				point_id += 1
	
	var room_graph = AStar2D.new()
	point_id = 0
	for room in rooms: 
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector2(room_center.x, room_center.y))
		point_id += 1
	
	while !is_everything_connected(room_graph): 
		add_random_connection(stone_graph, room_graph)

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
	
	var closest_start_point = stone_graph.get_closest_point(start_position)
	var closest_end_point = stone_graph.get_closest_point(end_position)
	
	if closest_start_point == -1 or closest_end_point == -1:
		print("No closest point found for start or end position!")
		return
	
	var path = stone_graph.get_point_path(closest_start_point, closest_end_point)
	assert(path)
	
	set_tile(start_position.x, start_position.y, Tile.Door)
	set_tile(end_position.x, end_position.y, Tile.Door)
	
	for path_point in path: 
		set_tile(path_point.x, path_point.y, Tile.Textured_Dirt)
	
	room_graph.connect_points(start_room_id, end_room_id)

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
	
	for x in range(room.position.x + 1, room.end.x - 2): 
		options.append(Vector2(x, room.position.y))
		options.append(Vector2(x, room.end.y - 1))
		
	for y in range(room.position.y + 1, room.end.y - 2): 
		options.append(Vector2(room.position.x, y))
		options.append(Vector2(room.end.x - 1, y))
	
	return options[randi() % options.size()]
				
func add_room(free_regions): 
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
		set_tile(x, start_y, Tile.Stone_Wall)
		set_tile(x, start_y + size_y - 1, Tile.Stone_Wall)
	
	for y in range(start_y + 1, start_y + size_y - 1): 
		set_tile(start_x, y, Tile.Stone_Wall)
		set_tile(start_x + size_x - 1, y, Tile.Stone_Wall)

	for x in range(start_x + 1, start_x + size_x - 1):
		for y in range(start_y + 1, start_y + size_y - 1):
			set_tile(x, y, Tile.Inside_Floor)
			
			
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
		
func set_tile(x, y, id): 
	if x < 0 or x >= map.size():
		print("Invalid x: ", x)
		return
	if typeof(map[x]) != TYPE_ARRAY:
		print("map[", x, "] is not an array! Got: ", map[x])
		return
	if y < 0 or y >= map[x].size():
		print("Invalid y: ", y, " in map[", x, "]")
		return
	map[x][y] = id
	tile_map.set_cell(Vector2i(x, y), id, Vector2i(0,0))
