#define ENTHRALL_OXY_DRAIN 35
#define ENTHRALL_OXY_RESTORE -100

// MARK: Ability
/datum/action/cooldown/shadowling/enthrall
	name = "Enthrall"
	desc = "Subjugate a nearby crewmember in front of you into a thrall of the Hive. Requires darkness."
	button_icon_state = "shadow_enthrall"
	cooldown_time = 45 SECONDS
	required_thralls = 0
	requires_dark_user = TRUE
	requires_dark_target = TRUE
	max_range = 2
	var/enthrall_time = 10 SECONDS
	cancel_on_bright = TRUE

/datum/action/cooldown/shadowling/enthrall/proc/find_cone_target(mob/living/carbon/human/H)
	var/mob/living/carbon/human/best = null
	var/best_dist = 999
	var/best_rank = 999
	for(var/mob/living/carbon/human/T in range(2, H))
		if(T == H)
			continue
		if(!in_front_cone(H, T, 90))
			continue
		if(!is_valid_target(H, T))
			continue
		var/d = get_dist(H, T)
		var/tdir = get_dir(H, T)
		var/rank = (tdir == H.dir) ? 0 : 1
		if(d < best_dist || (d == best_dist && rank < best_rank))
			best = T
			best_dist = d
			best_rank = rank
	return best

/datum/action/cooldown/shadowling/enthrall/proc/is_valid_target(mob/living/carbon/human/H, mob/living/carbon/human/T)
	if(!istype(T))
		return FALSE
	if(T.stat == DEAD)
		owner.balloon_alert(owner, "target is dead")
		return FALSE
	if(!T.mind)
		owner.balloon_alert(owner, "target lacks a mind")
		return FALSE
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(hive)
		if(T in hive.lings)
			return FALSE
		if(T in hive.thralls)
			return FALSE
	if(has_mindshield(T))
		return FALSE
	return TRUE

/datum/action/cooldown/shadowling/enthrall/proc/has_mindshield(mob/living/carbon/human/T)
	if(!istype(T))
		return FALSE
	if(islist(T.implants) && (locate(/obj/item/implant/mindshield) in T.implants))
		return TRUE
	return FALSE

/datum/action/cooldown/shadowling/enthrall/DoEffect(mob/living/carbon/human/H, atom/_ignored)
	var/mob/living/carbon/human/T = find_cone_target(H)
	if(!T)
		enable()
		return FALSE

	if(!is_dark(H) || !is_dark(T))
		owner.balloon_alert(owner, "light broke the connection")
		StartCooldown()
		return FALSE

	if(get_dist(H, T) > 2 || !is_valid_target(H, T))
		return FALSE

	var/obj/item/organ/existing = T.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL)
	if(existing)
		owner.balloon_alert(owner, "already bound to hive")
		to_chat(H, span_notice("[T.real_name] is already bound to the hive."))
		return TRUE

	to_chat(H, span_notice("You begin binding [T.real_name]'s mind to the hive. Stand still and remain in the dark..."))
	apply_wibbly_filters(T)
	apply_wibbly_filters(H)
	to_chat(T, span_danger("A freezing darkness envelopes your mind..."))

	// 30 second cast - to prevent players from speedrunning converts
	for(var/i in 1 to 3)
		if(cancel_on_bright && !is_dark(H))
			to_chat(H, span_warning("Light severed the connection."))
			remove_wibbly_filters(T)
			remove_wibbly_filters(H)
			return FALSE
		if(QDELETED(T) || T.stat == DEAD || get_dist(H, T) > 2 || has_mindshield(T) || !is_dark(T))
			to_chat(H, span_warning("Target lost."))
			remove_wibbly_filters(T)
			remove_wibbly_filters(H)
			return FALSE
		if(!do_after(H, enthrall_time, T))
			to_chat(H, span_warning("Connection broken."))
			remove_wibbly_filters(T)
			remove_wibbly_filters(H)
			return FALSE

		T.adjust_oxy_loss(ENTHRALL_OXY_DRAIN)

	if(QDELETED(T) || T.stat == DEAD || get_dist(H, T) > 2 || !is_dark(H) || !is_dark(T) || has_mindshield(T))
		to_chat(H, span_warning("The enthrallment failed."))
		remove_wibbly_filters(T)
		remove_wibbly_filters(H)
		return FALSE

	T.adjust_oxy_loss(ENTHRALL_OXY_RESTORE)

	var/obj/item/organ/brain/shadow/tumor_thrall/O = new
	if(!O.Insert(T))
		qdel(O)
		owner.balloon_alert(owner, "binding failed")
		to_chat(H, span_warning("Failed to bind [T.real_name] to the hive."))
		remove_wibbly_filters(T)
		remove_wibbly_filters(H)
		return FALSE

	to_chat(H, span_notice("You bind the mind of [T.real_name] to the hive."))
	to_chat(T, span_danger("Freezing darkness pierces your brain... You are now a thrall of the Hive!"))
	remove_wibbly_filters(T)
	remove_wibbly_filters(H)
	return TRUE

#undef ENTHRALL_OXY_DRAIN
#undef ENTHRALL_OXY_RESTORE
