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

	for x in range(level_size.x): 
		map.append([])
		for y in range(level_size.y): 
			map[x].append(Tile.Textured_Dirt)
			tile_map.set_cell(Vector2i(x, y), Tile.Textured_Dirt, Vector2i(0, 0))
	
	var free_regions = [Rect2(Vector2(2,2), level_size)]
	var num_rooms = LEVEL_ROOM_COUNTS[level_num]
	for i in range(num_rooms): 
		add_room(free_regions)
		if free_regions.is_empty(): 
			break

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
			set_tile(x, y, Tile.Door)
			
			
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
	map[x][y] = id
	tile_map.set_cell(Vector2i(x, y), id, Vector2i(0,0))
