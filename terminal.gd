extends SubViewport
class_name Terminal

#@onready var canvas_layer: CanvasLayer = $CanvasLayer
#@onready var interface: Control = $Interface
@onready var terminal_interface: Control = $TerminalInterface
@onready var code_entry_field: LineEdit = $TerminalInterface/HBoxContainer/VBoxContainer/CodeEntryField
@onready var code_result_label: Label = $TerminalInterface/HBoxContainer/VBoxContainer/CodeResultLabel

var enigma_success_array: Array[String] = [
	"The answer was 'Enigma'? Talk about hiding in plain sight.",
	"'Enigma' works. Honestly, I expected more from a game with 'Enigma' in the title.",
	"I guess that was pretty obvious?",
	"It's a 1 in 10, you got lucky.",
	"clever.",
	"'Enigma'? You'd think the code would put up more of a fight.",
	"You must feel like a genius.",
	"Ah, 'Enigma' ofcourse that worked, it's in the title of the game isn't it?",
	"Ofcourse you had to try it, and it worked... this time.",
	"Well this game was easy..."
]

var enigma_fail_array: Array[String] = [
	"you thought it would be that easy?",
	"It was worth a try.",
	"maybe next time!",
	"'Enigma' doesn't work. I see this game really leans into the mystery part of its name.",
	"Denied. Guess the password wasnt as self-referential as I thought.",
	"Nope, not 'Enigma' Its like the game is mocking me for taking the obvious route.",
	"...Really?",
	"I bet you thought that would work.",
	"Ironic. The password isnt 'Enigma', and yet it remains... an enigma.",
	"Not 'Enigma'? Bold move for a game literally called Exit Code Enigma.",
	"How many responses do you think there are for this?",
	"'Enigma' failed. Guess we're not as clever as we thought.",
	"Have you tried some other classics, like 'hunter2' or 'password'?",
	"Maybe you should try 'opensesame'?",
	"Maybe you should just ask for it to let you in next time?",
	"Try 'admin', you are the administrator right?",
	"Shouldn't this work?"
]

var silly_password_success_array: Array[String] = [
	"Oh, of course, it's 'password'. Why not just leave the door wide open while you're at it?",
	"'password'? Really? The cybersecurity equivalent of leaving your front door wide open.",
	"Of course, its 'password.' Truly the Picasso of lazy password choices.",
	"Ah, 'password' worked. I guess they really didnt want to make this too challenging.",
	"And just like that, 'password' unlocks the universe. Riveting security.",
	"'password' worked? I'm almost disappointed in how easy that was.",
	"Wow, 'password' actually worked. Are we in the 1990s again?",
	"'password' did the trick. Remind me to send this system a book on modern security practices.",
	"Oh, 'password' works. Guess originality wasnt on the priority list here."
]

var silly_password_fail_array: Array[String] = [
	"You though it would be 'password'? really?",
	"'password' didnt work? Even lazy systems have standards now?",
	"Not 'password'? Well, I'm fresh out of ideas.",
	"'password' failed? I feel personally betrayed by this turn of events.",
	"Oh, so 'password' is too clever for this system? Bold.",
	"Guess someone actually read the security manual. 'password' didnt work.",
	"'password' is rejected. Somewhere, an IT professional just sighed in relief.",
	"Imagine if that worked? wouldn't even have to play the game..."
]

var silly_opensesame_success_array: Array[String] = [
	"'opensesame'? Really? What's next, a magic carpet ride?",
	"'opensesame' worked? Did I just stumble into a fairy tale?",
	"Ah, the ancient art of password creation: 'opensesame' Truly timeless.",
	"'opensesame' unlocks the door. All we're missing is a treasure chest.",
	"Ofcourse, its 'opensesame' Because why bother with originality?",
	"'opensesame' worked. I feel like Ali Baba, but with fewer thieves.",
	"Well, that was anticlimactic. A magic password for a mundane system.",
	"'opensesame' The password equivalent of waving a wand and shouting 'abracadabra'",
	"'opensesame' a password so ancient, it practically creaks when you type it."
]

var silly_opensesame_fail_array: Array[String] = [
	"'opensesame' didnt work? Guess the magic words arent so magical anymore.",
	"No dice with 'opensesame' Its like the door heard me and laughed.",
	"'opensesame' failed. So much for tried-and-true classics.",
	"Denied? Guess this system prefers something more modern than ancient catchphrases.",
	"'opensesame' wasnt the key? I feel personally betrayed by this lack of whimsy.",
	"'opensesame' didnt work. A missed opportunity for nostalgic charm.",
	"Well, 'opensesame' failed. Maybe try 'password'? I'm kidding... mostly.",
	"'opensesame' doesnt cut it. Somewhere, a genie is rolling its eyes.",
	"'opensesame' didnt work. Somebody around here doesnt appreciate classic literature."
]

var silly_hunter2_success_array: Array[String] = [
	"'hunter2'? Well, memes do stand the test of time.",
	"Oh, 'hunter2' actually worked. Somebody's been lurking in forums since 2004.",
	"'hunter2' unlocked it. The internet jokes live on!",
	"Of course, its 'hunter2' The password of legends and meme-makers alike.",
	"Wow, 'hunter2' worked. Proof that the internet never forgets.",
	"'hunter2' Because why not use a meme as a security measure?",
	"And just like that, 'hunter2' cracks the code. Somebody is a bit too online.",
	"'hunter2'? Sure, why not. Lets let memes run our security systems.",
	"'hunter2'? I guess it is a meme come to life."
]

var silly_hunter2_fail_array: Array[String] = [
	"'hunter2' didnt work? A betrayal of meme culture everywhere.",
	"Oh, so 'hunter2' isnt the secret sauce. Guess Ill try ‘hunter3.",
	"Oh, so 'hunter2' isnt good enough for this system? Bold move.",
	"Not 'hunter2'? Looks like the system is too cool for old-school memes.",
	"'hunter2' didnt work? Feels like the internet just lost a little bit of soul.",
	"Well, 'hunter2' failed. I guess well never understand the real joke.",
	"'hunter2' rejected. This system clearly doesnt appreciate meme history.",
	"No luck with 'hunter2' Guess its back to trolling forums for clues."
]

var silly_letmein_success_array: Array[String] = [
	"fine, go ahead... sheesh.",
	"'letmein'? Well, that was polite of you. And shockingly effective.",
	"Ah, 'letmein' worked. The password equivalent of knocking on a door and hoping for the best.",
	"'letmein'? Sure, why not. Hospitality at its finest.",
	"And just like that, 'letmein' swings the door wide open. A password with manners!",
	"'letmein' worked. At least the system appreciated your directness.",
	"Of course, its 'letmein' Because whats security without a bit of desperation?",
	"'letmein' opened the door. Somewhere, an IT professional just fainted.",
	"Well, 'letmein' was the key. Subtlety clearly isnt this systems strength.",
	"'letmein'? Talk about taking the path of least resistance.",
	"'letmein' worked. It's almost like the system wanted you to succeed."
]

var silly_letmein_fail_array: Array[String] = [
	"I'm sorry, Dave. I'm afraid I can't do that.",
	"Oh, so 'letmein' isnt good enough? What is this, a velvet rope nightclub?",
	"'letmein' failed. Rude.",
	"Denied? Guess this system is immune to polite requests.",
	"'letmein' wasnt the answer? I thought we we're going for honesty here.",
	"No luck with 'letmein' Maybe try knocking harder?",
	"'letmein' didnt work. A truly missed opportunity for charm-based security.",
	"Not 'letmein'? I guess groveling is the next step."
]

var silly_admin_success_array: Array[String] = [
	"'admin'? Well, that was shockingly easy. Who even needs passwords at this point?",
	"Oh, 'admin' worked. Lets just leave the keys under the doormat while we're at it.",
	"'admin'? Bold choice for a password, truly revolutionary.",
	"Of course, its 'admin' Why complicate things when simplicity reigns supreme?",
	"'admin' unlocked the door. Did I just hack into a 1990s router?",
	"Oh, 'admin' worked. I feel like a world-class hacker now.",
	"'admin' the pinnacle of creativity and security in one package.",
	"Well, that was easy. 'admin' was the password. Who needs encryption anyway?",
	"'admin' cracked it? High-tech security at its finest, clearly.",
	"'admin' worked. Truly, the password of champions... or people who stopped caring."
]

var silly_admin_fail_array: Array[String] = [
	"'admin' didnt work? Wow, even the basics are too good for this system.",
	"Oh, so 'admin' isnt the key? Fancy system youve got here.",
	"'admin' rejected. Someone finally read a security handbook.",
	"Not 'admin'? Guess we're dealing with next-level password innovation here.",
	"'admin' failed. I'm shocked. Truly shocked.",
	"No dice with 'admin' Maybe its time to try 'admin1' for extra spice.",
	"'admin' didnt work. Looks like theyve graduated from the 'default passwords' school of thought.",
	"Denied? This system doesnt appreciate simplicity, apparently.",
	"Someone clearly decided to change the default password...",
	"'admin' isnt the password? Who knew we'd encounter such complexity today.",
	"'admin' failed. Whats next, 'admin123'? Surely they didnt try that hard."
]

var generic_fail_array: Array[String] = [
	"did you really just type '%s'? go look for some clues...",
	"nothing happens.",
	"shocking that this didn't work.",
	"no it's not '%s'...",
	"try again, maybe it'll work? probably not though.",
	"why are you still here if you don't have the password?",
	"there are probably some sticky notes out there that'll help you.",
	"I'm with you, '%s' should have worked...",
	"are you sure that you typed that correctly?",
	"why would you type '%s'???",
	"try '%s', I'm sure it'll work.",
	"maybe try some pop-culture passwords?",
]

var hint_array: Array[String] = [
	"try 'letmein'",
	"try 'admin'",
	"try 'password'",
	"try 'opensesame'",
	"try 'hunter2'",
	"try 'enigma', you know like in the title of the game?",
	"what if you had a map?",
	"sure would be useful if you had xray vision or something.",
	"I wonder if there are some hidden codes?",
	"is it possible to teleport?",
	"there's a manager roaming around?"
]

var exit_open_array: Array[String] = [
	"it's already open... leave.",
	"Exit is open.",
	"You're free to leave.",
	"Make like a tree and leave.",
	"It's open, but thanks for double-checking!",
	"Congratulations! You’ve unlocked the unlocked!",
	"Open sesame... oh, wait, it’s already sesame'd.",
	"Access granted... but wasn't it already?",
	"Why try to unlock the freedom you already have?",
	"System override not needed, door's open, friend!",
	"The system approves your redundant efforts.",
	"Pro tip: Open things don’t need opening."
]

func _ready() -> void:
	code_entry_field.text_changed.connect(_on_code_entry_field_text_changed)
	code_entry_field.text_submitted.connect(_on_code_entry_field_text_submitted)

#func show_terminal_view() -> void:
	#if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#canvas_layer.visible = true
	#interface.visible = true
#
#func hide_terminal_view() -> void:
	#if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#canvas_layer.visible = false
	#interface.visible = false

func _on_code_entry_field_text_changed(new_text: String) -> void:
	var caret_pos: int = code_entry_field.caret_column
	code_entry_field.text = new_text.to_upper()
	code_entry_field.caret_column = caret_pos

func _on_code_entry_field_text_submitted(new_text: String) -> void:
	if new_text == "XRAY":
		GameData.xray = !GameData.xray
		var xray_string: String
		if GameData.xray:
			xray_string = "Enabled"
		else:
			xray_string = "Disabled"
		code_result_label.text = "x-ray " + xray_string
		code_entry_field.clear()
		return
	if new_text == "TELEPORT":
		if GameData.exit.using_terminal:
			GameData.exit.toggle_terminal_usage()
		var cell_size: float = GameData.map.cell_size
		var cell_pos: Vector2i = GameData.map.find_random_empty_cell().pos * cell_size
		var teleport_pos: Vector3 = Vector3(cell_pos.x, 0.0, cell_pos.y)
		GameData.player.global_position = teleport_pos
		code_result_label.text = "you got teleported"
		code_entry_field.deselect()
		code_entry_field.release_focus()
		code_entry_field.clear()
		return
	if new_text == "MAP":
		code_result_label.text = "a map? there might be [o]ne"
		code_entry_field.clear()
		return
	if new_text == "HINT" or new_text == "HELP" or new_text == "TIP" or new_text == "CHEAT" or new_text == "CHEATS" or new_text == "CODE" or new_text == "HIDDEN" or new_text == "SECRET" or new_text == "SECRETS":
		var hint_text: String = hint_array[randi_range(0, hint_array.size() - 1)]
		code_result_label.text = hint_text
		return
	if new_text == "MANAGER":
		match GameData.office_manager.manager_type:
			OfficeManager.ManagerType.EVIL:
				code_result_label.text = "the manager is evil."
			OfficeManager.ManagerType.GOOD:
				code_result_label.text = "the manager is good."
			OfficeManager.ManagerType.AMBIVALENT:
				code_result_label.text = "the manager is ambivalent, who knows what he'll do."
		return
	if GameData.exit.is_open:
		var exit_open_text: String = exit_open_array[randi_range(0, exit_open_array.size() - 1)]
		code_result_label.text = exit_open_text
	else:
		if new_text == GameData.exit_code or new_text == "DEVPASS":
			code_result_label.text = "exit opened."
			GameData.exit.open_exit()
		elif new_text == "ENIGMA":
			if GameData.enigma_outcome == 1:
				var enigma_success_text: String = enigma_success_array[randi_range(0, enigma_success_array.size() - 1)]
				code_result_label.text = enigma_success_text
				GameData.exit.open_exit()
			else:
				var enigma_fail_text: String = enigma_fail_array[randi_range(0, enigma_fail_array.size() - 1)]
				code_result_label.text = enigma_fail_text
		elif new_text == "PASSWORD":
			if GameData.silly_result:
				var pass_success_text: String = silly_password_success_array[randi_range(0, silly_password_success_array.size() - 1)]
				code_result_label.text = pass_success_text
				GameData.exit.open_exit()
				GameData.used_silly = true
			else:
				var pass_fail_text: String = silly_password_fail_array[randi_range(0, silly_password_fail_array.size() - 1)]
				code_result_label.text = pass_fail_text
		elif new_text == "OPENSESAME":
			if GameData.silly_result:
				var opensesame_success_text: String = silly_opensesame_success_array[randi_range(0, silly_opensesame_success_array.size() - 1)]
				code_result_label.text = opensesame_success_text
				GameData.exit.open_exit()
				GameData.used_silly = true
			else:
				var opensesame_fail_text: String = silly_opensesame_fail_array[randi_range(0, silly_opensesame_fail_array.size() - 1)]
				code_result_label.text = opensesame_fail_text
		elif new_text == "HUNTER2":
			if GameData.silly_result:
				var hunter2_success_text: String = silly_hunter2_success_array[randi_range(0, silly_hunter2_success_array.size() - 1)]
				code_result_label.text = hunter2_success_text
				GameData.exit.open_exit()
				GameData.used_silly = true
			else:
				var hunter2_fail_text: String = silly_hunter2_fail_array[randi_range(0, silly_hunter2_fail_array.size() - 1)]
				code_result_label.text = hunter2_fail_text
		elif new_text == "LETMEIN":
			if GameData.silly_result:
				var letmein_success_text: String = silly_letmein_success_array[randi_range(0, silly_letmein_success_array.size() - 1)]
				code_result_label.text = letmein_success_text
				GameData.exit.open_exit()
				GameData.used_silly = true
			else:
				var letmein_fail_text: String = silly_letmein_fail_array[randi_range(0, silly_letmein_fail_array.size() - 1)]
				code_result_label.text = letmein_fail_text
		elif new_text == "ADMIN":
			if GameData.silly_result:
				var admin_success_text: String = silly_admin_success_array[randi_range(0, silly_admin_success_array.size() - 1)]
				code_result_label.text = admin_success_text
				GameData.exit.open_exit()
				GameData.used_silly = true
			else:
				var admin_fail_text: String = silly_admin_fail_array[randi_range(0, silly_admin_fail_array.size() - 1)]
				code_result_label.text = admin_fail_text
		else:
			var fail_array: Array[String] = generic_fail_array + hint_array
			var generic_fail_text: String = fail_array[randi_range(0, fail_array.size() - 1)]
			if "%s" in generic_fail_text:
				var formatted_text: String = generic_fail_text % new_text
				code_result_label.text = formatted_text
			else:
				code_result_label.text = generic_fail_text
	code_entry_field.clear()
