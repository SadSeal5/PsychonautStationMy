// MARK: Effects

/// Temporary red spark tile highlighting the Glare cone.
/obj/effect/temp_visual/shadowling/glare_cone_tile
	name = "glare cone"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_GAME_PLANE
	layer = EFFECTS_LAYER
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	alpha = 180
	color = "#ff2a2a"

/obj/effect/temp_visual/shadowling/glare_cone_tile/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = 6)
	QDEL_IN(src, 0.6 SECONDS)
	return .

// MARK: Movespeed Modifier

/// Temporary slow applied to targets hit by Glare.
/datum/movespeed_modifier/shadowling/glare_slow
	multiplicative_slowdown = 1.35
	priority = 20
	movetypes = GROUND

// MARK: Ability

/// Innate cone attack stunning, stamina-damaging, blinding, silencing, and knocking down enemies.
/datum/action/cooldown/shadowling/glare
	name = "Glare"
	desc = "A terrifying gaze in your facing direction that stuns and disorients enemies."
	button_icon_state = "shadow_glare"
	cooldown_time = 15 SECONDS
	role_flags = SL_INNATE | SL_LESSER | SL_ASCENDED
	required_thralls = 0
	max_range = 3
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	channel_time = 0
	var/const/fov_degree = 90
	var/const/baton_stamina = 70
	var/const/knock_delay = 0.6 SECONDS
	var/const/knock_time = 4 SECONDS

/// Collects non-hive human targets inside the Glare front cone within `max_range`.
/datum/action/cooldown/shadowling/glare/collect_targets(mob/living/carbon/human/H, atom/explicit)
	var/list/targets = list()
	for(var/mob/living/carbon/human/T in view(max_range, H))
		if(T == H)
			continue
		if(!in_front_cone(H, T, fov_degree))
			continue
		if(is_hive_ally(T))
			continue
		targets += T
	return targets

/datum/action/cooldown/shadowling/glare/validate_target(mob/living/carbon/human/H, atom/target)
	var/mob/living/carbon/human/T = target
	if(!istype(T))
		return FALSE
	if(!in_front_cone(H, T, fov_degree))
		return FALSE
	var/turf/tt = get_turf(T)
	if(!tt)
		return FALSE
	return TRUE

/datum/action/cooldown/shadowling/glare/do_effect_on_targets(mob/living/carbon/human/H, list/targets)
	if(!istype(H))
		return FALSE
	play_glare_fx(H)
	if(!length(targets))
		H.balloon_alert(H, "missed")
		return TRUE
	for(var/mob/living/carbon/human/T in targets)
		if(QDELETED(T) || T.stat == DEAD)
			continue
		if(get_dist(H, T) > max_range)
			continue
		apply_glare_primary(T)
		addtimer(CALLBACK(T, TYPE_PROC_REF(/mob/living, Knockdown), knock_time), knock_delay)
	return TRUE

/// Applies stun, stamina loss, temp blindness, blur, silence, slow, and screen shake to [T].
/datum/action/cooldown/shadowling/glare/proc/apply_glare_primary(mob/living/carbon/human/T)
	if(!istype(T))
		return
	T.Stun(5 SECONDS)
	T.adjust_stamina_loss(baton_stamina)
	T.set_temp_blindness(2 SECONDS)
	T.adjust_eye_blur(4 SECONDS)
	T.adjust_silence(4 SECONDS)
	apply_timed_slow(T, /datum/movespeed_modifier/shadowling/glare_slow, 5 SECONDS)
	apply_shake(T, 2, 0.6 SECONDS)

/// Emits red light flash, cone tile visuals, and ghost shriek sound from [H].
/datum/action/cooldown/shadowling/glare/proc/play_glare_fx(mob/living/carbon/human/H)
	if(!istype(H))
		return
	H.set_light(2, 0.6, "#ff2a2a")
	addtimer(CALLBACK(H, TYPE_PROC_REF(/atom, set_light), 0), 0.6 SECONDS)
	show_cone_fx(H)
	playsound(H, 'sound/effects/ghost2.ogg', 50, vary = TRUE, ignore_walls = FALSE)

/// Applies dizziness and camera shake to [L].
/datum/action/cooldown/shadowling/glare/proc/apply_shake(mob/living/L, strength, dur)
	if(!istype(L))
		return
	L.adjust_dizzy(dur)
	shake_camera(L, duration = dur, strength = strength)

/// Spawns temporary red spark markers across every turf in the Glare cone.
/datum/action/cooldown/shadowling/glare/proc/show_cone_fx(mob/living/carbon/human/H)
	if(!istype(H))
		return
	var/list/cone_turfs = collect_cone_turfs(H, max_range, fov_degree)
	if(!length(cone_turfs))
		return
	for(var/turf/T as anything in cone_turfs)
		new /obj/effect/temp_visual/shadowling/glare_cone_tile(T)
