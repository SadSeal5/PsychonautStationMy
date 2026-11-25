#define ENTHRALL_OXY_DRAIN 35
#define ENTHRALL_OXY_RESTORE -100

// MARK: Ability

/// Innate Shadowling ability binding a mindshield-free target in darkness into a Shadow Thrall.
/datum/action/cooldown/shadowling/enthrall
	name = "Enthrall"
	desc = "Subjugate a nearby crewmember in front of you into a thrall of the Hive. Requires darkness."
	button_icon_state = "shadow_enthrall"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED | AB_CHECK_HANDS_BLOCKED | AB_CHECK_OPEN_TURF
	cooldown_time = 45 SECONDS
	role_flags = SL_INNATE | SL_ASCENDED
	required_thralls = 0
	requires_dark_user = TRUE
	requires_dark_target = TRUE
	max_range = 2
	/// Channel duration per enthrall stage (3 stages total in normal mode).
	var/enthrall_time = 10 SECONDS
	cancel_on_bright = TRUE
	/// Re-entrancy lock preventing concurrent enthrall channels.
	var/channeling = FALSE
	/// Caster currently channeling Enthrall.
	var/mob/living/carbon/human/channel_caster
	/// Victim currently targeted by Enthrall.
	var/mob/living/channel_target
	/// Cumulative oxygen drained during the active channel for rollback on abort.
	var/channel_drained_oxy = 0

/datum/action/cooldown/shadowling/enthrall/Remove(mob/remove_from)
	if(channeling)
		fail_ritual(channel_caster || remove_from, channel_target, null, channel_drained_oxy)
	return ..()

/datum/action/cooldown/shadowling/enthrall/Destroy()
	if(channeling)
		fail_ritual(channel_caster || owner, channel_target, null, channel_drained_oxy)
	return ..()

/// Finds the closest valid non-hive target within a 90-degree front cone up to 2 tiles away.
/datum/action/cooldown/shadowling/enthrall/proc/find_cone_target(mob/living/carbon/human/H)
	var/mob/living/best = null
	var/best_dist = 999
	var/best_rank = 999
	for(var/mob/living/T in view(2, H))
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

/// Verifies that [T] is alive, eligible (human with mind, or carbon in debug mode), not in the hive, and lacks a mindshield.
/datum/action/cooldown/shadowling/enthrall/proc/is_valid_target(mob/living/carbon/human/H, mob/living/T)
	if(!istype(T))
		return FALSE
	if(T.stat == DEAD)
		owner.balloon_alert(owner, "target is dead")
		return FALSE
	var/datum/team/shadow_hive/hive = get_hive()
	var/debug_mode = hive?.debug_mode
	if(!ishuman(T) && !debug_mode)
		owner.balloon_alert(owner, "invalid target")
		return FALSE
	if(!T.mind)
		if(debug_mode)
			T.mind_initialize()
		else
			owner.balloon_alert(owner, "target lacks a mind")
			return FALSE
	if(is_hive_ally(T))
		return FALSE
	if(has_mindshield(T))
		return FALSE
	return TRUE

/// Returns TRUE if [T] is a carbon carrying a `/obj/item/implant/mindshield`.
/datum/action/cooldown/shadowling/enthrall/proc/has_mindshield(mob/living/T)
	if(!iscarbon(T))
		return FALSE
	var/mob/living/carbon/C = T
	if(islist(C.implants) && (locate(/obj/item/implant/mindshield) in C.implants))
		return TRUE
	return FALSE

/// Rolls back drained oxygen, `TRAIT_BEING_ENTHRALLED`, and wibbly visual filters on enthrall failure.
/datum/action/cooldown/shadowling/enthrall/proc/fail_ritual(mob/living/carbon/human/H, mob/living/T, reason, drained_oxy = 0)
	channeling = FALSE
	channel_caster = null
	channel_target = null
	channel_drained_oxy = 0
	if(reason && !QDELETED(H))
		to_chat(H, span_warning(reason))
	if(!QDELETED(T))
		if(drained_oxy > 0)
			T.adjust_oxy_loss(-drained_oxy)
		REMOVE_TRAIT(T, TRAIT_BEING_ENTHRALLED, REF(src))
		remove_wibbly_filters(T)
	if(!QDELETED(H))
		remove_wibbly_filters(H)
	return FALSE

/// Channels the 3-stage enthrall ritual, inserts a thrall tumor, and clears conflicting antagonist datums.
/datum/action/cooldown/shadowling/enthrall/do_effect(mob/living/carbon/human/H, atom/_ignored)
	if(!istype(H) || channeling)
		return FALSE
	if(!is_valid_caster(H))
		return FALSE

	var/datum/team/shadow_hive/hive = get_hive()
	if(!hive || QDELETED(hive))
		return FALSE
	var/debug_mode = hive.debug_mode

	var/mob/living/T = find_cone_target(H)
	if(!T)
		return FALSE

	if(HAS_TRAIT(T, TRAIT_BEING_ENTHRALLED))
		owner.balloon_alert(owner, "victim is already being enthralled")
		return FALSE

	if((!is_dark(H) || !is_dark(T)) && !debug_mode)
		owner.balloon_alert(owner, "light broke the connection")
		StartCooldown()
		return FALSE

	if(get_dist(H, T) > 2 || !is_valid_target(H, T))
		return FALSE

	if(iscarbon(T))
		var/mob/living/carbon/C = T
		var/obj/item/organ/existing = C.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL)
		if(existing)
			owner.balloon_alert(owner, "already bound to hive")
			to_chat(H, span_notice("[T.real_name] is already bound to the hive."))
			return FALSE

	channeling = TRUE
	channel_caster = H
	channel_target = T
	channel_drained_oxy = 0
	ADD_TRAIT(T, TRAIT_BEING_ENTHRALLED, REF(src))

	to_chat(H, span_notice("You begin binding [T.real_name]'s mind to the hive. Stand still and remain in the dark..."))
	apply_wibbly_filters(T)
	apply_wibbly_filters(H)
	to_chat(T, span_danger("A freezing darkness envelopes your mind..."))

	var/cast_delay = (debug_mode ? (1 SECONDS) : enthrall_time)
	var/loops = (debug_mode ? 1 : 3)

	// 30 second cast (1 loop of 1s in debug mode)
	for(var/i in 1 to loops)
		if(!is_valid_caster(H))
			return fail_ritual(H, T, null, channel_drained_oxy)
		if(cancel_on_bright && !is_dark(H) && !debug_mode)
			return fail_ritual(H, T, "Light severed the connection.", channel_drained_oxy)
		if(QDELETED(T) || T.stat == DEAD || get_dist(H, T) > 2 || has_mindshield(T) || (!is_dark(T) && !debug_mode))
			return fail_ritual(H, T, "Target lost.", channel_drained_oxy)
		if(!do_after(H, cast_delay, T))
			return fail_ritual(H, T, "Connection broken.", channel_drained_oxy)
		if(!is_valid_caster(H))
			return fail_ritual(H, T, null, channel_drained_oxy)

		T.adjust_oxy_loss(ENTHRALL_OXY_DRAIN)
		channel_drained_oxy += ENTHRALL_OXY_DRAIN

	if(!is_valid_caster(H) || QDELETED(T) || T.stat == DEAD || get_dist(H, T) > 2 || ((!is_dark(H) || !is_dark(T)) && !debug_mode) || has_mindshield(T))
		return fail_ritual(H, T, "The enthrallment failed.", channel_drained_oxy)

	REMOVE_TRAIT(T, TRAIT_BEING_ENTHRALLED, REF(src))
	T.adjust_oxy_loss(ENTHRALL_OXY_RESTORE)

	if(iscarbon(T))
		var/obj/item/organ/brain/shadow/tumor_thrall/O = new
		if(!O.Insert(T))
			if(debug_mode)
				T.mind?.add_antag_datum(/datum/antagonist/shadow_thrall)
			else
				qdel(O)
				owner.balloon_alert(owner, "binding failed")
				return fail_ritual(H, T, "Failed to bind [T.real_name] to the hive.")
	else if(debug_mode)
		T.mind?.add_antag_datum(/datum/antagonist/shadow_thrall)

	if(T.mind)
		var/static/list/conflicting_antags = list(
			/datum/antagonist/cult,
			/datum/antagonist/rev,
			/datum/antagonist/nukeop,
			/datum/antagonist/traitor,
			/datum/antagonist/changeling,
			/datum/antagonist/heretic,
		)
		for(var/antag_type in conflicting_antags)
			T.mind.remove_antag_datum(antag_type)

	to_chat(H, span_notice("You bind the mind of [T.real_name] to the hive."))
	to_chat(T, "<span class='reallybig redtext'>A terrifying darkness crashes into your subconscious, obliterating your former identity. All prior allegiances, oaths, and loyalties are entirely meaningless. Your soul belongs wholly to the Shadowling Hive — you will obey and protect your masters without hesitation!</span>")
	remove_wibbly_filters(T)
	remove_wibbly_filters(H)
	channeling = FALSE
	channel_caster = null
	channel_target = null
	channel_drained_oxy = 0
	return TRUE

#undef ENTHRALL_OXY_DRAIN
#undef ENTHRALL_OXY_RESTORE
