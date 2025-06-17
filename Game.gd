extends Control

const TILE_SIZE = 32

const LEVEL_SIZES = [
	Vector2(30, 30), 
	Vector2(35, 35),
	Vector2(40, 40),  
	Vector2(45, 45),
	Vector2(50,50)
]

const LEVEL_ROOM_COUNTS = [5, 7, 9, 12, 15]

const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

enum Tile {
	Wall, 
	Door, 
	Floor, 
	Textured_Dirt = 49, 
	Stone_Wall = 40
}

var level_num = 0
var map = []
var rooms = []
var level_size

@onready var tile_map = $TileMap
@onready var player = $TileMap/TileMapLayer

var player_tile
var score = 0

func _ready(): 
	DisplayServer.window_set_size(Vector2(1280, 720))
	randomize()
	build_level()
	
func build_level(): 
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	level_size = LEVEL_SIZES[level_num]
	for x in range(level_size.x): 
		map.append([])
		for y in range(level_size.y): 
			map[x].append(Tile.Stone_Wall)
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
			print("Trying to place tile ID:", Tile.Textured_Dirt, "at:", x, y)
