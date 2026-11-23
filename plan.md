# Ascension Action RPG — Phase 1

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
    └── touch_ui.gd            # CanvasLayer وأزرار اللمس ومنطقة سحب الكاميرا
```

## ما تم تضمينه في Phase 1
- أربعة مسارات Ascension في `PlayerStats.Path`.
- Strength, Wisdom, Agility, Speed, Willpower.
- Level, XP, Soul Points، وتقدم Martial Arts / Cultivation / Magic / Knighthood.
- Arena مبنية من BoxMesh وCapsuleMesh وStandardMaterial3D فقط.
- Third-person camera باستخدام SpringArm3D وCamera3D.
- WASD، الأسهم، Space، J، والنقر الأيسر.
- Touch directional pad على اليسار، Jump وAttack على اليمين، وسحب لمس لتدوير الكاميرا.

## خارج النطاق
واجهة Soul Tree، الأعداء، الجرد، المؤثرات الصوتية، والملفات الفنية الخارجية.
