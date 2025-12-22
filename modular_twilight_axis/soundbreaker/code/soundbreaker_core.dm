/datum/soundbreaker_combo_tracker
	var/mob/living/owner
	var/list/history

/datum/soundbreaker_combo_tracker/New(mob/living/L)
	. = ..()
	owner = L
	history = list()

/datum/soundbreaker_combo_tracker/proc/register_hit(note_id, mob/living/target)
	if(!owner)
		return
	if(!history)
		history = list()

	var/entry = list(
		"note" = note_id,
		"time" = world.time,
		"target" = target,
	)

	history += list(entry)
	cleanup_history()
	check_combos()

/datum/soundbreaker_combo_tracker/proc/cleanup_history()
	if(!history || !history.len)
		return

	var/current_time = world.time
	var/list/new_history = list()

	for(var/i in 1 to history.len)
		var/entry = history[i]
		if(!islist(entry))
			continue
		var/when = entry["time"]
		if(isnull(when))
			continue
		if(current_time - when <= SB_COMBO_WINDOW)
			new_history += list(entry)

	while(new_history.len > SB_MAX_HISTORY)
		new_history.Cut(1, 2)

	history = new_history

/datum/soundbreaker_combo_tracker/proc/check_combos()
	if(!history || !history.len)
		return

	var/list/notes = list()
	var/mob/living/last_target

	for(var/i in 1 to history.len)
		var/entry = history[i]
		if(!islist(entry))
			continue
		notes += entry["note"]
		last_target = entry["target"]

	if(!last_target)
		return

	// 10) Overture  -> 62114
	if(soundbreaker_match_suffix(notes, list(6, 2, 1, 1, 4)))
		soundbreaker_combo_overture(owner, last_target)
		return

	// 9) Crescendo Finale -> 13211
	if(soundbreaker_match_suffix(notes, list(1, 3, 2, 1, 1)))
		soundbreaker_combo_crescendo(owner, last_target)
		return

	// 11) Blade Dancer -> 12155
	if(soundbreaker_match_suffix(notes, list(1, 2, 1, 5, 5)))
		soundbreaker_combo_blade_dancer(owner, last_target)
		return

	// 12) Harmonic Burst -> 213
	if(soundbreaker_match_suffix(notes, list(2, 1, 3)))
		soundbreaker_combo_harmonic_burst(owner, last_target)
		return

	// 5) Bass Drop -> 4112 (two-stage)
	if(soundbreaker_match_suffix(notes, list(4, 1, 1, 2)))
		soundbreaker_combo_bass_drop(owner, last_target)
		return

	// 6) Reverb Cut -> 1423 (old wave/knockback wall)
	if(soundbreaker_match_suffix(notes, list(1, 4, 2, 3)))
		soundbreaker_combo_reverb_cut(owner, last_target)
		return

	// 7) Syncopation Lock -> 1216 (immob + offbalance, conditional knockdown)
	if(soundbreaker_match_suffix(notes, list(1, 2, 1, 6)))
		soundbreaker_combo_syncopation(owner, last_target)
		return

	// 8) Ritmo -> 364 (slow 5s + 60% dmg)
	if(soundbreaker_match_suffix(notes, list(3, 6, 4)))
		soundbreaker_combo_ritmo(owner, last_target)
		return

	// 1) Echo Beat -> 111 (150% dmg + short slow)
	if(soundbreaker_match_suffix(notes, list(1, 1, 1)))
		soundbreaker_combo_echo_beat(owner, last_target)
		return

	// 2) Tempo Flick -> 62 (projectile "spit", slow, no pull/immob)
	if(soundbreaker_match_suffix(notes, list(6, 2)))
		soundbreaker_combo_tempo_flick(owner, last_target)
		return

	// 3) Snapback -> 515 (30% dmg + immob 2s)
	if(soundbreaker_match_suffix(notes, list(5, 1, 5)))
		soundbreaker_combo_snapback(owner, last_target)
		return

	// 4) Crossfade -> 51146 (30% dmg + stun 2s)
	if(soundbreaker_match_suffix(notes, list(5, 1, 1, 4, 6)))
		soundbreaker_combo_crossfade(owner, last_target)
		return

/// Глобалка для регистрации удара ноты
/proc/soundbreaker_on_hit(mob/living/user, mob/living/target, note_id)
	if(!user || !note_id)
		return

	if(!soundbreaker_has_music(user))
		return

	var/datum/soundbreaker_combo_tracker/T = soundbreaker_get_combo_tracker(user)
	if(T && target)
		T.register_hit(note_id, target)

	soundbreaker_show_note_icon(user, note_id)
	soundbreaker_add_combo_stack(user)

/// Получить/создать трекер на мобе
/proc/soundbreaker_get_combo_tracker(mob/living/user)
	if(!user)
		return null
	if(!user.soundbreaker_combo)
		user.soundbreaker_combo = new /datum/soundbreaker_combo_tracker(user)
	return user.soundbreaker_combo

/// Проверка, совпадает ли хвост списка нот с паттерном
/proc/soundbreaker_match_suffix(list/notes, list/pattern)
	if(!notes || !pattern)
		return FALSE
	if(pattern.len > notes.len)
		return FALSE

	var/base = notes.len - pattern.len
	for(var/i in 1 to pattern.len)
		if(notes[base + i] != pattern[i])
			return FALSE
	return TRUE

/// Стак-комбо на владельце
/proc/soundbreaker_add_combo_stack(mob/living/user)
	if(!user)
		return
	user.apply_status_effect(/datum/status_effect/buff/soundbreaker_combo)

/proc/soundbreaker_get_combo_stacks(mob/living/user)
	if(!user)
		return 0
	var/datum/status_effect/buff/soundbreaker_combo/C = user.has_status_effect(/datum/status_effect/buff/soundbreaker_combo)
	if(!C)
		return 0
	return C.stacks

/// Проверка, играет ли музыка
/proc/soundbreaker_has_music(mob/living/user)
	if(!user)
		return FALSE

	if(user.has_status_effect(/datum/status_effect/buff/playing_music))
		return TRUE

	return FALSE

/// Вспомогательные проки контроля / доп-эффектов
/proc/sb_safe_offbalance(mob/living/L, duration)
	if(!L)
		return
	L.OffBalance(duration)

/proc/sb_safe_slow(mob/living/L, amount)
	if(!L)
		return
	L.Slowdown(amount)

/proc/sb_small_bleed(mob/living/L, times)
	if(!L)
		return
	for(var/i in 1 to times)
		L.apply_damage(5, BRUTE)

/// Нокбэк на tiles тайлов от user
/proc/soundbreaker_knockback(mob/living/user, mob/living/target, tiles)
	if(!user || !target)
		return
	var/dir = get_dir(user, target)
	var/turf/start = get_turf(target)
	var/turf/dest = get_ranged_target_turf(start, dir, tiles)
	if(dest)
		target.safe_throw_at(dest, tiles, 1, user, force = MOVE_FORCE_NORMAL)

/// Биндинг bclass → armor damage flag
/proc/soundbreaker_get_damage_flag(bclass, damage_type)
	switch(bclass)
		if(BCLASS_BLUNT, BCLASS_SMASH, BCLASS_TWIST, BCLASS_PUNCH)
			return "blunt"
		if(BCLASS_CHOP, BCLASS_CUT, BCLASS_LASHING, BCLASS_PUNISH)
			return "slash"
		if(BCLASS_PICK, BCLASS_STAB, BCLASS_PIERCE)
			return "stab"

	switch(damage_type)
		if(BRUTE)
			return "blunt"
		if(BURN)
			return "fire"
		if(TOX)
			return "bio"
		if(OXY)
			return "oxy"

	return "blunt"

/// Главный хелпер нанесения урона
/proc/soundbreaker_apply_damage(
	mob/living/user,
	mob/living/target,
	damage_mult = 1,
	bclass = BCLASS_PUNCH,
	zone = BODY_ZONE_CHEST,
	damage_type = BRUTE,
	use_combo_pierce = TRUE,
)
	if(!target)
		return FALSE

	var/final_damage = soundbreaker_scale_damage(user, damage_mult)
	if(final_damage <= 0)
		return FALSE

	if(use_combo_pierce)
		var/stacks = soundbreaker_get_combo_stacks(user)
		if(stacks >= 3)
			bclass = BCLASS_STAB

	if(ishuman(target))
		var/mob/living/carbon/human/H = target

		if(!zone)
			zone = BODY_ZONE_CHEST

		var/obj/item/bodypart/affecting = H.get_bodypart(zone)
		if(!affecting)
			affecting = H.get_bodypart(BODY_ZONE_CHEST)
			if(affecting)
				zone = affecting.body_zone

		if(!affecting)
			return FALSE

		var/d_flag = soundbreaker_get_damage_flag(bclass, damage_type)
		var/armor_block = H.run_armor_check(zone, d_flag, 0, damage = final_damage, used_weapon = null)

		if(H.apply_damage(final_damage, damage_type, affecting, armor_block))
			affecting.bodypart_attacked_by(
				bclass,
				final_damage,
				user,
				zone_precise = zone,
				armor = armor_block,
				crit_message = TRUE,
				weapon = null,
			)
			return TRUE

		return FALSE

	if(HAS_TRAIT(target, TRAIT_SIMPLE_WOUNDS))
		if(target.apply_damage(final_damage, damage_type))
			target.simple_woundcritroll(bclass, final_damage, user, zone)
			return TRUE
		return FALSE

	return target.apply_damage(final_damage, damage_type)

/// Удар по одной случайной цели на тайле.
/proc/soundbreaker_hit_one_on_turf(
	mob/living/user,
	turf/T,
	damage_mult = 1,
	damage_type = BRUTE,
	bclass = BCLASS_PUNCH,
	zone,
)
	if(!user || !T)
		return null

	var/list/candidates = list()
	for(var/mob/living/L in T)
		if(L == user)
			continue
		if(L.stat == DEAD)
			continue
		candidates += L

	if(!candidates.len)
		return null

	var/mob/living/target = pick(candidates)

	if(!zone && istype(user))
		var/mob/living/UL = user
		if(UL.zone_selected)
			zone = UL.zone_selected

	if(!zone)
		zone = BODY_ZONE_CHEST

	if(soundbreaker_apply_damage(user, target, damage_mult, bclass, zone, damage_type))
		return target

	return null

/// Скалирование урона саундбрекера от статов и навыков
#define SB_MIN_DAMAGE_MULT 0.5
#define SB_MAX_DAMAGE_MULT 3

/proc/soundbreaker_scale_damage(mob/living/user, damage_mult)
	if(!user || damage_mult <= 0)
		return 0

	var/damage = 10

	// --- Активное оружие и его показатели ---
	var/obj/holding = user.get_active_held_item()
	if(holding)
		if(istype(holding, /obj/item/rogueweapon/katar) || istype(holding, /obj/item/rogueweapon/knuckles))
			var/weapon_force = holding.force
			damage = weapon_force

	else
		// --- СТАТЫ ---
		var/str = user.get_stat(STATKEY_STR)
		var/dex = user.get_stat(STATKEY_SPD)
		var/con = user.get_stat(STATKEY_CON)

		var/str_bonus = (str - 10) * 0.3
		var/dex_bonus = (dex - 10) * 0.2
		var/con_bonus = (con - 10) * 0.1
		damage += damage*str_bonus + damage*dex_bonus + damage*con_bonus

	damage *= damage_mult

	// --- НАВЫКИ ---
	var/unarmed_skill = user.get_skill_level(/datum/skill/combat/unarmed)
	var/music_skill = user.get_skill_level(/datum/skill/misc/music)

	// 25% за уровень безоружки, 15% за уровень музыки
	var/skill_bonus = (unarmed_skill * 0.2) + (music_skill * 0.1)

	skill_bonus = clamp(skill_bonus, SB_MIN_DAMAGE_MULT, SB_MAX_DAMAGE_MULT)

	damage *= skill_bonus

	return max(1, round(damage))

// Прок отчистки
/proc/soundbreaker_reset_rhythm(mob/living/user)
	if(!user)
		return

	user.remove_status_effect(/datum/status_effect/buff/soundbreaker_combo)

	soundbreaker_clear_note_icons(user)
	if(user.soundbreaker_combo)
		var/datum/soundbreaker_combo_tracker/T = user.soundbreaker_combo
		if(T && islist(T.history))
			T.history.Cut()

/proc/soundbreaker_swing_fx(turf/T)
	if(!T)
		return
	var/obj/effect/temp_visual/special_intent/fx = new(T, 0.4 SECONDS)
	fx.icon = 'icons/effects/effects.dmi'
	fx.icon_state = "sweep_fx"

/proc/soundbreaker_exclaim_fx(turf/T)
	if(!T)
		return
	var/obj/effect/temp_visual/special_intent/fx = new(T, 0.5 SECONDS)
	fx.icon = 'icons/effects/effects.dmi'
	fx.icon_state = "blip"

/proc/soundbreaker_get_front_turf(mob/living/user, distance = 1)
	if(!user)
		return null
	var/turf/T = get_turf(user)
	for(var/i in 1 to distance)
		var/turf/next = get_step(T, user.dir)
		if(!next)
			break
		T = next
	return T

/proc/soundbreaker_get_arc_turfs(mob/living/user, distance = 1)
	var/list/res = list()
	if(!user)
		return res

	var/turf/center = soundbreaker_get_front_turf(user, distance)
	if(!center)
		return res

	var/dir_left = turn(user.dir, 90)
	var/dir_right = turn(user.dir, -90)

	res += center

	var/turf/up = get_step(center, dir_left)
	if(up)
		res += up

	var/turf/down = get_step(center, dir_right)
	if(down)
		res += down

	return res

/proc/soundbreaker_step_behind(mob/living/user, mob/living/target)
	if(!user || !target)
		return

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	var/dir_to_target = get_dir(user, target)
	var/turf/behind = get_step(target_turf, dir_to_target)
	if(behind && !behind.density)
		user.forceMove(behind)

/proc/soundbreaker_step_forward(mob/living/user, tiles)
	if(!user)
		return
	var/turf/T = get_turf(user)
	for(var/i in 1 to tiles)
		var/turf/N = get_step(T, user.dir)
		if(!N || N.density)
			break
		T = N
	user.forceMove(T)

#define SB_PRIME_FAIL 0
#define SB_PRIME_NEW  1
#define SB_PRIME_REFRESHED 2

/proc/soundbreaker_prime_note(mob/living/user, note_id, damage_mult, damage_type)
	if(!user || !note_id)
		return SB_PRIME_FAIL
	if(!soundbreaker_has_music(user))
		return SB_PRIME_FAIL

	var/datum/status_effect/buff/soundbreaker_prepared/P = user.has_status_effect(/datum/status_effect/buff/soundbreaker_prepared)
	if(P && P.note_id == note_id)
		user.remove_status_effect(/datum/status_effect/buff/soundbreaker_prepared)
		user.apply_status_effect(/datum/status_effect/buff/soundbreaker_prepared)

		P = user.has_status_effect(/datum/status_effect/buff/soundbreaker_prepared)
		if(!P)
			return SB_PRIME_FAIL

		P.set_payload(note_id, damage_mult, damage_type)
		return SB_PRIME_REFRESHED

	user.remove_status_effect(/datum/status_effect/buff/soundbreaker_prepared)
	user.apply_status_effect(/datum/status_effect/buff/soundbreaker_prepared)

	P = user.has_status_effect(/datum/status_effect/buff/soundbreaker_prepared)
	if(!P)
		return SB_PRIME_FAIL

	P.set_payload(note_id, damage_mult, damage_type)
	return SB_PRIME_NEW

#undef SB_PRIME_FAIL
#undef SB_PRIME_NEW
#undef SB_PRIME_REFRESHED

/proc/soundbreaker_hit_specific(mob/living/user, mob/living/target, damage_mult = 1, damage_type = BRUTE, bclass = BCLASS_PUNCH, zone = BODY_ZONE_CHEST)
	if(!user || !target)
		return FALSE

	if(!zone && istype(user))
		var/mob/living/UL = user
		if(UL.zone_selected)
			zone = UL.zone_selected
	if(!zone)
		zone = BODY_ZONE_CHEST

	return soundbreaker_apply_damage(user, target, damage_mult, bclass, zone, damage_type)

/// ВАЖНО: нота всегда исполняется; whiff — только если нота НЕ deferred и НЕ попали
/proc/soundbreaker_try_consume_prepared_attack(mob/living/user, mob/living/target, zone = BODY_ZONE_CHEST)
	if(!user)
		return FALSE
	if(!soundbreaker_has_music(user))
		return FALSE

	var/datum/status_effect/buff/soundbreaker_prepared/P = user.has_status_effect(/datum/status_effect/buff/soundbreaker_prepared)
	if(!P)
		return FALSE

	if(target)
		user.face_atom(target)

	var/note_id = P.note_id
	var/damage_mult = P.damage_mult
	var/damage_type = P.damage_type

	user.remove_status_effect(/datum/status_effect/buff/soundbreaker_prepared)

	// Нота запускается ВСЕГДА (target может быть null!)
	var/mob/living/last_hit = soundbreaker_execute_note(user, target, note_id, damage_mult, damage_type, zone)

	if(last_hit)
		soundbreaker_on_hit(user, last_hit, note_id)
	else
		// Если нота deferred (таймерная) — не считаем это промахом сразу
		playsound(user, 'sound/combat/sp_whip_whiff.ogg', 40, TRUE)

	return TRUE

/proc/soundbreaker_execute_note(mob/living/user, mob/living/primary_target, note_id, damage_mult, damage_type, zone = BODY_ZONE_CHEST)
	if(!user || !note_id)
		return null

	switch(note_id)
		if(SOUNDBREAKER_NOTE_BEND)
			return soundbreaker_note_bend_play(user, primary_target, damage_mult, damage_type, zone)
		if(SOUNDBREAKER_NOTE_BARE)
			return soundbreaker_note_bare_play(user, primary_target, damage_mult, damage_type, zone)
		if(SOUNDBREAKER_NOTE_SLAP)
			return soundbreaker_note_slap_play(user, primary_target, damage_mult, damage_type, zone)
		if(SOUNDBREAKER_NOTE_SHED)
			return soundbreaker_note_shed_play(user, primary_target, damage_mult, damage_type, zone)
		if(SOUNDBREAKER_NOTE_SOLO)
			return soundbreaker_note_solo_play(user, primary_target, damage_mult, damage_type, zone)
		if(SOUNDBREAKER_NOTE_RIFF)
			return soundbreaker_note_riff_play(user, primary_target, damage_mult, damage_type, zone)

	return null

/proc/soundbreaker_note_bend_play(mob/living/user, mob/living/primary, damage_mult, damage_type, zone)
	var/turf/T = soundbreaker_get_front_turf(user, 1)
	if(!T)
		return null

	soundbreaker_swing_fx(T)

	if(primary && get_turf(primary) == T)
		if(soundbreaker_hit_specific(user, primary, damage_mult, damage_type, BCLASS_PUNCH, zone))
			return primary
	else
		return soundbreaker_hit_one_on_turf(user, T, damage_mult, damage_type, BCLASS_PUNCH, zone)

	return null

/proc/soundbreaker_note_bare_play(mob/living/user, mob/living/primary, damage_mult, damage_type, zone)
	var/mob/living/last_hit = null

	var/turf/T = get_turf(user)
	for(var/i in 1 to 2)
		var/turf/next = get_step(T, user.dir)
		if(!next)
			break
		T = next

		soundbreaker_swing_fx(T)

		if(primary && get_turf(primary) == T)
			if(soundbreaker_hit_specific(user, primary, damage_mult, damage_type, BCLASS_PUNCH, zone))
				last_hit = primary
		else
			var/mob/living/other = soundbreaker_hit_one_on_turf(user, T, damage_mult, damage_type, BCLASS_PUNCH, zone)
			if(other)
				last_hit = other

	return last_hit

/proc/soundbreaker_note_slap_play(mob/living/user, mob/living/primary, damage_mult, damage_type, zone)
	var/mob/living/last_hit = null

	var/turf/origin = get_turf(user)
	if(!origin)
		return null

	var/list/turfs = list()
	var/turf/front = get_step(origin, user.dir)
	if(front)
		turfs += front

	var/turf/side_left = get_step(origin, turn(user.dir, 90))
	var/turf/side_right = get_step(origin, turn(user.dir, -90))
	if(side_left)
		turfs += side_left
	if(side_right)
		turfs += side_right

	for(var/turf/T in turfs)
		if(!T)
			continue

		soundbreaker_swing_fx(T)

		if(primary && get_turf(primary) == T)
			if(soundbreaker_hit_specific(user, primary, damage_mult, damage_type, BCLASS_PUNCH, zone))
				last_hit = primary
		else
			var/mob/living/other = soundbreaker_hit_one_on_turf(user, T, damage_mult, damage_type, BCLASS_PUNCH, zone)
			if(other)
				last_hit = other

	return last_hit

/proc/soundbreaker_note_shed_play(mob/living/user, mob/living/primary, damage_mult, damage_type, zone)
	var/turf/T = soundbreaker_get_front_turf(user, 1)
	if(!T)
		return null

	soundbreaker_swing_fx(T)

	var/mob/living/hit = null
	if(primary && get_turf(primary) == T)
		if(soundbreaker_hit_specific(user, primary, damage_mult, damage_type, BCLASS_PUNCH, zone))
			hit = primary
	else
		hit = soundbreaker_hit_one_on_turf(user, T, damage_mult, damage_type, BCLASS_PUNCH, zone)

	if(hit)
		sb_safe_offbalance(hit, 1 SECONDS)

	return hit

/proc/soundbreaker_note_solo_play(mob/living/user, mob/living/primary, damage_mult, damage_type, zone)
	var/mob/living/last_hit = null

	var/turf/start = get_turf(user)
	if(!start)
		return null

	var/turf/mid = get_step(start, user.dir)

	soundbreaker_spawn_afterimage(user, start, 0.8 SECONDS)
	if(mid)
		soundbreaker_spawn_afterimage(user, mid, 0.8 SECONDS)

	if(mid)
		if(primary && get_turf(primary) == mid)
			if(soundbreaker_hit_specific(user, primary, damage_mult, damage_type, BCLASS_PUNCH, zone))
				last_hit = primary
		else
			var/mob/living/other = soundbreaker_hit_one_on_turf(user, mid, damage_mult, damage_type, BCLASS_PUNCH, zone)
			if(other)
				last_hit = other

	if(last_hit)
		soundbreaker_step_behind(user, last_hit)
		user.face_atom(last_hit)
	else
		soundbreaker_step_forward(user, 2)

	return last_hit

/proc/soundbreaker_note_riff_play(mob/living/user, mob/living/primary, damage_mult, damage_type, zone)
	var/mob/living/last_hit = null

	// Удар (например 1 тайл перед собой, как тебе хочется)
	var/turf/T = soundbreaker_get_front_turf(user, 1)
	if(!T)
		return null

	soundbreaker_swing_fx(T)
	if(primary && get_turf(primary) == T)
		if(soundbreaker_hit_specific(user, primary, damage_mult, damage_type, BCLASS_PUNCH, zone))
			last_hit = primary
	else
		last_hit = soundbreaker_hit_one_on_turf(user, T, damage_mult, damage_type, BCLASS_PUNCH, zone)

	user.apply_status_effect(/datum/status_effect/buff/soundbreaker_riff)

	return last_hit

/proc/soundbreaker_riff_on_successful_defense(mob/living/victim)
	if(!victim)
		return
	if(!victim.has_status_effect(/datum/status_effect/buff/soundbreaker_riff))
		return
	if(!soundbreaker_has_music(victim)) 
		return

	soundbreaker_add_combo_stack(victim)
	victim.remove_status_effect(/datum/status_effect/buff/soundbreaker_riff)

/proc/sb_is_offbalanced(mob/living/L)
	if(!L)
		return FALSE
	// В роге/азуре обычно есть IsOffBalanced() (у тебя даже комментом встречалось)
	return L.IsOffBalanced()

/proc/sb_try_get_zone(mob/living/user, zone)
	if(zone)
		return zone
	if(user?.zone_selected)
		return user.zone_selected
	return BODY_ZONE_CHEST

/// Псевдо-проектайл: ищем первую живую цель по линии (без настоящих projectile-объектов)
/// Возвращает, кого попали (или null)
/proc/soundbreaker_line_hit_first(mob/living/user, range = 5, damage_mult = 0.5, damage_type = BRUTE, bclass = BCLASS_PUNCH, zone)
	if(!user)
		return null

	zone = sb_try_get_zone(user, zone)

	var/turf/T = get_turf(user)
	if(!T)
		return null

	for(var/i in 1 to range)
		T = get_step(T, user.dir)
		if(!T)
			break
		if(T.density)
			break

		soundbreaker_swing_fx(T)
		var/mob/living/hit = soundbreaker_hit_one_on_turf(user, T, damage_mult, damage_type, bclass, zone)
		if(hit)
			return hit

	return null


#undef SB_MIN_DAMAGE_MULT
#undef SB_MAX_DAMAGE_MULT
