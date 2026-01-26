/obj/effect/proc_holder/spell/self/library
	name = "Compendium of Arcane Arts"
	desc = "Summon the knowledge of the arcane library to learn new spells."
	school = "transmutation"
	overlay_state = "book1"
	chargedrain = 0
	chargetime = 0
	var/hide_unavailable = FALSE

/obj/effect/proc_holder/spell/self/library/cast(list/targets, mob/user = usr)
	. = ..()
	if(!GLOB.learnable_spells)
		to_chat(user, span_warning("The void is silent... (Global spell list is missing)"))
		return
	if(!user.mind)
		return
	
	var/html = generate_spell_html(user)
	user << browse(html, "window=grimoire;size=700x600;can_close=1")

/obj/effect/proc_holder/spell/self/library/Topic(href, href_list)
	if(!usr || usr.stat != 0 || !usr.mind) return

	var/mob/living/user = usr

	if(href_list["action"] == "toggle_filter")
		hide_unavailable = !hide_unavailable
		var/html = generate_spell_html(user)
		user << browse(html, "window=grimoire;size=700x600;can_close=1")
		return

	if(href_list["action"] == "learn")
		var/path_text = href_list["path"]
		var/spell_path = text2path(path_text)
		
		if(!ispath(spell_path)) return

		if(!(spell_path in GLOB.learnable_spells))
			return 

		var/status = can_learn_spell(user, spell_path, check_cost = TRUE)
		
		switch(status)
			if("known")
				to_chat(user, span_warning("You already know this spell!"))
				return
			if("evil")
				to_chat(user, span_warning("Your soul is not dark enough for this art."))
				return
			if("tier")
				to_chat(user, span_warning("You lack the arcane training for this spell."))
				return
			if("cost")
				var/obj/effect/proc_holder/spell/S = spell_path
				var/cost = initial(S.cost)
				var/points = user.mind.spell_points - user.mind.used_spell_points
				to_chat(user, span_warning("Not enough spell points! Need [cost], have [points]."))
				return
		
		var/obj/effect/proc_holder/spell/S_Type = spell_path
		var/cost = initial(S_Type.cost)
		var/spell_name = initial(S_Type.name)

		user.mind.used_spell_points += cost
		var/obj/effect/proc_holder/spell/new_spell = new spell_path()
		new_spell.refundable = TRUE 
		user.mind.AddSpell(new_spell)
		addtimer(CALLBACK(user.mind, TYPE_PROC_REF(/datum/mind, check_learnspell)), 2 SECONDS)

		to_chat(user, span_notice("You have woven <b>[spell_name]</b> into your mind!"))
		playsound(user, 'sound/magic/lightning.ogg', 50, 1)
		
		var/html = generate_spell_html(user)
		user << browse(html, "window=grimoire;size=700x600;can_close=1")


/obj/effect/proc_holder/spell/self/library/proc/can_learn_spell(mob/user, spell_type, check_cost = TRUE)
	var/obj/effect/proc_holder/spell/S = spell_type
	
	for(var/obj/effect/proc_holder/spell/known in user.mind.spell_list)
		if(known.type == spell_type) return "known"


	if(initial(S.zizo_spell) > get_user_evilness(user)) return "evil"
		

	if(initial(S.spell_tier) > get_user_spell_tier(user)) return "tier"
		

	if(check_cost)
		var/points_left = user.mind.spell_points - user.mind.used_spell_points
		if(initial(S.cost) > points_left) return "cost"
            
	return "ok"

/obj/effect/proc_holder/spell/self/library/proc/generate_spell_html(mob/living/user)
	var/points_avail = 0
	if(user.mind)
		points_avail = user.mind.spell_points - user.mind.used_spell_points

	user << browse_rsc('html/KettleParallaxBG.png', "bg_texture.png")

	var/list/sorted_spells = list()
	for(var/spell_type in GLOB.learnable_spells)
		var/obj/effect/proc_holder/spell/S = spell_type
		sorted_spells["[initial(S.name)]_[spell_type]"] = spell_type
	sorted_spells = sortList(sorted_spells)

	var/list/sent_icons_cache = list() 

	var/cards_html = ""
	
	for(var/key in sorted_spells)
		var/spell_type = sorted_spells[key]
		
		var/status = can_learn_spell(user, spell_type, check_cost = FALSE)

		if(status == "tier" || status == "evil")
			continue
		
		var/can_afford = (can_learn_spell(user, spell_type, check_cost = TRUE) != "cost")
		var/is_known = (status == "known")
		
		if(hide_unavailable && !is_known && !can_afford)
			continue

		var/obj/effect/proc_holder/spell/S_Type = spell_type
		var/s_name = initial(S_Type.name)
		var/s_desc = initial(S_Type.desc)
		var/s_cost = initial(S_Type.cost)
		var/s_tier = initial(S_Type.spell_tier)
		
		var/icon_file = initial(S_Type.action_icon)
		var/icon_state_str = initial(S_Type.overlay_state)
		if(!icon_state_str) icon_state_str = initial(S_Type.action_icon_state)

		var/img_tag = ""
		if(icon_file && icon_state_str)
			var/img_filename = "[icon_state_str].png"
			
			if(!sent_icons_cache[img_filename])
				try
					var/icon/I = icon(icon_file, icon_state_str)
					user << browse_rsc(I, img_filename)
					sent_icons_cache[img_filename] = TRUE
					img_tag = "<img src='[img_filename]' class='spell-icon'>"
				catch
					img_tag = "<div class='spell-icon-placeholder'>?</div>"
			else
				img_tag = "<img src='[img_filename]' class='spell-icon'>"
		else
			img_tag = "<div class='spell-icon-placeholder'>?</div>"

		var/btn_html = ""
		var/card_class = "card"
		
		if(is_known)
			card_class += " known"
			btn_html = "<div class='btn disabled'>LEARNED</div>"
		else
			if(can_afford)
				btn_html = "<a href='?src=\ref[src];action=learn;path=[spell_type]' class='btn buy'>WEAVE ([s_cost])</a>"
			else
				card_class += " locked"
				btn_html = "<div class='btn disabled'>[s_cost] PT</div>"

		cards_html += {"
			<div class='[card_class]' title='[s_desc]'>
				<div class='header'>
					<span class='title'>[s_name]</span>
					<span class='badge tier'>T[s_tier]</span>
				</div>
				<div class='icon-container'>
					[img_tag]
				</div>
				<div class='desc'>[s_desc]</div>
				<div class='footer'>
					[btn_html]
				</div>
			</div>
		"}

	var/filter_text = hide_unavailable ? "SHOW ALL SPELLS" : "HIDE UNAVAILABLE"
	var/filter_class = hide_unavailable ? "filter-btn active" : "filter-btn"

	var/html = {"
	<html>
	<head>
		<meta http-equiv='X-UA-Compatible' content='IE=edge'>
		<style>
			/* ... (стили те же, сократил для краткости) ... */
			body { background-image: url('bg_texture.png'); background-color: #1a1a1d; background-attachment: fixed; background-size: cover; color: #c5c6c7; font-family: 'Verdana', sans-serif; padding: 15px; margin: 0; }
			h2 { color: #66fcf1; text-align: center; border-bottom: 2px solid #45a29e; padding-bottom: 5px; margin-top: 0; text-shadow: 2px 2px 4px #000; }
			.status-bar { background: rgba(11, 12, 16, 0.9); padding: 8px; display: flex; justify-content: space-between; align-items: center; color: #45a29e; border-radius: 5px; margin-bottom: 15px; border: 1px solid #1f2833; box-shadow: 0 4px 6px rgba(0,0,0,0.5); }
			.status-text { font-weight: bold; }
			.filter-btn { background-color: #1f2833; color: #c5c6c7; text-decoration: none; padding: 4px 10px; border-radius: 3px; font-size: 11px; border: 1px solid #45a29e; transition: all 0.2s; }
			.filter-btn:hover { background-color: #45a29e; color: #0b0c10; }
			.filter-btn.active { background-color: #45a29e; color: #0b0c10; font-weight: bold; box-shadow: 0 0 5px #45a29e; }
			.grid-container { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 8px; }
			.card { background-color: rgba(31, 40, 51, 0.95); border: 1px solid #45a29e; border-radius: 4px; padding: 6px; display: flex; flex-direction: column; min-height: 150px; transition: all 0.2s ease; }
			.card:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(102, 252, 241, 0.4); }
			.card.known { border-color: #4caf50; background-color: rgba(27, 38, 27, 0.95); }
			.card.locked { border-color: #f44336; opacity: 0.8; }
			.header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
			.title { font-weight: bold; color: #fff; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 90px; }
			.badge { font-size: 9px; padding: 1px 4px; border-radius: 3px; font-weight: bold; background: #45a29e; color: #0b0c10; }
			.icon-container { display: flex; justify-content: center; align-items: center; height: 42px; margin: 4px 0; background: rgba(0,0,0,0.3); border-radius: 4px; border: 1px solid #333; }
			.spell-icon { width: 32px; height: 32px; image-rendering: pixelated; }
			.spell-icon-placeholder { font-size: 24px; color: #555; }
			.desc { font-size: 10px; color: #aab; flex-grow: 1; margin-bottom: 6px; line-height: 1.2; overflow: hidden; }
			.footer { margin-top: auto; }
			.btn { display: block; text-align: center; padding: 4px; border-radius: 3px; text-decoration: none; font-weight: bold; font-size: 10px; }
			.buy { background-color: #45a29e; color: #0b0c10; transition: background 0.2s; }
			.buy:hover { background-color: #66fcf1; }
			.disabled { background-color: #2c3038; color: #555; cursor: default; }
			.known .disabled { color: #4caf50; background: transparent; border: 1px solid #4caf50; }
		</style>
	</head>
	<body>
		<h2>Grimoire of Spells</h2>
		<div class="status-bar">
			<span class="status-text">MAGICAL ENERGY: [points_avail]</span>
			<a href='?src=\ref[src];action=toggle_filter' class='[filter_class]'>[filter_text]</a>
		</div>
		<div class="grid-container">[cards_html]</div>
	</body>
	</html>
	"}
	
	return html
