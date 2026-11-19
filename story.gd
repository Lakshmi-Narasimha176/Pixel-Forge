extends RefCounted
## THE LAST REVENGE - story, chapters, lore pages and radio lines (data only).
##
## Nora Hollis comes home to the family farm after a dead radio calls her name. Twenty years ago Abel Crane,
## the family's butcher, murdered the Hollis family to bind a spirit to the Devil's Bible. His victims are still
## in the house: her sister MIRA (the Woman), her little sister LILY (the Girl, possessed), her mother ADA (the Ghost),
## and Lily's doll PEARL, who sees everything. Nora has one night to take the Bible, free them, and burn it.

const CHAPTERS := [
	{
		"id": "swamp", "type": "walk", "title": "PROLOGUE", "sub": "The Swamp Road",
		"intro": "Nora Hollis, 11:48 PM.\n\nThe radio on your belt has been dead for twenty years. Tonight it said your name.\n\nThe farmhouse waits at the end of the swamp road, exactly where you left it. The lights are on.\n\nWalk to the house. Do not stray from the road.",
		"obj": "Walk to the Hollis farmhouse", "model": "swamp", "length": 95.0,
		"fog": 0.045, "ambient": 0.5, "tint": Color(0.05, 0.07, 0.1), "butcher": false, "chars": ["rat", "ghost"],
		"radio": [[3.0, "MIRA (radio): ...Nora? Is that you?"], [20.0, "MIRA (radio): He keeps the key where the family used to rest. Be quiet inside."]],
	},
	{
		"id": "house", "type": "house", "title": "CHAPTER 1", "sub": "The Hollis House",
		"intro": "The front door locks behind you.\n\nEvery room is exactly as it was the night of the killings. The table is still set for six.\n\nThe Butcher sleeps in the slaughter room. Find the brass key, take the Devil's Bible from his block, and get out before he wakes.\n\nHe hears footsteps. He sees light. Crouch (C) to move quietly. Throw the bat (T) to pull him away.",
		"obj": "Find the brass key", "fog": 0.035, "ambient": 0.55, "tint": Color(0.05, 0.055, 0.07), "butcher": true,
		"chars": ["girl", "doll", "ghost", "woman", "rat"],
		"radio": [[4.0, "MIRA (radio): Crouch. He cannot hear you if you crouch."], [60.0, "MIRA (radio): The light hurts him. Do not let it go out."]],
	},
	{
		"id": "cellar", "type": "collect", "title": "CHAPTER 2", "sub": "The Cellar",
		"intro": "The floor gives way.\n\nYou wake in the cellar under the house. The lift back up is dead. Three fuses were pulled from its panel and hidden in the tunnels, one by one, by someone who wanted you to find them.\n\nCollect all three fuses. The Butcher is awake now, and he is not patient.",
		"obj": "Collect the lift fuses", "kind": "fuse", "need": 3, "label": "Take the fuse", "model": "corridor", "length": 19.0,
		"fog": 0.06, "ambient": 0.35, "tint": Color(0.04, 0.05, 0.05), "butcher": true, "chars": ["girl", "doll", "woman", "rat"],
		"radio": [[5.0, "MIRA (radio): Lily is down here. Don't turn your back on her."], [45.0, "MIRA (radio): Two more. I can feel them pulling at the walls."]],
	},
	{
		"id": "parlor", "type": "collect", "title": "CHAPTER 3", "sub": "The Memory Wing",
		"intro": "The lift opens on a wing of the house that was never on any plan.\n\nOld furniture. Old photographs. Every photo is a moment from the night the family died, and every one holds a piece of the person who is trapped inside.\n\nFind all four photographs. Mira will show you where to look.",
		"obj": "Find the family photographs", "kind": "photo", "need": 4, "label": "Take the photograph", "model": "parlor", "length": 0.0,
		"fog": 0.03, "ambient": 0.6, "tint": Color(0.07, 0.05, 0.04), "butcher": true, "chars": ["girl", "doll", "woman", "ghost", "rat"], "guide": true,
		"radio": [[5.0, "MIRA (radio): Watch for me. When I appear, I am standing near one."], [50.0, "ADA (whisper): ...my babies..."]],
	},
	{
		"id": "ritual", "type": "collect", "title": "CHAPTER 4", "sub": "The Sickroom",
		"intro": "A hidden door behind the parlor wardrobe reveals the original sickroom.\n\nThe Devil's Bible rests on an altar of bone and rusted iron. Abel Crane bound Lily's soul to this book. To break the seal, you must gather three ritual offerings: the Silver Cross, the Salted Thread, and the Child's Locket.\n\nPearl's eyes turn with every step you take. Do not look away when she watches.",
		"obj": "Gather the ritual offerings", "kind": "relic", "need": 3, "label": "Take the offering", "model": "room", "length": 0.0,
		"fog": 0.04, "ambient": 0.5, "tint": Color(0.06, 0.04, 0.05), "butcher": true, "chars": ["girl", "doll", "ghost", "rat"],
		"radio": [[4.0, "MIRA (radio): Pearl sees through the walls. Keep the light on her."], [40.0, "LILY (whisper): Don't let him cut me again..."]],
	},
	{
		"id": "soviet", "type": "puzzle", "title": "CHAPTER 5", "sub": "The Interrogation Chamber",
		"intro": "The cold stone turns to Soviet-era reinforced concrete. An old interrogation station built deep beneath the estate.\n\nThe wall clock is frozen at 12:00. Abel's journal says the ritual was completed at 3:33—the Witching Hour. Set the clock hands to break the steel vault lock.\n\nThe Butcher is pounding against the iron bulkhead. Time is running out.",
		"obj": "Solve the clock mechanism", "kind": "clock", "need": 1, "label": "Turn clock hand", "model": "soviet", "length": 0.0,
		"fog": 0.035, "ambient": 0.45, "tint": Color(0.05, 0.06, 0.05), "butcher": true, "chars": ["woman", "doll", "mask", "rat"],
		"radio": [[4.0, "MIRA (radio): Three thirty-three. That was the time the screaming stopped."], [35.0, "MIRA (radio): Turn the brass dial. Quickly!"]],
	},
	{
		"id": "tunnel", "type": "escape", "title": "CHAPTER 6", "sub": "The Collapse",
		"intro": "The blast door swings open onto a collapsing underground drainage canal.\n\nAbel Crane has broken through. Behind him, the shadows of the bound spirits writhe in fury. There is no stealth now.\n\nSprint down the tunnel toward the surface access shaft. Do not look back.",
		"obj": "Escape through the collapsing tunnel", "model": "tunnel", "length": 58.0,
		"fog": 0.05, "ambient": 0.4, "tint": Color(0.08, 0.03, 0.03), "butcher": true, "chars": ["butcher", "ghost", "mask"],
		"radio": [[2.0, "MIRA (radio): RUN, NORA! HE IS RIGHT BEHIND YOU!"], [25.0, "ADA (screaming): RUN!"]],
	},
	{
		"id": "pyre", "type": "boss", "title": "CHAPTER 7", "sub": "The Final Pyre",
		"intro": "You burst out into the storm at the edge of the Hollis farmyard.\n\nThe pyre is prepared near the old outhouse. Place the Devil's Bible on the flames to break the binding forever.\n\nAbel Crane emerges from the darkness with his butcher's cleaver for one final reckoning. Keep the light on him. Cleanse the Hollis name.",
		"obj": "Burn the Devil's Bible at the pyre", "model": "farm", "length": 0.0,
		"fog": 0.04, "ambient": 0.55, "tint": Color(0.06, 0.05, 0.07), "butcher": true, "chars": ["butcher", "woman", "ghost", "girl", "doll"],
		"radio": [[3.0, "MIRA (radio): Throw the Bible into the fire, Nora! Free us!"], [20.0, "MIRA (radio): He's burning! It's over..."]],
	},
]

const LORE_PAGES := [
	{
		"id": "page_01",
		"title": "Abel's Ledger - Entry 1",
		"text": "The blood of the innocent is required to open the binding. The father went first. He fought like an ox, but the cleaver does not negotiate."
	},
	{
		"id": "page_02",
		"title": "Torn Diary Page - Mira",
		"text": "Nora was sent away to school in the city. If she were here, she would tell father that Abel is watching us from the barn. His eyes are dead."
	},
	{
		"id": "page_03",
		"title": "The Butcher's Covenant",
		"text": "To bind a soul to parchment: three lives for the seal, one child for the voice. The Devil's Bible demands absolute obedience. Fire alone unweaves the thread."
	},
	{
		"id": "page_04",
		"title": "Lily's Drawing",
		"text": "A crayon sketch of a girl holding a doll named Pearl. Behind them stands a tall man in a blood-soaked leather apron holding a butcher's hook."
	},
	{
		"id": "page_05",
		"title": "Ada's Final Note",
		"text": "Nora, if you ever come back to this house, do not search for our bodies. We are in the wood, in the walls, in the book. Burn the farm down."
	}
]

static func get_chapter(id: String) -> Dictionary:
	for ch in CHAPTERS:
		if ch.id == id:
			return ch
	return {}

static func get_chapter_by_index(idx: int) -> Dictionary:
	if idx >= 0 and idx < CHAPTERS.size():
		return CHAPTERS[idx]
	return {}
