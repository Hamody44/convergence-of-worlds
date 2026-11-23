# Ascension Action RPG — Phase 1 + Phase 2 + Phase 3

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
│   ├── player_stats.gd        # Resource مستقل لمسارات القوة وشجرة الروح والتقدم
│   ├── combat_projectile.gd   # مقذوفات Primitive مع اصطدام وضرر
│   └── training_dummy.gd      # أهداف التدريب وHP وتجدد الصحة وأرقام الضرر
└── ui/
    ├── touch_ui.gd            # CanvasLayer وأزرار اللمس ومنطقة سحب الكاميرا
    ├── progression_ui.gd      # اختيار المسار وSoul Tree وفتح المهارات
    └── combat_ui.gd            # HP/energy bars وأزرار المهارات واختصارات 1/2/3
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

## ما تم تضمينه في Phase 3
- Health وPath Energy HUD يتغير اسمه حسب المسار ويعاد توليده حسب Wisdom.
- Basic Attack يستخدم `Area3D` hitbox وضررًا متأثرًا بـ Strength مع slash مضيء.
- المهارات الاثنتا عشرة للمسارات الأربعة: تكلفة طاقة، cooldown، ضرر أو buff، ومؤثر primitive مضيء.
- أزرار Skills 1/2/3 على شاشة اللمس واختصارات لوحة المفاتيح `1`, `2`, `3`.
- أزرار المهارات تتغير تلقائيًا إلى اسم المهارة عند فتحها وتُعطّل عند القفل أو نقص الطاقة.
- Training Dummy عدد 2، لكل منهما HP bar عائم وأرقام ضرر وتجدد تلقائي بعد الهزيمة.
- جميع المقذوفات والمؤثرات تستخدم `SphereMesh` أو `BoxMesh` أو `CylinderMesh` مع emission، دون ملفات خارجية.

## خارج النطاق
الذكاء الاصطناعي للأعداء، XP drops، حلقات Level Up، الجرد، المؤثرات الصوتية، والملفات الفنية الخارجية.
