// MARK: Phased Dummy

/// Incorporeal jaunting dummy carrying a Shadowling through walls while phased.
/obj/effect/dummy/phased_mob/shadowling
	parent_type = /obj/effect/dummy/phased_mob/shadow
	name = "shadows"
	phased_mob_icon_state = "purple_laser"

	/// Set TRUE for Ascended Shadowlings so bright light does not eject them.
	var/light_immunity = FALSE
	light_max = SHADOWLING_LIGHT_THRESHOLD
	movespeed = 3
	density = FALSE

	/// Seconds a non-ascended Shadowling can linger in bright light before forced ejection.
	var/light_grace_period = 5 SECONDS
	/// Remaining grace period time before bright light forces ejection.
	var/light_time_remaining = 0
	/// Last integer second announced to the jaunting mob.
	var/last_light_second = 0

/// Forwards projectile hits on the phased dummy to the jaunting mob.
/obj/effect/dummy/phased_mob/shadowling/projectile_hit(obj/projectile/hitting_projectile, def_zone, piercing_hit, blocked)
	if(jaunter)
		jaunter.bullet_act(hitting_projectile, def_zone, piercing_hit, blocked)
		return BULLET_ACT_HIT
	return BULLET_ACT_FORCE_PIERCE

/// Returns TRUE when [location_to_check] exceeds `light_max` unless `light_immunity` is set.
/obj/effect/dummy/phased_mob/shadowling/check_light_level(atom/location_to_check)
	if(light_immunity)
		return FALSE

	var/atom/place = location_to_check || src
	var/turf/T = get_turf(place)
	if(!istype(T))
		return FALSE

	var/brightness = T.get_lumcount()
	if(isnull(brightness))
		return FALSE

	return brightness > light_max

/// Tracks light exposure grace countdown, heals organic damage, and validates jaunter presence each tick.
/obj/effect/dummy/phased_mob/shadowling/process(seconds_per_tick)
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return

	if(!jaunter || jaunter.loc != src)
		qdel(src)
		return

	if(check_light_level(T))
		if(!light_time_remaining)
			light_time_remaining = light_grace_period
			last_light_second = CEILING(light_time_remaining / (1 SECONDS), 1)
			to_chat(jaunter, span_warning("The light burns away your shadow! You will be forced out in [last_light_second] seconds."))
		var/current_second = CEILING(light_time_remaining / (1 SECONDS), 1)
		if(current_second != last_light_second)
			last_light_second = current_second
			to_chat(jaunter, span_warning("The light burns away your shadow! You will be forced out in [current_second] seconds."))
		new /obj/effect/temp_visual/shadow_phase_smoke(T)
		light_time_remaining -= seconds_per_tick * (1 SECONDS)
		if(light_time_remaining <= 0)
			eject_jaunter(TRUE)
	else
		light_time_remaining = 0
		last_light_second = 0

	if(!QDELETED(jaunter) && isliving(jaunter))
		var/mob/living/living_jaunter = jaunter
		living_jaunter.heal_overall_damage(brute = (healing_rate * seconds_per_tick), burn = (healing_rate * seconds_per_tick), required_bodytype = BODYTYPE_ORGANIC)

/// Moves the phased dummy across permitted turfs when the jaunter inputs a direction.
/obj/effect/dummy/phased_mob/shadowling/relaymove(mob/living/user, direction)
	var/turf/newloc = phased_check(user, direction)
	if(!newloc)
		return
	if(direction in GLOB.alldirs)
		setDir(direction)
	forceMove(newloc)

/// Prevents non-ascended Shadowlings from phasing into space turfs.
/obj/effect/dummy/phased_mob/shadowling/phased_check(mob/living/user, direction)
	var/turf/newloc = ..()
	if(newloc && isspaceturf(newloc) && !light_immunity)
		to_chat(user, span_warning("It really would not be wise to go into space."))
		return null
	return newloc

/obj/effect/dummy/phased_mob/shadowling/Destroy()
	if(jaunter && jaunter.loc == src)
		eject_jaunter(TRUE)
	return ..()

/// Ejects [jaunter] to an open turf, resets Shadow Phase button state, and stuns briefly if forced out by light.
/obj/effect/dummy/phased_mob/shadowling/eject_jaunter(forced_out = FALSE)
	var/mob/living/L = jaunter
	var/turf/cur_turf = get_turf(src)
	if(!isopenturf(cur_turf))
		var/list/open_turfs = list()
		for(var/turf/T in get_adjacent_open_turfs(cur_turf))
			if(!T.density)
				open_turfs += T
		if(length(open_turfs))
			forceMove(pick(open_turfs))

	. = ..()

	if(istype(L))
		var/datum/action/cooldown/shadowling/shadow_phase/SP = locate(/datum/action/cooldown/shadowling/shadow_phase) in L.actions
		var/restore_alpha = SP ? SP.prev_alpha : 255
		animate(L, alpha = restore_alpha, time = 0.3 SECONDS)

		if(SP)
			SP.active = FALSE
			SP.apply_button_overlay()
			if(forced_out && !light_immunity)
				SP.StartCooldown(30 SECONDS)

		if(forced_out && !light_immunity)
			L.Knockdown(1 SECONDS)
			L.Paralyze(1 SECONDS)
