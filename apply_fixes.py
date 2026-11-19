#!/usr/bin/env python3
"""Patch a local clone of Pixel-Forge. Usage: python3 apply_fixes.py /path/to/Pixel-Forge
Fixes the broken res://horror/ paths and adds a few gameplay upgrades to main.gd.
Every edit is asserted to match exactly once; nothing is written if a check fails."""
import sys, pathlib

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
T = lambda s: s.replace("<T>", "\t")

def read(p):
    raw = p.read_bytes().decode("utf-8")
    crlf = "\r\n" in raw
    return raw.replace("\r\n", "\n"), crlf

def write(p, text, crlf):
    p.write_bytes((text.replace("\n", "\r\n") if crlf else text).encode("utf-8"))

# 1) path fixes: everything actually lives at the repo root
path_files = ["project.godot", "main.tscn", "gallery.tscn", "main.gd", "gallery.gd"]
pending = {}
for name in path_files:
    p = root / name
    if not p.exists():
        sys.exit(f"missing {p} - run from/for the repo root")
    text, crlf = read(p)
    pending[name] = [text.replace("res://horror/", "res://"), crlf]

# 2) gameplay upgrades in main.gd
edits = [
 # stamina lockout + run timer vars
 (r'''var stamina := 1.0
''', r'''var stamina := 1.0
var winded := false
var run_time := 0.0
'''),
 (r'''var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and mv.y > 0.0 and stamina > 0.0 and not crouch''',
  T(r'''if stamina <= 0.0: winded = true
<T>elif stamina > 0.25: winded = false
<T>var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and mv.y > 0.0 and stamina > 0.0 and not winded and not crouch''')),
 (T(r'''stamina = 1.0
<T>battery = 1.0'''), T(r'''stamina = 1.0
<T>winded = false
<T>run_time = 0.0
<T>battery = 1.0''')),
 # timer
 (T(r'''<T>_update_player(dt)
<T>_update_butcher(dt)'''), T(r'''<T>run_time += dt
<T>_update_player(dt)
<T>_update_butcher(dt)''')),
 # helpers (best time saved to user://)
 (r'''func _die() -> void:
''', T(r'''func _fmt_time(t: float) -> String:
<T>return "%d:%02d" % [floori(t / 60.0), int(t) % 60]

func _record_time(t: float) -> float:
<T>var cfg := ConfigFile.new()
<T>cfg.load("user://last_revenge.cfg")
<T>var best: float = cfg.get_value("run", "best", 0.0)
<T>if best <= 0.0 or t < best:
<T><T>best = t
<T><T>cfg.set_value("run", "best", best)
<T><T>cfg.save("user://last_revenge.cfg")
<T>return best

func _die() -> void:
''')),
 (r'''_show_overlay("YOU DIED\n\nThe Butcher found you.\n\nENTER  try again     G  gallery")''',
  r'''_show_overlay("YOU DIED\n\nThe Butcher found you after %s.\n\nENTER  try again     G  gallery" % _fmt_time(run_time))'''),
 (r'''_show_overlay("YOU ESCAPED\n\nThe Devil's Bible burns behind you.\n\nENTER  play again     G  gallery")''',
  T(r'''var best := _record_time(run_time)
<T>_show_overlay("YOU ESCAPED\n\nTime: %s   Best: %s\n\nThe Devil's Bible burns behind you.\n\nENTER  play again     G  gallery" % [_fmt_time(run_time), _fmt_time(best)])''')),
 # reliable Butcher footsteps (fire once per stride)
 (r'''b_step += dt * speed * 2.0''', T(r'''var prev_step := b_step
<T>b_step += dt * speed * 2.0''')),
 (T(r'''if moving and sin(b_step) > 0.98 and b_step - floorf(b_step) < 0.5:
<T><T>p_butcher.stream = snd["bstep"]
<T><T>if not p_butcher.playing: p_butcher.play()'''),
  T(r'''if moving and floorf(b_step / PI) != floorf(prev_step / PI):
<T><T>p_butcher.stream = snd["bstep"]
<T><T>p_butcher.play()''')),
]
text = pending["main.gd"][0]
for old, new in edits:
    n = text.count(old)
    if n != 1:
        sys.exit(f"ABORTED: expected 1 match, found {n} for:\n{old}\n(main.gd differs from the version I analysed)")
    text = text.replace(old, new)
pending["main.gd"][0] = text

for name, (txt, crlf) in pending.items():
    write(root / name, txt, crlf)
    print("patched", name)
print("done")
