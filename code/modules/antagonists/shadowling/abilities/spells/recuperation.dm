// MARK: Ability

/// Innate ability channeling dark energy into an adjacent Shadow Thrall in darkness to elevate them into a Lesser Shadowling.
/datum/action/cooldown/shadowling/recuperation
	name = "Shadow Recuperation"
	desc = "Channel dark power into a living thrall (within 1 tile and in darkness) to elevate them into a Lesser Shadowling."
	button_icon_state = "shadow_recuperation"
	cooldown_time = 50 SECONDS
	channel_time = 10 SECONDS
	role_flags = SL_INNATE | SL_ASCENDED
	click_to_activate = TRUE
	unset_after_click = TRUE

	/// Active visual beam connecting caster to target thrall during channeling.
	var/datum/beam/current_beam
	/// Visual shadow cocoon placed over the target thrall during elevation.
	var/obj/structure/shadowling_cocoon/cover
	var/prev_alpha

	var/static/sfx_start = 'sound/effects/splat.ogg'
	var/static/sfx_end = 'sound/effects/ghost.ogg'
	/// Re-entrancy lock preventing concurrent recuperation channels.
	var/channeling = FALSE
	/// Caster currently channeling Shadow Recuperation.
	var/mob/living/carbon/human/channel_caster
	/// Thrall target currently inside the recuperation cocoon.
	var/mob/living/carbon/human/channel_target

/datum/action/cooldown/shadowling/recuperation/Remove(mob/remove_from)
	if(channeling)
		fail_ritual(channel_caster || remove_from, channel_target, refund_cd = TRUE)
	return ..()

/datum/action/cooldown/shadowling/recuperation/deactivate_power(mob/living/carbon/human/H)
	if(channeling)
		fail_ritual(channel_caster || H, channel_target, refund_cd = TRUE)
	else
		stop_beam()
		detach_cover(channel_target)
	return ..()

/// Aborts an active recuperation channel, tearing down beam, cocoon, and target alpha.
/datum/action/cooldown/shadowling/recuperation/proc/fail_ritual(mob/living/carbon/human/H, mob/living/carbon/human/T, reason, refund_cd = TRUE)
	channeling = FALSE
	channel_caster = null
	channel_target = null
	if(reason && !QDELETED(H))
		to_chat(H, span_warning(reason))
	stop_beam()
	detach_cover(T)
	if(!QDELETED(T) && !isnull(prev_alpha))
		T.alpha = prev_alpha
	if(!QDELETED(H) && H.click_intercept == src)
		unset_click_ability(H, refund_cd)
	return FALSE

/// Validates the clicked thrall, channels dark energy, strips the thrall tumor, and converts them to a Lesser Shadowling.
/datum/action/cooldown/shadowling/recuperation/InterceptClickOn(mob/living/clicker, params, atom/target)
	if(channeling)
		return FALSE

	if(!istype(clicker))
		if(ismob(clicker))
			unset_click_ability(clicker, TRUE)
		else if(ismob(owner))
			unset_click_ability(owner, TRUE)
		return FALSE

	if(!can_use(clicker) || !is_valid_caster(clicker))
		unset_click_ability(clicker, TRUE)
		return FALSE

	var/datum/team/shadow_hive/hive = get_hive()
	if(!hive || QDELETED(hive))
		unset_click_ability(clicker, TRUE)
		return FALSE

	if(!ishuman(target))
		clicker.balloon_alert(clicker, "invalid target")
		unset_click_ability(clicker, TRUE)
		return FALSE

	var/mob/living/carbon/human/T = target

	if(get_dist(clicker, T) > 1)
		clicker.balloon_alert(clicker, "too far")
		unset_click_ability(clicker, TRUE)
		return FALSE

	if((!is_dark(clicker) || !is_dark(T)) && !hive.debug_mode)
		clicker.balloon_alert(clicker, "too bright")
		unset_click_ability(clicker, TRUE)
		return FALSE

	if(!(T in hive.thralls) || (!T.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL) && !hive.debug_mode))
		clicker.balloon_alert(clicker, "requires a thrall")
		unset_click_ability(clicker, TRUE)
		return FALSE

	if(T in hive.lings)
		clicker.balloon_alert(clicker, "already a shadowling")
		unset_click_ability(clicker, TRUE)
		return FALSE

	channeling = TRUE
	channel_caster = clicker
	channel_target = T
	StartCooldown()

	start_beam(clicker, T)
	attach_cover(T)
	prev_alpha = T.alpha
	T.alpha = 0

	var/start_loc = T.loc
	var/cast_time = (hive.debug_mode ? (1 SECONDS) : channel_time)
	if(!do_after(clicker, cast_time, T))
		return fail_ritual(clicker, T)

	if(!is_valid_caster(clicker) || QDELETED(hive))
		return fail_ritual(clicker, T)

	if(QDELETED(T) || T.stat == DEAD || T.loc != start_loc || get_dist(clicker, T) > 1)
		return fail_ritual(clicker, T)

	if(!hive.convert_to_lesser(T))
		return fail_ritual(clicker, T, "Elevation failed.")

	to_chat(clicker, span_notice("You infuse the essence of [T.real_name] with shadows — they rise as a Lesser Shadowling."))
	playsound(get_turf(T), sfx_end, 65, TRUE)

	channeling = FALSE
	channel_caster = null
	channel_target = null
	stop_beam()
	detach_cover(T)
	if(!QDELETED(T))
		T.alpha = prev_alpha
	unset_click_ability(clicker, FALSE)
	return TRUE

/// Spawns a visual cocoon cover at [T]'s turf if not already active.
/datum/action/cooldown/shadowling/recuperation/proc/attach_cover(mob/living/carbon/human/T)
	if(cover)
		return
	cover = new /obj/structure/shadowling_cocoon(get_turf(T))

/// Removes and deletes the active visual cocoon cover.
/datum/action/cooldown/shadowling/recuperation/proc/detach_cover(mob/living/carbon/human/T)
	if(!cover)
		return
	qdel(cover)
	cover = null

/// Creates the channeling beam between [source] and [target].
/datum/action/cooldown/shadowling/recuperation/proc/start_beam(mob/living/source, mob/living/target)
	stop_beam()
	current_beam = source.Beam(
		BeamTarget = target,
		icon = 'icons/mob/antagonists/shadowling/shadowling_objects.dmi',
		icon_state = "shadow_grabber",
		time = channel_time,
		maxdistance = 2,
		emissive = FALSE
	)

/// Clears and deletes the active channeling beam if present.
/datum/action/cooldown/shadowling/recuperation/proc/stop_beam()
	if(current_beam && !QDELETED(current_beam))
		qdel(current_beam)
	current_beam = null

/datum/action/cooldown/shadowling/recuperation/Destroy()
	if(channeling)
		fail_ritual(channel_caster || owner, channel_target, refund_cd = FALSE)
	stop_beam()
	detach_cover(channel_target)
	return ..()
