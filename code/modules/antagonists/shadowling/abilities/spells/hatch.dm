// MARK: Effects

/// Fading purple spark pulse spawned during Hatch and Ascension ticks.
/obj/effect/temp_visual/shadowling/hatch_pulse
	name = "shadow pulse"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_GAME_PLANE
	layer = EFFECTS_LAYER
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	color = "#6e00a8"
	alpha = 220

/obj/effect/temp_visual/shadowling/hatch_pulse/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = 6)
	QDEL_IN(src, 0.6 SECONDS)
	return .

// MARK: Structures

/// Indestructible visual cocoon covering a Shadowling or thrall during transformation.
/obj/structure/shadowling_cocoon
	name = "shadow cocoon"
	desc = "A pulsating cocoon of living shadows."
	icon = 'icons/mob/antagonists/shadowling/shadowling_objects.dmi'
	icon_state = "shadowcocoon"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/alien/resin/wall/shadowling
	name = "umbral mass"
	desc = "Slick, oppressive darkness hardened into an impassable barrier."
	color = "#5e545a"
	move_resist = MOVE_FORCE_VERY_STRONG
	resistance_flags = INDESTRUCTIBLE

/obj/structure/alien/resin/wall/shadowling/Initialize(mapload)
	. = ..()
	QDEL_IN(src, 3 MINUTES)

// MARK: Ability

/// Unhatched Shadowling ritual that strips disguises, builds protective walls, and transforms the caster into `/datum/species/shadow/shadowling`.
/datum/action/cooldown/shadowling/hatch
	name = "Hatch"
	desc = "Shed your mortal guise and reveal your true shadow form. Requires darkness."
	button_icon_state = "shadow_hatch"
	cooldown_time = 30 SECONDS
	requires_dark_user = TRUE
	requires_dark_target = FALSE
	max_range = 0
	channel_time = 0

	/// Number of channel stages required to hatch.
	var/steps = 3
	/// Duration of each channel stage.
	var/step_time = 10 SECONDS

	var/static/sfx_start = 'sound/effects/splat.ogg'
	var/static/sfx_end = 'sound/effects/ghost.ogg'
	var/static/list/sfx_tick = list('sound/items/weapons/slice.ogg', 'sound/items/weapons/slash.ogg', 'sound/items/weapons/slashmiss.ogg')

	/// Cocoon visual spawned over the caster while hatching.
	var/obj/structure/shadowling_cocoon/cover
	var/prev_alpha
	/// Temporary resin walls spawned around the hatch site.
	var/list/walls
	/// Re-entrancy lock preventing concurrent hatch channels.
	var/channeling = FALSE
	/// Caster currently channeling Hatch, cleared when the ritual ends or aborts.
	var/mob/living/carbon/human/channel_caster

/datum/action/cooldown/shadowling/hatch/Remove(mob/remove_from)
	if(channeling)
		fail_ritual(channel_caster || remove_from)
	return ..()

/datum/action/cooldown/shadowling/hatch/Destroy()
	if(channeling)
		fail_ritual(channel_caster || owner)
	cleanup(walls)
	walls = null
	detach_cover()
	return ..()

/// Surrounds [center] with temporary indestructible umbral resin walls on open turfs.
/datum/action/cooldown/shadowling/hatch/proc/build_ring_walls(turf/center)
	var/list/walls = list()
	if(!istype(center))
		return walls
	var/list/dirs = list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
	for(var/d in dirs)
		var/turf/T = get_step(center, d)
		if(!istype(T))
			continue
		if(T.density)
			continue
		var/obj/structure/alien/resin/wall/shadowling/W = new(T)
		walls += W
	return walls

/// Deletes all temporary objects tracked in [to_clean].
/datum/action/cooldown/shadowling/hatch/proc/cleanup(list/to_clean)
	if(!islist(to_clean))
		return
	for(var/atom/movable/A as anything in to_clean)
		if(!QDELETED(A))
			qdel(A)

/// Spawns a hatch pulse visual and plays a tick sound at [H]'s turf.
/datum/action/cooldown/shadowling/hatch/proc/play_tick_fx(mob/living/carbon/human/H)
	var/turf/T = get_turf(H)
	if(!T)
		return
	new /obj/effect/temp_visual/shadowling/hatch_pulse(T)
	playsound(T, pick(sfx_tick), 35, TRUE, -1)

/// Places the visual shadow cocoon at the owner's turf if not already spawned.
/datum/action/cooldown/shadowling/hatch/proc/attach_cover()
	if(cover)
		return
	cover = new /obj/structure/shadowling_cocoon(get_turf(owner))

/// Deletes the visual shadow cocoon if present.
/datum/action/cooldown/shadowling/hatch/proc/detach_cover()
	if(!cover)
		return
	qdel(cover)
	cover = null

/// Tears down cocoon cover, temporary walls, and restores alpha when hatching aborts.
/datum/action/cooldown/shadowling/hatch/proc/fail_ritual(mob/living/carbon/human/H, reason)
	channeling = FALSE
	channel_caster = null
	if(reason && !QDELETED(H))
		to_chat(H, span_warning(reason))
	detach_cover()
	cleanup(walls)
	walls = null
	if(!QDELETED(H) && !isnull(prev_alpha))
		H.alpha = prev_alpha
	return FALSE

/// Encases [H] in a dark cocoon ring, channels the hatch stages, and swaps to `/datum/species/shadow/shadowling`.
/datum/action/cooldown/shadowling/hatch/do_effect(mob/living/carbon/human/H, atom/_)
	if(!istype(H) || channeling)
		return FALSE
	if(!is_valid_caster(H))
		return FALSE
	if(isshadowling(H) || isshadowling_ascended(H))
		return FALSE

	var/turf/start = get_turf(H)
	if(!start)
		return FALSE
	if(start.get_lumcount() >= SHADOWLING_DIM_THRESHOLD)
		to_chat(H, span_warning("Light prevents hatching."))
		return FALSE

	channeling = TRUE
	channel_caster = H
	StartCooldown()
	walls = build_ring_walls(start)

	attach_cover()
	playsound(start, sfx_start, 60, TRUE)
	to_chat(H, span_notice("You begin tearing through your outer shell..."))

	var/turf/anchor_turf = get_turf(H)
	var/area/anchor_area = get_area(H)
	prev_alpha = H.alpha
	H.alpha = 0
	H.drop_all_held_items()

	for(var/i in 1 to steps)
		if(!is_valid_caster(H))
			return fail_ritual(H)

		var/turf/cur = get_turf(H)
		if(!cur || cur != anchor_turf || get_area(H) != anchor_area)
			return fail_ritual(H, "You broke free of the cocoon — hatching interrupted.")

		if(cur.get_lumcount() >= SHADOWLING_DIM_THRESHOLD)
			return fail_ritual(H, "Light dispels the darkness — hatching aborted.")

		play_tick_fx(H)

		if(i == 1)
			to_chat(H, span_notice("Darkness coils within you, reshaping your flesh."))
		else
			to_chat(H, span_notice("The shadows solidify as the transformation nears completion..."))

		if(!do_after(H, step_time, H))
			return fail_ritual(H, "You broke free of the cocoon — hatching interrupted.")
		if(!is_valid_caster(H))
			return fail_ritual(H)

	if(!is_valid_caster(H))
		return fail_ritual(H)

	var/turf/final_turf = get_turf(H)
	if(!final_turf || final_turf.get_lumcount() >= SHADOWLING_DIM_THRESHOLD)
		return fail_ritual(H, "Bright light disrupts the darkness — hatching aborted.")

	var/datum/antagonist/shadowling/ling_datum = get_shadowling_antag_of(H)
	var/datum/team/shadow_hive/hive = ling_datum?.get_hive()
	if(!ling_datum || !hive || QDELETED(hive))
		return fail_ritual(H, "Hive connection severed — hatching aborted.")

	H.shadowling_strip_quirks()
	H.reset_robotic_limbs()
	if(!ling_datum.original_species)
		ling_datum.original_species = H.dna?.species
	H.set_species(/datum/species/shadow/shadowling)
	hive.sync_after_event(H)
	H.refresh_eye_overlays()
	playsound(start, sfx_end, 70, TRUE)
	new /obj/effect/temp_visual/shadowling/hatch_pulse(start)
	to_chat(H, span_boldnotice("You shed your disguise and emerge as a true Shadow!"))

	var/datum/action/cooldown/shadowling/toggle_night_vision/nightvision = hive.grant_night_vision(H)
	nightvision?.do_effect(H)

	channeling = FALSE
	channel_caster = null
	detach_cover()
	cleanup(walls)
	walls = null
	H.alpha = prev_alpha
	remove_after_use()
	return TRUE
