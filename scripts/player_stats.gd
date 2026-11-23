class_name PlayerStats
extends Resource

## Shared progression foundation for all four Ascension paths.
enum Path {
	NONE,
	MARTIAL_ARTS,
	CULTIVATION,
	MAGIC,
	KNIGHTHOOD
}

@export_category("Identity")
@export var chosen_path: Path = Path.NONE
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100
@export var soul_points: int = 0

@export_category("Soul Tree")
@export var strength: int = 1
@export var wisdom: int = 1
@export var agility: int = 1
@export var speed: int = 1
@export var willpower: int = 1

@export_category("Martial Arts")
@export var body_soul_will_sync: float = 0.0
@export var martial_rank: int = 0

@export_category("Cultivation")
@export var qi: float = 0.0
@export var cultivation_realm: int = 0
@export var soul_grade: int = 0

@export_category("Magic")
@export var magic_circles: int = 0
@export var mana: float = 0.0
@export var maximum_mana: float = 25.0

@export_category("Knighthood")
@export var sword_skill: float = 0.0
@export var aura: float = 0.0
@export var knight_rank: int = 0

const BASE_MOVE_SPEED: float = 5.0
const SPEED_PER_POINT: float = 0.35

func get_move_speed() -> float:
	return BASE_MOVE_SPEED + float(maxi(speed - 1, 0)) * SPEED_PER_POINT

func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		soul_points += 1
		experience_to_next_level = 100 + (level - 1) * 35

func spend_soul_point(stat_name: String) -> bool:
	if soul_points <= 0:
		return false
	if not stat_name in ["strength", "wisdom", "agility", "speed", "willpower"]:
		return false
	set(stat_name, int(get(stat_name)) + 1)
	soul_points -= 1
	return true
