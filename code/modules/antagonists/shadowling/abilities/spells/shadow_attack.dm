// MARK: Ability
/datum/action/cooldown/shadowling/shadow_strike
	name = "Shadow Strike"
	desc = "Teleport out of the shadows adjacent to a nearby enemy and strike them with a devastating blow."
	button_icon_state = "shadow_strike"
	cooldown_time = 5 SECONDS
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	channel_time = 0
	max_range = 3

	var/attack_value = 25
	var/static/sfx_activate = 'sound/effects/magic/demon_attack1.ogg'

/datum/action/cooldown/shadowling/shadow_strike/can_use(mob/living/carbon/human/H)
	if(!..())
		return FALSE
	if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		return TRUE
	if(H.has_status_effect(/datum/status_effect/shadow/phase))
		return TRUE
	owner.balloon_alert(owner, "you must be incorporeal")
	return FALSE

/datum/action/cooldown/shadowling/shadow_strike/Trigger(mob/clicker, trigger_flags, atom/target)
	if(!istype(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(!can_use(H))
		return
	var/mob/living/carbon/human/target_mob = find_closest_target(H)
	if(!target_mob)
		owner.balloon_alert(owner, "no valid targets")
		return
	if(DoEffect(H, target_mob))
		StartCooldown()

/datum/action/cooldown/shadowling/shadow_strike/proc/find_closest_target(mob/living/carbon/human/H)
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	var/turf/center = get_turf(H)
	if(!center)
		return null
	var/mob/living/carbon/human/best
	var/best_dist = 999
	for(var/mob/living/carbon/human/L in range(max_range, center))
		if(L == H)
			continue
		if(L.stat == DEAD)
			continue
		if(hive)
			if(L in hive.lings)
				continue
			if(L in hive.thralls)
				continue
		var/d = get_dist(H, L)
		if(d < best_dist)
			best = L
			best_dist = d
	return best

/datum/action/cooldown/shadowling/shadow_strike/DoEffect(mob/living/carbon/human/H, atom/target)
	if(!istype(H))
		return FALSE

	var/mob/living/carbon/human/T = null
	if(istype(target, /mob/living/carbon/human))
		T = target
	else
		T = find_closest_target(H)

	if(!istype(T))
		owner.balloon_alert(owner, "no valid targets")
		return FALSE

	var/turf/nearby = pick_adjacent_open_turf(get_turf(T))
	var/datum/action/cooldown/shadowling/shadow_phase/SP
	for(var/datum/action/cooldown/shadowling/shadow_phase/X in H.actions)
		SP = X
		break
	if(SP)
		SP.materialize_near(H, nearby, FALSE)
	else
		if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
			var/obj/effect/dummy/phased_mob/shadowling/P = H.loc
			if(istype(nearby))
				P.forceMove(nearby)
			P.eject_jaunter(FALSE)
		else
			H.remove_status_effect(/datum/status_effect/shadow/phase)

	if(get_dist(H, T) > 1)
		step_towards(H, T)

	if(QDELETED(H) || QDELETED(T) || get_dist(H, T) > 1)
		owner.balloon_alert(owner, "too far to strike")
		return FALSE

	H.visible_message(
		span_boldwarning("[H] bursts from the shadows and strikes [T]!"),
		span_userdanger("You burst from the shadows and strike [T]!"),
		ignored_mobs = null
	)

	T.apply_damage(attack_value, BRUTE, null, sharpness = SHARP_POINTY)
	H.do_attack_animation(T)
	playsound(get_turf(H), sfx_activate, 65, TRUE)
	T.log_message("was hit by [H] with shadow strike for [attack_value] brute", LOG_ATTACK, color = "#8a2be2")
	return TRUE
