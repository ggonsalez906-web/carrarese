import os

costumes = [
    ('costume_camiseta', 'uid://pf_camiseta_001'),
    ('costume_bufanda', 'uid://pf_bufanda_001'),
    ('costume_completo', 'uid://pf_completo_001'),
    ('costume_todo', 'uid://pf_todo_001')
]

res_dir = r'c:\Users\daylan\Desktop\assets\Carrarese_Aventura\resources'

for name, uid in costumes:
    path = os.path.join(res_dir, f'{name}.tres')
    content = f'''[gd_resource type="SpriteFrames" load_steps=12 format=3 uid="{uid}"]

[ext_resource type="Texture2D" path="res://assets/personajes/{name}/idle_0.png" id="1_id0"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/idle_1.png" id="2_id1"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/walk_0.png" id="3_wk0"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/walk_1.png" id="4_wk1"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/walk_2.png" id="5_wk2"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/walk_3.png" id="6_wk3"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/walk_4.png" id="7_wk4"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/jump_up.png" id="8_jp1"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/jump_fall.png" id="9_jf0"]
[ext_resource type="Texture2D" path="res://assets/personajes/{name}/hurt_0.png" id="10_hr0"]

[resource]
animations = [{{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("1_id0")
}}, {{
"duration": 1.0,
"texture": ExtResource("2_id1")
}}],
"loop": true,
"name": &"idle",
"speed": 3.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("3_wk0")
}}, {{
"duration": 1.0,
"texture": ExtResource("4_wk1")
}}, {{
"duration": 1.0,
"texture": ExtResource("5_wk2")
}}, {{
"duration": 1.0,
"texture": ExtResource("6_wk3")
}}, {{
"duration": 1.0,
"texture": ExtResource("7_wk4")
}}],
"loop": true,
"name": &"walk",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("3_wk0")
}}, {{
"duration": 1.0,
"texture": ExtResource("4_wk1")
}}, {{
"duration": 1.0,
"texture": ExtResource("5_wk2")
}}, {{
"duration": 1.0,
"texture": ExtResource("6_wk3")
}}, {{
"duration": 1.0,
"texture": ExtResource("7_wk4")
}}],
"loop": true,
"name": &"run",
"speed": 13.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("8_jp1")
}}],
"loop": false,
"name": &"jump",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("9_jf0")
}}],
"loop": false,
"name": &"fall",
"speed": 6.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("10_hr0")
}}],
"loop": true,
"name": &"hurt",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("5_wk2")
}}],
"loop": false,
"name": &"throw",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("5_wk2")
}}],
"loop": false,
"name": &"celebrate",
"speed": 4.0
}}]
'''
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Created {name}.tres')
