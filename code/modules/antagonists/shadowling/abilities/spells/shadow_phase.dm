// MARK: Effects

/// Expanding blue swirl visual emitted when entering, exiting, or burning inside Shadow Phase.
/obj/effect/temp_visual/shadow_phase_smoke
	name = "umbral plume"
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "cloud_swirl"
	plane = ABOVE_GAME_PLANE
	layer = EFFECTS_LAYER
	color = "#015fff"
	alpha = 220

/obj/effect/temp_visual/shadow_phase_smoke/Initialize(mapload)
	. = ..()
	animate(src, transform = matrix() * 1.2, time = 4)
	animate(alpha = 0, time = 6)
	QDEL_IN(src, 0.6 SECONDS)
	return .

// MARK: Ability

/// Threshold-15% toggle ability shifting the caster into an incorporeal `/obj/effect/dummy/phased_mob/shadowling`.
/datum/action/cooldown/shadowling/shadow_phase
	name = "Shadow Phase"
	desc = "Become incorporeal and phase through walls for a short duration. Bright light forces you out unless ascended."
	button_icon_state = "shadowling_crawl"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	cooldown_time = 30 SECONDS
	role_flags = SL_THRESHOLD | SL_LESSER | SL_ASCENDED
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	max_range = 0
	channel_time = 0
	min_req = 1
	max_req = 3
	required_thralls = 15
	var/phase_duration = 12 SECONDS
	/// Guards against double-casting during the 0.3s fade-out delay before spawning the dummy.
	var/entering = FALSE
	/// Alpha captured prior to phasing so non-standard alpha values are preserved on exit.
	var/prev_alpha = 255
	var/static/sfx_enter = 'sound/effects/magic/teleport_app.ogg'

/datum/action/cooldown/shadowling/shadow_phase/Remove(mob/remove_from)
	var/was_entering = entering
	entering = FALSE
	var/mob/living/carbon/human/H = remove_from
	if(istype(H))
		if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
			exit_phase(H, forced_out = FALSE)
		else if(was_entering || H.alpha == 0)
			animate(H)
			H.alpha = prev_alpha
	return ..()

/datum/action/cooldown/shadowling/shadow_phase/Destroy()
	var/was_entering = entering
	entering = FALSE
	var/mob/living/carbon/human/H = owner
	if(istype(H))
		if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
			exit_phase(H, forced_out = FALSE)
		else if(was_entering || H.alpha == 0)
			animate(H)
			H.alpha = prev_alpha
	return ..()

/datum/action/cooldown/shadowling/shadow_phase/deactivate_power(mob/living/carbon/human/H)
	if(istype(H) && istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		exit_phase(H, forced_out = FALSE)
	return ..()

/datum/action/cooldown/shadowling/shadow_phase/can_use(mob/living/carbon/human/H)
	if(!..())
		return FALSE
	if(!isopenturf(H.loc) && !istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		owner.balloon_alert(owner, "cannot use while enclosed")
		return FALSE
	return TRUE

/datum/action/cooldown/shadowling/shadow_phase/Activate(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE

	var/obj/effect/dummy/phased_mob/shadowling/P = istype(H.loc, /obj/effect/dummy/phased_mob/shadowling) ? H.loc : null
	var/is_in_phase = !!P

	if(!is_in_phase)
		if(!can_use(H))
			return FALSE
		if(channel_time > 0)
			if(!perform_channel(H, null))
				return FALSE
		if(!enter_phase(H))
			return FALSE
		return TRUE
	else
		exit_phase(H, forced_out = FALSE)
		StartCooldown(5 SECONDS)
		return TRUE

/datum/action/cooldown/shadowling/shadow_phase/proc/fade_out(mob/living/carbon/human/H, time = 0.3 SECONDS)
	animate(H, alpha = 0, time = time)

/datum/action/cooldown/shadowling/shadow_phase/proc/fade_in(mob/living/carbon/human/H, time = 0.3 SECONDS)
	animate(H, alpha = prev_alpha, time = time)

/datum/action/cooldown/shadowling/shadow_phase/proc/_auto_exit_if_still_inside(datum/weakref/P_ref)
	var/obj/effect/dummy/phased_mob/shadowling/P = P_ref?.resolve()
	if(!istype(P))
		return
	if(!P.jaunter)
		return
	var/mob/living/carbon/human/H = P.jaunter
	exit_phase(H, forced_out = FALSE)
	if(!QDELETED(src))
		StartCooldown()

/// Begins phasing [H] out, fading alpha and spawning the phased dummy after 0.3s.
/datum/action/cooldown/shadowling/shadow_phase/proc/enter_phase(mob/living/carbon/human/H)
	if(entering)
		to_chat(H, span_warning("You are already dissolving into the shadows."))
		return FALSE

	var/turf/start = get_turf(H)
	if(!start)
		return FALSE

	if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		to_chat(H, span_warning("You are already dissolved into the shadows."))
		return FALSE

	entering = TRUE
	prev_alpha = H.alpha
	new /obj/effect/temp_visual/shadow_phase_smoke(start)
	playsound(start, sfx_enter, 65, TRUE)
	fade_out(H, 0.3 SECONDS)

	addtimer(CALLBACK(src, PROC_REF(finish_enter_phase), WEAKREF(H), WEAKREF(start)), 0.3 SECONDS)
	return TRUE

/// Completes phase entry by placing [H] into a new phased dummy at [start].
/datum/action/cooldown/shadowling/shadow_phase/proc/finish_enter_phase(datum/weakref/mob_ref, datum/weakref/start_ref)
	entering = FALSE
	var/mob/living/carbon/human/H = mob_ref?.resolve()
	var/turf/start = start_ref?.resolve()
	if(QDELETED(src) || QDELETED(H) || QDELETED(start) || owner != H || H.stat == DEAD || istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		if(!QDELETED(H))
			H.alpha = prev_alpha
		return FALSE

	var/obj/effect/dummy/phased_mob/shadowling/P = new(start)
	P.dir = H.dir
	P.light_immunity = isshadowling_ascended(owner)
	P.set_jaunter(H)

	addtimer(CALLBACK(src, PROC_REF(_auto_exit_if_still_inside), WEAKREF(P)), phase_duration)

	to_chat(H, span_notice("You dissolve into the shadows."))

	for(var/datum/action/cooldown/shadowling/shadow_phase/A in owner.actions)
		A.activate_power(H)

	refresh_owner_actions(owner)
	return TRUE

/// Ejects [H] from the phased dummy and restores physical visibility and button state.
/datum/action/cooldown/shadowling/shadow_phase/proc/exit_phase(mob/living/carbon/human/H, forced_out = FALSE)
	var/turf/end_turf = get_turf(H)
	var/obj/effect/dummy/phased_mob/shadowling/P = H.loc

	if(istype(P))
		P.eject_jaunter(forced_out)

	if(end_turf)
		new /obj/effect/temp_visual/shadow_phase_smoke(end_turf)

	fade_in(H, 0.3 SECONDS)
	to_chat(H, span_notice("You return to physical form."))

	for(var/datum/action/cooldown/shadowling/shadow_phase/A in H.actions)
		A.active = FALSE
		A.apply_button_overlay()

	refresh_owner_actions(H)
	return TRUE

/// Moves the phased dummy to [nearby], exits phase, and starts a 10s cooldown (used by Shadow Strike).
/datum/action/cooldown/shadowling/shadow_phase/proc/materialize_near(mob/living/carbon/human/H, turf/nearby, forced_out = FALSE)
	if(!istype(H))
		return FALSE

	var/exited = FALSE
	var/turf/end_turf = nearby || get_turf(H)

	if(istype(H.loc, /obj/effect/dummy/phased_mob/shadowling))
		var/obj/effect/dummy/phased_mob/shadowling/P = H.loc
		if(istype(nearby))
			P.forceMove(nearby)
		end_turf = get_turf(P) || nearby
		P.eject_jaunter(forced_out)
		exited = TRUE

	if(!exited)
		return FALSE

	if(end_turf)
		new /obj/effect/temp_visual/shadow_phase_smoke(end_turf)

	fade_in(H, 0.3 SECONDS)
	to_chat(H, span_notice("You return to physical form."))
	StartCooldown(10 SECONDS)

	for(var/datum/action/cooldown/shadowling/shadow_phase/A in H.actions)
		A.active = FALSE
		A.apply_button_overlay()

	refresh_owner_actions(H)
	return TRUE
