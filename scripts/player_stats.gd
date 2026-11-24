class_name PlayerStats
extends Resource

## Shared progression foundation for all four Ascension paths.
signal path_selected(path: Path)
signal stat_changed(stat_name: String, new_value: int)
signal soul_points_changed(new_value: int)
signal skill_changed(skill_id: String, unlocked: bool)
signal progression_changed
signal experience_changed(current: int, maximum: int)
signal level_up(new_level: int)
signal ascension_changed(rank: int, progress: float)
signal breakthrough_completed(new_rank: int)
signal save_reset

enum Path {
	NONE,
	MARTIAL_ARTS,
	CULTIVATION,
	MAGIC,
	KNIGHTHOOD
}

const SAVE_PATH := "user://save_data.json"
const MAX_ASCENSION_RANK: int = 9

@export_category("Identity")
@export var chosen_path: Path = Path.NONE
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100
@export var soul_points: int = 0

@export_category("Ascension")
@export var ascension_rank: int = 1
@export var ascension_progress: float = 0.0

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
var is_loading: bool = false

func get_move_speed() -> float:
	return BASE_MOVE_SPEED + float(maxi(speed - 1, 0)) * SPEED_PER_POINT

func get_damage_multiplier() -> float:
	return 1.0 + float(maxi(ascension_rank - 1, 0)) * 0.25

func get_energy_multiplier() -> float:
	return get_damage_multiplier()

func choose_path(new_path: Path) -> bool:
	if chosen_path != Path.NONE or new_path == Path.NONE:
		return false
	chosen_path = new_path
	soul_points = 3
	path_selected.emit(chosen_path)
	soul_points_changed.emit(soul_points)
	experience_changed.emit(experience, experience_to_next_level)
	save_to_disk()
	return true

func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	var did_level_up := false
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		soul_points += 2
		experience_to_next_level = 100 + (level - 1) * 35
		did_level_up = true
	soul_points_changed.emit(soul_points)
	experience_changed.emit(experience, experience_to_next_level)
	if did_level_up:
		level_up.emit(level)
	save_to_disk()

func add_test_soul_point() -> void:
	soul_points += 1
	soul_points_changed.emit(soul_points)
	save_to_disk()

func spend_soul_point(stat_name: String) -> bool:
	if soul_points <= 0:
		return false
	if not stat_name in ["strength", "wisdom", "agility", "speed", "willpower"]:
		return false
	set(stat_name, int(get(stat_name)) + 1)
	soul_points -= 1
	stat_changed.emit(stat_name, int(get(stat_name)))
	soul_points_changed.emit(soul_points)
	save_to_disk()
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
	save_to_disk()
	return true

func is_skill_unlocked(skill_id: String) -> bool:
	return bool(unlocked_skills.get(skill_id, false))

func can_breakthrough() -> bool:
	return chosen_path != Path.NONE and ascension_rank < MAX_ASCENSION_RANK and ascension_progress >= 100.0

func advance_path_progress(amount: float) -> void:
	if chosen_path == Path.NONE or amount <= 0.0:
		return
	match chosen_path:
		Path.MARTIAL_ARTS:
			body_soul_will_sync = minf(body_soul_will_sync + amount, 100.0)
		Path.CULTIVATION:
			qi += amount
		Path.MAGIC:
			magic_circles = maxi(magic_circles, 1)
		Path.KNIGHTHOOD:
			aura += amount
	ascension_progress = minf(ascension_progress + amount, 100.0)
	progression_changed.emit()
	ascension_changed.emit(ascension_rank, ascension_progress)
	save_to_disk()

func breakthrough() -> bool:
	if not can_breakthrough():
		return false
	ascension_rank += 1
	ascension_progress = 0.0
	ascension_changed.emit(ascension_rank, ascension_progress)
	breakthrough_completed.emit(ascension_rank)
	progression_changed.emit()
	save_to_disk()
	return true

func get_path_name(arabic: bool = false) -> String:
	if arabic:
		match chosen_path:
			Path.MARTIAL_ARTS: return "الفنون القتالية"
			Path.CULTIVATION: return "الزراعة"
			Path.MAGIC: return "السحر"
			Path.KNIGHTHOOD: return "الفروسية"
		return "غير مختار"
	match chosen_path:
		Path.MARTIAL_ARTS: return "Martial Arts"
		Path.CULTIVATION: return "Cultivation"
		Path.MAGIC: return "Magic"
		Path.KNIGHTHOOD: return "Knighthood"
	return "Unchosen"

func get_path_description(path_value: Path, arabic: bool = false) -> String:
	if arabic:
		match path_value:
			Path.MARTIAL_ARTS: return "وحّد الجسد والروح والإرادة."
			Path.CULTIVATION: return "ابنِ الـ Qi الداخلي وتقدم نحو الخلود."
			Path.MAGIC: return "وسّع الدوائر السحرية واملأها بالـ Mana."
			Path.KNIGHTHOOD: return "أتقن السيف وقوِّ الـ Aura."
		return "اختر مصيرك."
	match path_value:
		Path.MARTIAL_ARTS: return "Unite Body, Soul, and Will."
		Path.CULTIVATION: return "Build inner Qi and advance toward immortality."
		Path.MAGIC: return "Expand Magic Circles and fill them with Mana."
		Path.KNIGHTHOOD: return "Master Sword skills and strengthen Aura."
	return "A lone mortal must choose a destiny."

func get_rank_name(rank: int = ascension_rank, arabic: bool = false) -> String:
	var index := clampi(rank - 1, 0, MAX_ASCENSION_RANK - 1)
	var english := [
		["Mortal Body", "Iron Bone", "Bronze Skin", "Blood Purification", "Soul-Body Unity", "Spirit Meridian", "Heaven Shattering", "Martial Overlord", "Peak Martial Saint"],
		["Qi Condensation", "Foundation Establishment", "Core Formation", "Golden Core", "Nascent Soul", "Soul Transformation", "Void Refinement", "Tribulation Transcendence", "Immortal Ascension"],
		["1st Circle Apprentice", "2nd Circle Adept", "3rd Circle Mage", "4th Circle Master", "5th Circle Grand Mage", "6th Circle High Mage", "7th Circle Archmage", "8th Circle Grand Archmage", "9th Circle Supreme Archmage"],
		["Mortal Squire", "Aura Knight", "Silver Knight", "Gold Knight", "Sword Master", "Grand Knight", "Radiant Knight", "Sovereign Knight", "Sovereign Radiant Knight"]
	]
	var arabic_names := [
		["الجسد الفاني", "العظم الحديدي", "الجلد البرونزي", "تنقية الدم", "وحدة الروح والجسد", "مسارات الروح", "تحطيم السماء", "سيد الفنون القتالية", "قديس الفنون القتالية الأسمى"],
		["تكثيف الـ Qi", "تأسيس الأساس", "تكوين النواة", "النواة الذهبية", "الروح الوليدة", "تحول الروح", "صقل الفراغ", "عبور المحنة", "الصعود إلى الخلود"],
		["متدرب الدائرة الأولى", "متمرس الدائرة الثانية", "ساحر الدائرة الثالثة", "سيد الدائرة الرابعة", "الساحر الأعظم للدائرة الخامسة", "الساحر الأعلى للدائرة السادسة", "رئيس سحرة الدائرة السابعة", "رئيس السحرة الأعظم للدائرة الثامنة", "رئيس السحرة الأعلى للدائرة التاسعة"],
		["الفارس المبتدئ", "فارس الـ Aura", "الفارس الفضي", "الفارس الذهبي", "سيد السيف", "الفارس الأعظم", "الفارس المشع", "الفارس السيادي", "الفارس السيادي المشع"]
	]
	var path_index := maxi(int(chosen_path) - 1, 0)
	return String((arabic_names if arabic else english)[path_index][index])

func get_path_metric(arabic: bool = false) -> String:
	var rank_text := get_rank_name(ascension_rank, arabic)
	if arabic:
		return "%s | التقدم: %d%%" % [rank_text, roundi(ascension_progress)]
	return "%s | Progress: %d%%" % [rank_text, roundi(ascension_progress)]

func get_skill_definitions(arabic: bool = false) -> Array[Dictionary]:
	match chosen_path:
		Path.MARTIAL_ARTS:
			if arabic:
				return [
					{"id": "iron_body", "name": "الجسد الحديدي", "description": "يزيد الصمود الجسدي.", "cost": 1},
					{"id": "soul_palm", "name": "كف الروح", "description": "يركز قوة الروح في الهجمات.", "cost": 1},
					{"id": "will_breaker", "name": "كاسر الإرادة", "description": "يحطم عزيمة العدو.", "cost": 2}
				]
			return [
				{"id": "iron_body", "name": "Iron Body", "description": "Increase physical resilience.", "cost": 1},
				{"id": "soul_palm", "name": "Soul Palm", "description": "Focus Soul power into attacks.", "cost": 1},
				{"id": "will_breaker", "name": "Will Breaker", "description": "Break through enemy resolve.", "cost": 2}
			]
		Path.CULTIVATION:
			if arabic:
				return [
					{"id": "qi_gathering", "name": "جمع الـ Qi", "description": "اجمع الـ Qi الداخلي بكفاءة أكبر.", "cost": 1},
					{"id": "spirit_step", "name": "خطوة الروح", "description": "تحرك بخفة روحية أكبر.", "cost": 1},
					{"id": "immortal_sword_qi", "name": "Qi السيف الخالد", "description": "شكّل الـ Qi في قوة سيف.", "cost": 2}
				]
			return [
				{"id": "qi_gathering", "name": "Qi Gathering", "description": "Gather inner Qi more efficiently.", "cost": 1},
				{"id": "spirit_step", "name": "Spirit Step", "description": "Move with a lighter spirit.", "cost": 1},
				{"id": "immortal_sword_qi", "name": "Immortal Sword Qi", "description": "Shape Qi into sword power.", "cost": 2}
			]
		Path.MAGIC:
			if arabic:
				return [
					{"id": "mana_bolt", "name": "قذيفة Mana", "description": "أطلق قذيفة Mana مركزة.", "cost": 1},
					{"id": "second_circle", "name": "الدائرة الثانية", "description": "افتح دائرة سحرية ثانية.", "cost": 1},
					{"id": "arcane_shield", "name": "الدرع الغامض", "description": "كوّن حاجزًا سحريًا واقيًا.", "cost": 2}
				]
			return [
				{"id": "mana_bolt", "name": "Mana Bolt", "description": "Release a focused Mana projectile.", "cost": 1},
				{"id": "second_circle", "name": "Second Circle", "description": "Unlock a second Magic Circle.", "cost": 1},
				{"id": "arcane_shield", "name": "Arcane Shield", "description": "Form a protective arcane barrier.", "cost": 2}
			]
		Path.KNIGHTHOOD:
			if arabic:
				return [
					{"id": "aura_slash", "name": "ضربة الـ Aura", "description": "مدد الضربة بطاقة الـ Aura.", "cost": 1},
					{"id": "knight_dash", "name": "اندفاعة الفارس", "description": "اندفع بقوة وانضباط.", "cost": 1},
					{"id": "golden_aura", "name": "الـ Aura الذهبية", "description": "أيقظ Aura ذهبية دفاعية.", "cost": 2}
				]
			return [
				{"id": "aura_slash", "name": "Aura Slash", "description": "Extend a strike with Aura.", "cost": 1},
				{"id": "knight_dash", "name": "Knight Dash", "description": "Dash with disciplined force.", "cost": 1},
				{"id": "golden_aura", "name": "Golden Aura", "description": "Awaken a golden defensive Aura.", "cost": 2}
			]
	return []

func get_skill_definition(skill_id: String, arabic: bool = false) -> Dictionary:
	for definition: Dictionary in get_skill_definitions(arabic):
		if String(definition.get("id", "")) == skill_id:
			return definition
	return {}

func save_to_disk() -> bool:
	if is_loading:
		return true
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_to_dictionary()))
	file.close()
	return true

func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return false
	is_loading = true
	_apply_dictionary(parsed)
	is_loading = false
	return chosen_path != Path.NONE

func reset_save() -> void:
	chosen_path = Path.NONE
	level = 1
	experience = 0
	experience_to_next_level = 100
	soul_points = 0
	ascension_rank = 1
	ascension_progress = 0.0
	strength = 1
	wisdom = 1
	agility = 1
	speed = 1
	willpower = 1
	body_soul_will_sync = 0.0
	qi = 0.0
	magic_circles = 0
	mana = 0.0
	aura = 0.0
	unlocked_skills.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	save_reset.emit()
	path_selected.emit(Path.NONE)
	soul_points_changed.emit(soul_points)
	experience_changed.emit(experience, experience_to_next_level)
	ascension_changed.emit(ascension_rank, ascension_progress)

func _to_dictionary() -> Dictionary:
	return {
		"chosen_path": int(chosen_path),
		"level": level,
		"experience": experience,
		"experience_to_next_level": experience_to_next_level,
		"soul_points": soul_points,
		"ascension_rank": ascension_rank,
		"ascension_progress": ascension_progress,
		"strength": strength,
		"wisdom": wisdom,
		"agility": agility,
		"speed": speed,
		"willpower": willpower,
		"body_soul_will_sync": body_soul_will_sync,
		"qi": qi,
		"magic_circles": magic_circles,
		"mana": mana,
		"aura": aura,
		"unlocked_skills": unlocked_skills.keys()
	}

func _apply_dictionary(data: Dictionary) -> void:
	chosen_path = clampi(int(data.get("chosen_path", 0)), 0, 4) as Path
	level = maxi(int(data.get("level", 1)), 1)
	experience = maxi(int(data.get("experience", 0)), 0)
	experience_to_next_level = maxi(int(data.get("experience_to_next_level", 100)), 1)
	soul_points = maxi(int(data.get("soul_points", 0)), 0)
	ascension_rank = clampi(int(data.get("ascension_rank", 1)), 1, MAX_ASCENSION_RANK)
	ascension_progress = clampf(float(data.get("ascension_progress", 0.0)), 0.0, 100.0)
	strength = maxi(int(data.get("strength", 1)), 1)
	wisdom = maxi(int(data.get("wisdom", 1)), 1)
	agility = maxi(int(data.get("agility", 1)), 1)
	speed = maxi(int(data.get("speed", 1)), 1)
	willpower = maxi(int(data.get("willpower", 1)), 1)
	body_soul_will_sync = maxf(float(data.get("body_soul_will_sync", 0.0)), 0.0)
	qi = maxf(float(data.get("qi", 0.0)), 0.0)
	magic_circles = maxi(int(data.get("magic_circles", 0)), 0)
	mana = maxf(float(data.get("mana", 0.0)), 0.0)
	aura = maxf(float(data.get("aura", 0.0)), 0.0)
	unlocked_skills.clear()
	for skill_id in data.get("unlocked_skills", []):
		unlocked_skills[String(skill_id)] = true
