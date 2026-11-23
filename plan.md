# Ascension Action RPG — Phase 1 + Phase 2

## الهدف
إنشاء نموذج أولي ثلاثي الأبعاد يعمل مباشرة في Godot 4.7 على جهاز Android touchscreen، بدون أي ملفات خارجية.

## هيكل الملفات

```text
action_rpg_phase1/
├── project.godot              # إعدادات المشروع وإجراءات لوحة المفاتيح/الفأرة
├── plan.md                    # هذا المستند
├── scenes/
│   └── main.tscn              # مشهد Root صغير؛ البناء الفعلي يتم بالكود
├── scripts/
│   ├── main.gd                # الساحة والإضاءة والعوائق وإنشاء اللاعب والواجهة
│   ├── player.gd              # CharacterBody3D، الحركة، القفز، الكاميرا والهجوم
│   └── player_stats.gd        # Resource مستقل لمسارات القوة وشجرة الروح والتقدم
└── ui/
    ├── touch_ui.gd            # CanvasLayer وأزرار اللمس ومنطقة سحب الكاميرا
    └── progression_ui.gd      # اختيار المسار وSoul Tree وفتح المهارات
```

## ما تم تضمينه في Phase 1
- أربعة مسارات Ascension في `PlayerStats.Path`.
- Strength, Wisdom, Agility, Speed, Willpower.
- Level, XP, Soul Points، وتقدم Martial Arts / Cultivation / Magic / Knighthood.
- Arena مبنية من BoxMesh وCapsuleMesh وStandardMaterial3D فقط.
- Third-person camera باستخدام SpringArm3D وCamera3D.
- WASD، الأسهم، Space، J، والنقر الأيسر.
- Touch directional pad على اليسار، Jump وAttack على اليمين، وسحب لمس لتدوير الكاميرا.

## ما تم تضمينه في Phase 2
- Path Selection Panel يظهر تلقائيًا عندما يكون المسار `NONE`.
- أربعة أزرار كبيرة لاختيار Martial Arts أو Cultivation أو Magic أو Knighthood.
- منح 3 Soul Points عند اختيار المسار وإظهار زر `SOUL TREE [K]`.
- Soul Tree Panel يحتوي على المسار، مقياس الصعود، Level، Soul Points، والإحصاءات الخمسة.
- أزرار `+` للإحصاءات، مع إشارات PlayerStats التي تحدث الحركة والقفز وسرعة الهجوم فورًا.
- ثلاث مهارات خاصة بالمسار المختار مع تكاليف 1 أو 2 Soul Points.
- زر `+1 SOUL POINT (TEST)` للاختبار قبل بناء الأعداء.
- واجهة Phase 2 تستخدم `PanelContainer` و`VBoxContainer` و`HBoxContainer` و`ScrollContainer`.

## خارج النطاق
الأعداء، الجرد، المؤثرات الصوتية، والملفات الفنية الخارجية.
