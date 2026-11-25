// MARK: Ability

/// Ascended ability usable while phased to materialize beside a target and strike or neck-grab them.
/datum/action/cooldown/shadowling/shadow_strike
	name = "Shadow Strike"
	desc = "Target a mortal while incorporeal. Left-Click to teleport and deliver a devastating strike (25 brute damage). Right-Click to teleport and grab them by the neck."
	button_icon_state = "shadow_strike"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	cooldown_time = 5 SECONDS
	role_flags = SL_ASCENDED
	click_to_activate = TRUE
	unset_after_click = TRUE
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	channel_time = 0
	max_range = 3

	/// Tile range within which neck-grab mode can engage.
	var/grab_range = 2
	/// Brute damage dealt by left-click Shadow Strike.
	var/attack_value = 25
	/// Grab level escalated to on right-click ambush.
	var/target_grab_level = GRAB_NECK
	var/static/sfx_activate = 'sound/effects/magic/demon_attack1.ogg'
	/// Tracks whether right-click grab mode was triggered.
	var/secondary_mode = FALSE

/datum/action/cooldown/shadowling/shadow_strike/unset_click_ability(mob/on_who, refund_cooldown)
	secondary_mode = FALSE
	button_icon_state = "shadow_strike"
	. = ..()
	build_all_button_icons(UPDATE_BUTTON_ICON, force = TRUE)

/// Requires the Ascended Shadowling to be phased inside a shadow dummy.
/datum/action/cooldown/shadowling/shadow_strike/can_use(mob/living/carbon/human/H)
	if(!..())
		return FALSE
	if(!isopenturf(H.loc) && !istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		owner.balloon_alert(owner, "cannot use while enclosed")
		return FALSE
	if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		return TRUE
	owner.balloon_alert(owner, "you must be incorporeal")
	return FALSE

/// Switches between left-click strike and right-click neck-grab icons based on [trigger_flags].
/datum/action/cooldown/shadowling/shadow_strike/Trigger(mob/clicker, trigger_flags, atom/target)
	if(!istype(owner))
		return FALSE
	if(!can_use(owner))
		return FALSE
	secondary_mode = (trigger_flags & TRIGGER_SECONDARY_ACTION) ? TRUE : FALSE
	button_icon_state = secondary_mode ? "shadow_grab" : "shadow_strike"
	build_all_button_icons(UPDATE_BUTTON_ICON, force = TRUE)
	return ..()

/// Materializes adjacent to the clicked non-hive human and executes either a 25-brute strike or neck grab.
/datum/action/cooldown/shadowling/shadow_strike/InterceptClickOn(mob/living/clicker, params, atom/target)
	if(!istype(clicker))
		if(ismob(clicker))
			unset_click_ability(clicker, TRUE)
		else if(ismob(owner))
			unset_click_ability(owner, TRUE)
		return FALSE

	if(!can_use(clicker))
		unset_click_ability(clicker, TRUE)
		return FALSE

	var/mob/living/carbon/human/H = clicker
	var/mob/living/carbon/human/T
	if(ishuman(target))
		T = target
	else if(istype(target?.loc, /mob/living/carbon/human))
		T = target.loc

	if(!istype(T))
		H.balloon_alert(H, "invalid target")
		return FALSE

	if(T == H)
		H.balloon_alert(H, "cannot target yourself")
		return FALSE

	if(T.stat == DEAD)
		H.balloon_alert(H, "target is dead")
		return FALSE

	if(is_hive_ally(T))
		H.balloon_alert(H, "allies cannot be targeted")
		return FALSE

	var/list/modifiers = params2list(params)
	var/is_grab = LAZYACCESS(modifiers, RIGHT_CLICK) ? TRUE : secondary_mode
	secondary_mode = FALSE

	var/dist = get_dist(H, T)
	if(is_grab)
		if(H.usable_hands <= 0 || HAS_TRAIT(H, TRAIT_HANDS_BLOCKED))
			H.balloon_alert(H, "hands not free")
			return FALSE
		if(T.anchored)
			H.balloon_alert(H, "target cannot be grabbed")
			return FALSE
		if(dist > grab_range)
			H.balloon_alert(H, "too far to grab")
			return FALSE
	else
		if(dist > max_range)
			H.balloon_alert(H, "too far to strike")
			return FALSE

	var/turf/target_turf = get_turf(T)
	if(!istype(target_turf))
		H.balloon_alert(H, "invalid target")
		return FALSE

	var/list/open_turfs = list()
	for(var/turf/open_cand in get_adjacent_open_turfs(target_turf))
		if(!open_cand.density && !open_cand.is_blocked_turf(TRUE))
			open_turfs += open_cand
	var/turf/nearby = length(open_turfs) ? pick(open_turfs) : null
	if(!nearby || !T.Adjacent(nearby))
		H.balloon_alert(H, "no space near target")
		return FALSE
	var/datum/action/cooldown/shadowling/shadow_phase/SP = locate(/datum/action/cooldown/shadowling/shadow_phase) in H.actions
	if(SP)
		SP.materialize_near(H, nearby, FALSE)
	else
		if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
			var/obj/effect/dummy/phased_mob/shadowling/P = H.loc
			if(istype(nearby))
				P.forceMove(nearby)
			P.eject_jaunter(FALSE)
		H.alpha = 255

	refresh_owner_actions(H)

	if(get_dist(H, T) > 1)
		step_towards(H, T)

	if(QDELETED(H))
		return FALSE

	if(QDELETED(T) || get_dist(H, T) > 1)
		H.balloon_alert(H, is_grab ? "too far to grab" : "too far to strike")
		unset_click_ability(H, TRUE)
		return FALSE

	if(is_grab)
		if(H.grab(T) != GRAB_SUCCESS)
			unset_click_ability(H, TRUE)
			return FALSE

		for(var/i in 1 to 3)
			if(H.grab_state >= target_grab_level)
				break
			if(!H.pulling || H.pulling != T)
				break
			if(!T.grippedby(H, TRUE))
				break

		if(H.pulling != T)
			unset_click_ability(H, TRUE)
			return FALSE

		H.visible_message(
			span_boldwarning("[H] bursts from the shadows and lunges at [T]'s throat!"),
			span_userdanger("You burst from the shadows and grab [T] by the neck!"),
			ignored_mobs = null
		)
		T.log_message("was grabbed from shadows by [H]", LOG_ATTACK, color = "#8a2be2")
		button_icon_state = "shadow_grab"
	else
		H.visible_message(
			span_boldwarning("[H] bursts from the shadows and strikes [T]!"),
			span_userdanger("You burst from the shadows and strike [T]!"),
			ignored_mobs = null
		)
		T.apply_damage(attack_value, BRUTE, null, sharpness = SHARP_POINTY)
		H.do_attack_animation(T)
		playsound(get_turf(H), sfx_activate, 65, TRUE)
		T.log_message("was hit by [H] with shadow strike for [attack_value] brute", LOG_ATTACK, color = "#8a2be2")
		button_icon_state = "shadow_strike"

	build_all_button_icons(UPDATE_BUTTON_ICON, force = TRUE)
	unset_click_ability(H, refund_cooldown = FALSE)
	StartCooldown()
	return TRUE

