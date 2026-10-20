// MARK: Global procedure
/proc/shadow_spawn_smoke(turf/where, mob/living/holder, r = 4, ticks = 6, heal = 10, blind = 5 SECONDS, schance = 25, stun = 2 SECONDS)
	if(!istype(where))
		return
	var/datum/effect_system/fluid_spread/smoke/shadow/shadow_smoke = new(where, r, null, holder, ticks, heal, blind, schance, stun)
	shadow_smoke.start()

// MARK: Effects
/obj/effect/particle_effect/fluid/smoke/shadow
	name = "shadow smoke"
	opacity = FALSE
	lifetime = 10 SECONDS
	color = "#000000"
	alpha = 220
	var/heal_amount = 10
	var/blind_time = 5 SECONDS
	var/stun_chance = 25
	var/stun_time = 2 SECONDS

/obj/effect/particle_effect/fluid/smoke/shadow/smoke_mob(mob/living/carbon/smoker, seconds_per_tick)
	if(!..())
		return FALSE
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	var/is_ally = FALSE
	if(hive)
		is_ally = (smoker in hive.lings) || (smoker in hive.thralls)

	if(is_ally)
		smoker.adjust_brute_loss(-heal_amount)
		smoker.adjust_fire_loss(-heal_amount)
		smoker.adjust_tox_loss(-heal_amount)
		smoker.adjust_oxy_loss(-heal_amount)
		var/mob/living/carbon/C = smoker
		if(istype(C))
			C.adjust_stamina_loss(-heal_amount)
	else
		var/mob/living/carbon/C2 = smoker
		if(istype(C2))
			C2.adjust_temp_blindness(blind_time)
		if(prob(stun_chance))
			smoker.Stun(stun_time)
	return TRUE

/datum/effect_system/fluid_spread/smoke/shadow
	effect_type = /obj/effect/particle_effect/fluid/smoke/shadow
	var/smoke_range = 4
	var/smoke_ticks = 6
	var/heal_amount = 10
	var/blind_time = 5 SECONDS
	var/stun_chance = 25
	var/stun_time = 2 SECONDS

/datum/effect_system/fluid_spread/smoke/shadow/New(turf/location, range = 1, amount = null, atom/holder = null, ticks = 6, heal = 10, blind = 5 SECONDS, schance = 25, stun = 2 SECONDS)
	. = ..(location, range, amount, holder)
	smoke_range = range
	smoke_ticks = ticks
	heal_amount = heal
	blind_time = blind
	stun_chance = schance
	stun_time = stun

/datum/effect_system/fluid_spread/smoke/shadow/start(log = FALSE)
	var/turf/center = location || get_turf(holder)
	if(!center)
		return
	var/datum/fluid_group/G = new /datum/fluid_group
	var/list/visited = list()
	var/list/queue = list()
	visited[center] = 0
	queue += center
	while(length(queue))
		var/turf/current = queue[1]
		queue.Cut(1, 2)
		var/dist = visited[current]
		var/life_secs = max(smoke_ticks - dist, 0)
		if(life_secs > 0)
			var/obj/effect/particle_effect/fluid/smoke/shadow/node = new /obj/effect/particle_effect/fluid/smoke/shadow(current, G)
			node.heal_amount = heal_amount
			node.blind_time = blind_time
			node.stun_chance = stun_chance
			node.stun_time = stun_time
			node.lifetime = life_secs SECONDS
		if(dist >= smoke_range)
			continue
		for(var/turf/N in current.get_atmos_adjacent_turfs())
			if(isnull(visited[N]))
				visited[N] = dist + 1
				queue += N

// MARK: Deprecated Ability
/// Shadow Smoke has been merged into Shadow Veil.
/// Left-click triggers Shadow Veil, Right-click triggers Shadow Smoke.
/datum/action/cooldown/shadowling/shadow_smoke
	name = "Shadow Smoke (Merged)"
	desc = "Shadow Smoke has been merged into Shadow Veil. Use Shadow Veil with Right-Click to emit smoke."
	button_icon_state = "shadow_smoke"
