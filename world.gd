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
@onready var player = $Tile0085

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
