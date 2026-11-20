import os
import shutil

# 1. Patch horror/main.gd and main.gd for corridor backside hiding and Father viewing window / sign
for path in ["/Users/malikarjunr/Pixel-Forge/horror/main.gd", "/Users/malikarjunr/Pixel-Forge/main.gd"]:
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    # Hide backside of corridor so doorway is completely clear
    old_corr = """\t# Horror Corridor 5 (Mira's domain extending West from hallway door at x=1.0, z=6.0)
\tvar corr := fit("corridor", 2.8)
\tcorr.position = Vector3(-7.5, 0, 6.0)
\tcorr.rotation.y = PI / 2.0
\tadd_child(corr)"""

    new_corr = """\t# Horror Corridor 5 (Mira's domain extending West from hallway door at x=1.0, z=6.0)
\tvar corr := fit("corridor", 2.8)
\tcorr.position = Vector3(-7.5, 0, 6.0)
\tcorr.rotation.y = PI / 2.0
\tfor c in corr.find_children("*", "MeshInstance3D", true, false):
\t\tif "backside" in c.name.to_lower():
\t\t\t(c as MeshInstance3D).visible = false
\tadd_child(corr)"""

    if old_corr in code:
        code = code.replace(old_corr, new_corr)

    # Add red glow and grate window to Slaughterhouse doors so Father is clearly visible inside
    old_slaughter_dressing = """\t# Slaughterhouse diorama environment props
\tvar diorama := fit("diorama", 1.8)
\tdiorama.position = Vector3(24.8, 0, 9.5)
\tadd_child(diorama)"""

    new_slaughter_dressing = """\t# Slaughterhouse diorama environment props
\tvar diorama := fit("diorama", 1.8)
\tdiorama.position = Vector3(24.8, 0, 9.5)
\tadd_child(diorama)

\t# Ominous red light shining from inside Slaughterhouse through the doors
\tvar sl_glow := OmniLight3D.new()
\tsl_glow.light_color = Color(1.0, 0.18, 0.1)
\tsl_glow.light_energy = 3.0
\tsl_glow.omni_range = 8.0
\tsl_glow.position = Vector3(23.0, 1.8, 10.0)
\tadd_child(sl_glow)

\t# Father viewing window in dining room door (bars to see the Butcher inside)
\tvar grate := MeshInstance3D.new()
\tvar gm := BoxMesh.new()
\tgm.size = Vector3(0.12, 0.6, 0.45)
\tgrate.mesh = gm
\tvar gmat := _mat(Color(0.15, 0.15, 0.15), 0.3, 0.9)
\tgrate.material_override = gmat
\tgrate.position = Vector3(21.0, 1.5, 10.0)
\tadd_child(grate)"""

    if old_slaughter_dressing in code:
        code = code.replace(old_slaughter_dressing, new_slaughter_dressing)

    # Clarify interaction message when inspecting locked Slaughterhouse door
    old_lock_msg = """say("Locked by Abel Crane (Father). Lily holds Father's key! Defeat her with the bat.")"""
    new_lock_msg = """say("Locked: Slaughterhouse (Father's Room). You can hear Abel Crane breathing inside! Slay Lily with the bat to get Father's Key.", 7.0)"""
    if old_lock_msg in code:
        code = code.replace(old_lock_msg, new_lock_msg)

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)

print("Patched horror/main.gd and main.gd!")

# 2. Patch horror/main_cinematic.gd and main_cinematic.gd to eliminate the black screen flashback bug
for path in ["/Users/malikarjunr/Pixel-Forge/horror/main_cinematic.gd", "/Users/malikarjunr/Pixel-Forge/main_cinematic.gd"]:
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    # Prevent black screen flashback when picking up lore
    old_collect = """func _collect_lore(it: Dictionary) -> void:
\tvar page: Dictionary = it.page
\tif lore_found.has(page.id):
\t\treturn
\tsuper(it)
\tif cine_cam != null and CineData.FLASHBACKS.has(page.id):
\t\t_cs_start("flashback", {"id": page.id, "text": overlay_label.text})"""

    new_collect = """func _collect_lore(it: Dictionary) -> void:
\tvar page: Dictionary = it.page
\tif lore_found.has(page.id):
\t\treturn
\tsuper(it)
\t# Safe readable lore reading: do not black out screen with broken (400,400) camera
\tplay("book", -2.0)
\tplay("stinger", -12.0)"""

    if old_collect in code:
        code = code.replace(old_collect, new_collect)

    # In _physics_process: pause the rat when reading memory so player cannot be attacked while reading
    old_phys = """func _physics_process(dt: float) -> void:
\tsuper(dt)
\tif state == "cinematic":
\t\t_unpause_audio()
\t\treturn"""

    new_phys = """func _physics_process(dt: float) -> void:
\tif state == "reading":
\t\tif rat != null: rat.velocity = Vector3.ZERO
\t\treturn
\tsuper(dt)
\tif state == "cinematic":
\t\t_unpause_audio()
\t\treturn"""

    if old_phys in code:
        code = code.replace(old_phys, new_phys)

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)

print("Patched horror/main_cinematic.gd and main_cinematic.gd!")
