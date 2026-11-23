class_name PlayerStats
extends Resource

## Shared progression foundation for all four Ascension paths.
signal path_selected(path: Path)
signal stat_changed(stat_name: String, new_value: int)
signal soul_points_changed(new_value: int)
signal skill_changed(skill_id: String, unlocked: bool)

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

var unlocked_skills: Dictionary = {}

func get_move_speed() -> float:
	return BASE_MOVE_SPEED + float(maxi(speed - 1, 0)) * SPEED_PER_POINT

func choose_path(new_path: Path) -> bool:
	if chosen_path != Path.NONE or new_path == Path.NONE:
		return false
	chosen_path = new_path
	soul_points = 3
	path_selected.emit(chosen_path)
	soul_points_changed.emit(soul_points)
	return true

func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		soul_points += 1
		experience_to_next_level = 100 + (level - 1) * 35
	soul_points_changed.emit(soul_points)

func add_test_soul_point() -> void:
	soul_points += 1
	soul_points_changed.emit(soul_points)

func spend_soul_point(stat_name: String) -> bool:
	if soul_points <= 0:
		return false
	if not stat_name in ["strength", "wisdom", "agility", "speed", "willpower"]:
		return false
	set(stat_name, int(get(stat_name)) + 1)
	soul_points -= 1
	stat_changed.emit(stat_name, int(get(stat_name)))
	soul_points_changed.emit(soul_points)
	return true

func unlock_skill(skill_id: String) -> bool:
	var definition: Dictionary = get_skill_definition(skill_id)
	if definition.is_empty() or is_skill_unlocked(skill_id):
		return false
	var cost: int = int(definition.get("cost", 1))
	if soul_points < cost:
		return false
	soul_points -= cost
	unlocked_skills[skill_id] = true
	skill_changed.emit(skill_id, true)
	soul_points_changed.emit(soul_points)
	return true

func is_skill_unlocked(skill_id: String) -> bool:
	return bool(unlocked_skills.get(skill_id, false))

func get_path_name() -> String:
	match chosen_path:
		Path.MARTIAL_ARTS:
			return "Martial Arts"
		Path.CULTIVATION:
			return "Cultivation"
		Path.MAGIC:
			return "Magic"
		Path.KNIGHTHOOD:
			return "Knighthood"
	return "Unchosen"

func get_path_description(path_value: Path) -> String:
	match path_value:
		Path.MARTIAL_ARTS:
			return "Unite Body, Soul, and Will."
		Path.CULTIVATION:
			return "Build inner Qi and advance toward immortality."
		Path.MAGIC:
			return "Expand Magic Circles and fill them with Mana."
		Path.KNIGHTHOOD:
			return "Master Sword skills and strengthen Aura."
	return "A lone mortal must choose a destiny."

func get_path_metric() -> String:
	match chosen_path:
		Path.MARTIAL_ARTS:
			return "Body-Soul-Will Sync: %d%%" % roundi(body_soul_will_sync)
		Path.CULTIVATION:
			return "Realm: %d  |  Qi: %.0f" % [cultivation_realm, qi]
		Path.MAGIC:
			return "Circles: %d  |  Mana: %.0f / %.0f" % [magic_circles, mana, maximum_mana]
		Path.KNIGHTHOOD:
			return "Aura Level: %d  |  Aura: %.0f" % [knight_rank, aura]
	return "Path: Unchosen"

func get_skill_definitions() -> Array[Dictionary]:
	match chosen_path:
		Path.MARTIAL_ARTS:
			return [
				{"id": "iron_body", "name": "Iron Body", "description": "Increase physical resilience.", "cost": 1},
				{"id": "soul_palm", "name": "Soul Palm", "description": "Focus Soul power into attacks.", "cost": 1},
				{"id": "will_breaker", "name": "Will Breaker", "description": "Break through enemy resolve.", "cost": 2}
			]
		Path.CULTIVATION:
			return [
				{"id": "qi_gathering", "name": "Qi Gathering", "description": "Gather inner Qi more efficiently.", "cost": 1},
				{"id": "spirit_step", "name": "Spirit Step", "description": "Move with a lighter spirit.", "cost": 1},
				{"id": "immortal_sword_qi", "name": "Immortal Sword Qi", "description": "Shape Qi into sword power.", "cost": 2}
			]
		Path.MAGIC:
			return [
				{"id": "mana_bolt", "name": "Mana Bolt", "description": "Release a focused Mana projectile.", "cost": 1},
				{"id": "second_circle", "name": "Second Circle", "description": "Unlock a second Magic Circle.", "cost": 1},
				{"id": "arcane_shield", "name": "Arcane Shield", "description": "Form a protective arcane barrier.", "cost": 2}
			]
		Path.KNIGHTHOOD:
			return [
				{"id": "aura_slash", "name": "Aura Slash", "description": "Extend a strike with Aura.", "cost": 1},
				{"id": "knight_dash", "name": "Knight Dash", "description": "Dash with disciplined force.", "cost": 1},
				{"id": "golden_aura", "name": "Golden Aura", "description": "Awaken a golden defensive Aura.", "cost": 2}
			]
	return []

func get_skill_definition(skill_id: String) -> Dictionary:
	for definition: Dictionary in get_skill_definitions():
		if String(definition.get("id", "")) == skill_id:
			return definition
	return {}
