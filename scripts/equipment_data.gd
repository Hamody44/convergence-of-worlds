class_name EquipmentData
extends RefCounted

const RARITIES := ["Common", "Rare", "Ascendant"]
const RARITY_AR := {"Common": "عادي", "Rare": "نادر", "Ascendant": "صاعد"}

static func make_item(path: int, slot: String, stage: int, rarity_index: int = 0) -> Dictionary:
	var rarity: String = RARITIES[clampi(rarity_index, 0, 2)]
	var tier := 1.0 + float(rarity_index) * 0.65 + float(maxi(stage - 1, 0)) * 0.22
	var item := {"id": "%s_%s_%d_%d" % [slot, path, stage, Time.get_ticks_usec()], "slot": slot, "path": path, "rarity": rarity, "stage": stage, "power": roundi(8.0 * tier)}
	match path:
		PlayerStats.Path.MARTIAL_ARTS:
			item["name"] = "Soul-Forged Gauntlets" if rarity_index > 0 else "Iron Cestus"
			item["name_ar"] = "قفازات الروح المصهورة" if rarity_index > 0 else "قبضة الحديد"
			item["armor_name"] = "Martial Vest"
			item["armor_name_ar"] = "سترة قتالية"
			item["stats"] = {"strength": roundi(3.0 * tier), "speed": roundi(2.0 * tier)}
		PlayerStats.Path.CULTIVATION:
			item["name"] = "Immortal Flying Sword" if rarity_index > 0 else "Jade Spirit Blade"
			item["name_ar"] = "سيف التحليق الخالد" if rarity_index > 0 else "نصل اليشم الروحي"
			item["armor_name"] = "Daoist Robe"
			item["armor_name_ar"] = "رداء داوي"
			item["stats"] = {"wisdom": roundi(3.0 * tier), "qi": roundi(2.0 * tier)}
		PlayerStats.Path.MAGIC:
			item["name"] = "Astral Archmage Scepter" if rarity_index > 0 else "Mana Conduit Staff"
			item["name_ar"] = "صولجان سيد النجوم" if rarity_index > 0 else "عصا قناة المانا"
			item["armor_name"] = "Runic Cloak"
			item["armor_name_ar"] = "عباءة رونية"
			item["stats"] = {"wisdom": roundi(3.0 * tier), "mana": roundi(3.0 * tier)}
		PlayerStats.Path.KNIGHTHOOD:
			item["name"] = "Radiant Aura Claymore" if rarity_index > 0 else "Squire Longsword"
			item["name_ar"] = "سيف الهالة المشع" if rarity_index > 0 else "سيف التابع الطويل"
			item["armor_name"] = "Plate Armor"
			item["armor_name_ar"] = "درع الصفائح"
			item["stats"] = {"strength": roundi(3.0 * tier), "willpower": roundi(2.0 * tier), "health": roundi(12.0 * tier)}
	item["display_name"] = item["name"] if slot == "Weapon" else item["armor_name"]
	item["display_name_ar"] = item["name_ar"] if slot == "Weapon" else item["armor_name_ar"]
	return item

static func localized_name(item: Dictionary, arabic: bool) -> String:
	return String(item.get("display_name_ar" if arabic else "display_name", "Unknown Gear"))

static func rarity_name(item: Dictionary, arabic: bool) -> String:
	var rarity := String(item.get("rarity", "Common"))
	return String(RARITY_AR.get(rarity, rarity)) if arabic else rarity
