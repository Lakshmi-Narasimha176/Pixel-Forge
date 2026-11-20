extends RefCounted
## Cinematic data for THE LAST REVENGE: flashback sets, subtitle lines, location cards and credits.
## Everything here is plain data. Edit the text, colours and positions freely; main_cinematic.gd reads it.

const SPEAKER_COLORS := {
	"NORA": "#cfe6ff",
	"ADA": "#7fe9ff",
	"ABEL": "#ff5a4a",
	"MIRA": "#d9a6ff",
	"LILY": "#b9ffd6",
	"PEARL": "#ffb3c7",
}

# Lower-third card shown the first time Nora enters each place: [title, subtitle].
const ROOM_TITLES := {
	"tunnel": ["THE TUNNEL", "The only way in. The only way out."],
	"yard": ["THE YARD", "Rain, lanterns and one breaker box"],
	"hall": ["THE HALL", "Family portraits turned to the wall"],
	"bed": ["PEARL'S BEDROOM", "A porcelain doll is still crying"],
	"bath": ["THE BATHROOM", "Something drips in the dark"],
	"study": ["ABEL'S STUDY", "Every drawer smells of iron"],
	"kitchen": ["THE KITCHEN", "Nothing here was ever cooked"],
	"living": ["ADA'S PARLOR", "Someone hums beside the radio"],
	"foyer": ["THE FOYER", "The front door is sealed from inside"],
	"dining": ["THE DINING ROOM", "Set for a family that never left"],
	"slaughter": ["THE SLAUGHTERHOUSE", "Father's Room"],
	"corridor": ["MIRA'S WING", "Lavender and static"],
}

# Chapter cards shown when a required objective is completed: mission id -> [title, subtitle].
const CHAPTER_CARDS := {
	"enter": ["CHAPTER I", "THE HOLLIS HOUSE"],
	"father_key": ["CHAPTER II", "FATHER'S ROOM"],
	"bible": ["CHAPTER III", "THE ESCAPE"],
}

const INTRO_SUBS := [
	[3.4, 3.8, "NORA", "Ada's voice came through a dead radio. After three years of silence."],
	[7.4, 3.6, "NORA", "The Hollis house is still standing. So is whatever Father became."],
	[11.2, 3.4, "ADA", "Follow the lanterns, Nora. Find the breaker. Don't wake him."],
]

const REVEAL_SUBS := [
	[0.9, 1.8, "ABEL", "You came home, Nora."],
	[2.8, 1.7, "ABEL", "Come. Let me show you the family business."],
]

const BIBLE_SUBS := [
	[0.4, 1.6, "ADA", "That's the book. Take it. TAKE IT."],
	[2.5, 1.6, "ABEL", "GIVE. IT. BACK."],
]

const ENDING_TRUE_SUBS := [
	[2.0, 3.4, "NORA", "The Bible let go the moment the last memory was read."],
	[6.0, 3.0, "ADA", "Look at the sky, Nora. It's morning."],
	[9.2, 3.0, "MIRA", "Thank you for finding my letter."],
	[12.4, 3.2, "ABEL", "My girls... I remember now."],
]

const ENDING_BAD_SUBS := [
	[2.0, 3.4, "NORA", "I have the Bible. But the house still has them."],
	[6.0, 3.0, "ADA", "Come back for us, Nora."],
	[9.4, 3.4, "ABEL", "I will wait. I am very good at waiting."],
]

const ADA_VOICE_SUBS := [
	[0.2, 2.8, "ADA", "Nora? You're standing right next to me."],
	[3.4, 3.4, "ADA", "I'm not afraid of Father. I'm afraid he won't remember us."],
	[7.2, 3.4, "ADA", "Free me when you're ready. I'll hum Mama's song."],
]

# Short "spirit freed" cutscenes: id -> colour, who, lines.
const FREED := {
	"ada": {"color": Color(0.45, 0.9, 1.0), "lines": [
		[0.4, 2.0, "ADA", "Thank you, Nora."],
		[2.4, 1.8, "ADA", "Tell Mama I wasn't scared."]]},
	"mira": {"color": Color(0.8, 0.55, 1.0), "lines": [
		[0.4, 2.0, "MIRA", "Abel... forgive me."],
		[2.4, 1.8, "MIRA", "Take care of our girls."]]},
	"lily": {"color": Color(1.0, 0.85, 0.3), "lines": [
		[0.4, 2.0, "LILY", "It was heavy. I held it so long."],
		[2.4, 1.8, "ADA", "That's Father's key. Take it, Nora."]]},
	"pearl": {"color": Color(1.0, 0.55, 0.7), "lines": [
		[0.4, 2.0, "PEARL", "Mama?"],
		[2.4, 1.8, "NORA", "Almost, Pearl. Almost."]]},
}

# Memory flashbacks, played when a lore page is picked up.
# set: model key from MODELS in main.gd (room / soviet), height: metres.
# cast: models placed relative to the middle of the set's floor.
# orbit: the camera circles the target (radius r, angle a in radians, height h), start -> end.
const FLASHBACKS := {
	"abel_ledger": {
		"set": "soviet", "height": 3.2, "dur": 11.0,
		"light": Color(1.0, 0.22, 0.1), "energy": 2.6,
		"target": Vector3(0.0, 1.4, 0.0),
		"orbit": {"r0": 2.8, "r1": 1.6, "a0": 0.5, "a1": 2.1, "h0": 1.2, "h1": 1.7},
		"cast": [
			{"m": "butcher", "h": 1.95, "fx": true, "pos": Vector3(0.0, 0.0, 0.0), "yaw": 0.4},
			{"m": "hook", "len": 3.2, "pos": Vector3(0.0, 2.4, 0.0)},
			{"m": "pig", "h": 1.25, "pos": Vector3(1.3, 1.45, -0.7)},
			{"m": "pig", "h": 1.25, "pos": Vector3(-1.2, 1.45, -0.9)},
			{"m": "bloodwall", "len": 3.5, "pos": Vector3(0.0, 0.0, -2.2)},
		],
		"subs": [
			[0.8, 2.6, "NORA", "Father wrote down everything he ever butchered."],
			[3.6, 2.6, "ABEL", "The drain behind this room was meant for runoff."],
			[6.4, 2.4, "ABEL", "Now it carries my family. The book calls it a road home."],
			[8.8, 2.0, "NORA", "He believed it. That is how the Bible got in."],
		],
	},
	"ada_note": {
		"set": "room", "height": 3.0, "dur": 10.0,
		"light": Color(0.45, 0.8, 1.0), "energy": 1.8,
		"target": Vector3(0.0, 1.0, 0.0),
		"orbit": {"r0": 2.2, "r1": 1.3, "a0": -0.6, "a1": 0.6, "h0": 1.1, "h1": 1.3},
		"cast": [
			{"m": "ghost", "h": 1.7, "fx": true, "pos": Vector3(0.0, 0.0, 0.0), "yaw": 0.0},
			{"m": "walkie", "len": 0.26, "pos": Vector3(0.7, 0.03, 0.3)},
			{"m": "flashlight", "len": 0.27, "pos": Vector3(-0.6, 0.03, 0.4)},
		],
		"subs": [
			[0.8, 2.6, "ADA", "Nora, the walkie still works when the lights fail."],
			[3.6, 2.8, "ADA", "I can hear you in the static. Find Father's key."],
			[6.8, 2.8, "ADA", "But don't leave the Bible behind. It has all of us."],
		],
	},
	"mira_letter": {
		"set": "room", "height": 3.0, "dur": 10.0,
		"light": Color(0.75, 0.55, 1.0), "energy": 1.9,
		"target": Vector3(0.0, 1.1, 0.0),
		"orbit": {"r0": 2.4, "r1": 1.5, "a0": 2.4, "a1": 3.6, "h0": 1.2, "h1": 1.4},
		"cast": [
			{"m": "woman", "h": 1.7, "pos": Vector3(0.0, 0.0, 0.0), "yaw": -0.6},
			{"m": "bible", "h": 0.3, "pos": Vector3(0.6, 0.03, 0.5)},
		],
		"subs": [
			[0.8, 2.8, "MIRA", "Abel said the corridor key would keep his room safe."],
			[3.8, 2.8, "MIRA", "I hid it beside the west hall door. He never looked."],
			[6.8, 2.6, "MIRA", "If Nora comes back, let her through."],
		],
	},
	"pearl_drawing": {
		"set": "room", "height": 3.0, "dur": 10.0,
		"light": Color(1.0, 0.5, 0.6), "energy": 1.8,
		"target": Vector3(0.0, 0.7, 0.0),
		"orbit": {"r0": 2.0, "r1": 1.0, "a0": 0.0, "a1": 1.5, "h0": 0.9, "h1": 0.5},
		"cast": [
			{"m": "doll", "h": 0.55, "pos": Vector3(0.0, 0.0, 0.0), "yaw": 0.0},
			{"m": "girl", "h": 1.68, "pos": Vector3(0.0, 0.0, -1.3), "yaw": 3.14159, "ghost": true},
			{"m": "fan", "len": 1.3, "pos": Vector3(0.0, 2.6, 0.0), "spin": true},
		],
		"subs": [
			[0.8, 2.6, "PEARL", "A girl and a doll stand under a rusty fan."],
			[3.6, 2.4, "PEARL", "Red handprints on every wall."],
			[6.2, 3.0, "PEARL", "Every window drawn as a door, so someone could leave."],
		],
	},
}

const CREDITS := [
	["THE LAST REVENGE", ""],
	["NORA", "You"],
	["ABEL CRANE", "The Butcher, Father"],
	["MIRA", "The Butcher's Wife"],
	["ADA", "The Blood-Stained Spirit, Younger Sister"],
	["LILY", "The Horror Girl, Keeper of the Key"],
	["PEARL", "The Crying Doll"],
	["THE STREET RAT", "Biter of ankles"],
	["BUILT WITH", "Pixel-Forge GLB assets and Godot 4"],
	["AUDIO", "See AUDIO_CREDITS.txt"],
	["", "Thanks for playing"],
]
