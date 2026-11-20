extends RefCounted
## Story and optional lore for THE LAST REVENGE.
## Abel Crane is the player's father and the Butcher. Mira is his wife.
## Ada, the blood-stained living-room ghost, is the player's younger sister.
## Lily is the translucent horror girl who guards the slaughterhouse key.

const CHAPTERS := [
	{
		"id": "the_hollis_house",
		"title": "The Hollis House",
		"intro": "Nora returns to the Hollis house after Ada's voice breaks through a dead walkie-talkie. Her father, Abel Crane, now hunts the rooms as the Butcher. Mira, his wife, haunts the corridor; Ada, Nora's younger sister, drifts through the vintage living room as a blood-stained spirit. A translucent girl named Lily holds the key to the slaughterhouse. Find the bat, free the spirits, take the Devil's Bible, and escape through the tunnel.",
		"obj": "Find a way into the slaughterhouse and escape with the Devil's Bible.",
	}
]

const MINI_MISSIONS := [
	{"id": "bat", "text": "Find the bloody baseball bat."},
	{"id": "walkie", "text": "Find Ada's walkie-talkie and call her with R."},
	{"id": "lily", "text": "Defeat Lily to claim Father's key."},
	{"id": "ada", "text": "Lay Ada's blood-stained spirit to rest."},
	{"id": "mira", "text": "Free Mira, the Butcher's wife, in the corridor."},
	{"id": "breaker", "text": "Restore power at the master breaker after a short circuit."},
	{"id": "mira_key", "text": "Collect Mira's corridor key beside the wing entrance."},
	{"id": "bible", "text": "Take the Devil's Bible from the slaughterhouse."},
	{"id": "escape", "text": "Return to the tunnel and escape."},
]

const LORE_PAGES := [
	{
		"id": "abel_ledger",
		"title": "Abel's Butcher Ledger",
		"text": "The old drain behind the slaughterhouse was made for the runoff. Now it carries the family's blood, and the thing in the book keeps calling it a road home."
	},
	{
		"id": "ada_note",
		"title": "Ada's Note",
		"text": "Nora, the walkie still works when the lights fail. I can hear you in the static. Find Father's key, but don't leave the Bible behind."
	},
	{
		"id": "mira_letter",
		"title": "Mira's Letter",
		"text": "Abel said the corridor key would keep his room safe. He never noticed I hid it beside the west hall door. If Nora comes back, let her through."
	},
	{
		"id": "pearl_drawing",
		"title": "Pearl's Crayon Drawing",
		"text": "A little girl and a porcelain doll stand beneath a rusted fan. Red handprints cover the walls. Every window is drawn as a door."
	}
]

static func get_chapter(id: String) -> Dictionary:
	for chapter in CHAPTERS:
		if chapter.id == id:
			return chapter
	return {}

static func get_chapter_by_index(idx: int) -> Dictionary:
	if idx >= 0 and idx < CHAPTERS.size():
		return CHAPTERS[idx]
	return {}
