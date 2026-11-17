extends Node

## Manages global game state: score, energy, inventory, accessories, and game phase.

# --- Signals ---
signal score_changed(new_score: int)
signal energy_changed(new_energy: int)
signal item_collected(item_name: String)
signal game_over
signal accessory_equipped(accessory_name: String)

# --- Enums ---
enum GameState { MENU, MAP, TRAIN, BOSS, FINALE }

# --- Constants ---
const MAX_ENERGY: int = 100

# --- State ---
var score: int = 0
var energy: int = MAX_ENERGY
var collected_items: Dictionary = {}
var current_accessories: Array[String] = []
var game_state: GameState = GameState.MENU


# --- Public API ---

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func take_damage(amount: int) -> void:
	energy = maxi(energy - amount, 0)
	energy_changed.emit(energy)
	if energy <= 0:
		game_over.emit()


func heal(amount: int) -> void:
	energy = mini(energy + amount, MAX_ENERGY)
	energy_changed.emit(energy)


func collect_item(item_name: String) -> void:
	if collected_items.has(item_name):
		collected_items[item_name] += 1
	else:
		collected_items[item_name] = 1
	item_collected.emit(item_name)


func equip_accessory(accessory_name: String) -> void:
	if accessory_name not in current_accessories:
		current_accessories.append(accessory_name)
		accessory_equipped.emit(accessory_name)


func reset_game() -> void:
	score = 0
	energy = MAX_ENERGY
	collected_items.clear()
	current_accessories.clear()
	game_state = GameState.MENU
	score_changed.emit(score)
	energy_changed.emit(energy)
