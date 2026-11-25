// MARK: Team

/// Shared team datum coordinating all Shadowlings, Lesser Shadowlings, and Thralls in the hive.
/datum/team/shadow_hive
	name = "\improper Shadow Hive"
	show_roundend_report = FALSE
	/// Active hive leader election datum, if a vote is currently running.
	var/shadowling_vote
	/// True once a hive leader election has finalized.
	var/is_shadowling_vote_finished
	/// True once Engine Sabotage has been expended this round.
	var/is_shadowling_engine_sabotage_used
	/// Cached number of living thralls required for Ascension.
	var/asc_thralls_needed = 0
	/// Elected hive leader mob, if any.
	var/mob/leader
	/// Living or dead human mobs registered as Shadowlings or Lesser Shadowlings.
	var/list/lings = list()
	/// Living or dead human mobs registered as Shadow Thralls.
	var/list/thralls = list()
	/// Map of Shadowling mob -> role constant (`SHADOWLING_ROLE_MAIN` or `SHADOWLING_ROLE_LESSER`).
	var/list/ling_roles = list()
	/// Highest thrall count observed at sync time; never decreases when thralls die.
	var/last_sync_thrall_count = 0
	/// High-water mark of living thralls reached by the hive for ability threshold unlocks.
	var/max_thralls_reached = 0
	/// True once any hive Shadowling has completed Ascension.
	var/is_ascended = FALSE
	/// True while an Ascension ritual is actively channeling.
	var/is_ascending = FALSE
	/// Debug flag enabling mindless/non-human enthrallment, fast cast, and lighting bypass.
	var/debug_mode = FALSE
	/// Tracks whether `begin_roundender()` has already fired this round.
	var/roundender_started = FALSE

/datum/team/shadow_hive/New(starting_members)
	. = ..()
	if(!GLOB.shadowling_hive || QDELETED(GLOB.shadowling_hive))
		GLOB.shadowling_hive = src

/datum/team/shadow_hive/Destroy(force)
	if(GLOB.shadowling_hive == src)
		GLOB.shadowling_hive = null
	reset_hive(clear_objectives = FALSE)
	return ..(force)

/// Resets all member tracking, team back-references, flags, and optional objectives on the hive.
/datum/team/shadow_hive/proc/reset_hive(clear_objectives = TRUE)
	for(var/mob/living/L as anything in lings)
		if(QDELETED(L))
			continue
		UnregisterSignal(L, COMSIG_QDELETING)
		var/datum/antagonist/shadowling/antag = L.mind?.has_antag_datum(/datum/antagonist/shadowling, TRUE)
		if(antag && antag.shadow_team == src)
			antag.shadow_team = null
	for(var/mob/living/T as anything in thralls)
		if(QDELETED(T))
			continue
		UnregisterSignal(T, COMSIG_QDELETING)
		var/datum/antagonist/shadowling/antag = T.mind?.has_antag_datum(/datum/antagonist/shadowling, TRUE)
		if(antag && antag.shadow_team == src)
			antag.shadow_team = null
	if(islist(members))
		for(var/datum/mind/M as anything in members)
			var/datum/antagonist/shadowling/antag = M?.has_antag_datum(/datum/antagonist/shadowling, TRUE)
			if(antag && antag.shadow_team == src)
				antag.shadow_team = null
		members.Cut()
	lings.Cut()
	thralls.Cut()
	ling_roles.Cut()
	leader = null
	QDEL_NULL(shadowling_vote)
	if(clear_objectives && islist(objectives))
		QDEL_LIST(objectives)
		objectives = list()
	is_ascended = FALSE
	is_ascending = FALSE
	is_shadowling_vote_finished = FALSE
	is_shadowling_engine_sabotage_used = FALSE
	asc_thralls_needed = 0
	last_sync_thrall_count = 0
	max_thralls_reached = 0
	show_roundend_report = FALSE
	debug_mode = FALSE
	roundender_started = FALSE

/// Refreshes explanation text on all `enslave_fraction` team objectives.
/datum/team/shadow_hive/proc/update_objective_explanations()
	if(!islist(objectives))
		return

	for(var/datum/objective/shadowling/enslave_fraction/O in objectives)
		O.update_explanation_text()

/datum/team/shadow_hive/add_member(datum/mind/new_member)
	if(!new_member || is_unassigned_job(new_member.assigned_role))
		return
	show_roundend_report = TRUE
	. = ..()
	if(!(new_member in members))
		members += new_member

/datum/team/shadow_hive/remove_member(datum/mind/old_member)
	. = ..()
	if(!old_member)
		return
	members -= old_member

/// Registers [H] into `lings` or `thralls` under [role] and grants baseline hive actions.
/datum/team/shadow_hive/proc/join_member(mob/living/carbon/human/H, role = SHADOWLING_ROLE_THRALL)
	if(!istype(H))
		return
	if(QDELETED(H))
		return
	show_roundend_report = TRUE
	lings -= H
	thralls -= H
	ling_roles -= H
	UnregisterSignal(H, COMSIG_QDELETING)
	if(role == SHADOWLING_ROLE_THRALL)
		thralls += H
	else
		lings += H
		ling_roles[H] = role
	RegisterSignal(H, COMSIG_QDELETING, PROC_REF(_on_member_qdel))
	if(H.mind && !(H.mind in members))
		members += H.mind
	sanitize()
	grant_comm_action(H)
	if(role == SHADOWLING_ROLE_THRALL || isshadowling(H) || isshadowling_ascended(H))
		grant_night_vision(H)
	update_objective_explanations()

/// Removes [H] and its mind from all hive tracking lists and unregisters qdel cleanup.
/datum/team/shadow_hive/proc/leave_member(mob/living/carbon/human/H)
	if(!istype(H))
		return
	lings -= H
	thralls -= H
	ling_roles -= H
	if(leader == H)
		leader = null
	UnregisterSignal(H, COMSIG_QDELETING)
	if(H.mind && (H.mind in members))
		members -= H.mind
	sanitize()
	update_objective_explanations()

/// Signal handler removing deleted mobs from hive tracking lists.
/datum/team/shadow_hive/proc/_on_member_qdel(mob/living/source)
	SIGNAL_HANDLER
	lings -= source
	thralls -= source
	ling_roles -= source
	if(leader == source)
		leader = null
	UnregisterSignal(source, COMSIG_QDELETING)
	if(source?.mind && (source.mind in members))
		members -= source.mind
	sanitize()
	update_objective_explanations()

/// Returns a combined list of all Shadowlings and Thralls registered in the hive.
/datum/team/shadow_hive/proc/get_all_members()
	return lings + thralls

/// Prunes qdeleted mobs, stale role entries, and orphaned mind references from hive lists.
/datum/team/shadow_hive/proc/sanitize()
	for(var/i = length(lings) to 1 step -1)
		var/mob/living/L = lings[i]
		if(QDELETED(L) || !istype(L, /mob/living))
			lings.Cut(i, i + 1)
	for(var/i = length(thralls) to 1 step -1)
		var/mob/living/T = thralls[i]
		if(QDELETED(T) || !istype(T, /mob/living))
			thralls.Cut(i, i + 1)
	for(var/mob/M as anything in ling_roles.Copy())
		if(!(M in lings))
			ling_roles -= M
	var/list/keep = list()
	for(var/mob/living/carbon/human/K in lings + thralls)
		if(K?.mind)
			keep[K.mind] = TRUE
	for(var/datum/mind/mm as anything in members.Copy())
		if(!keep[mm])
			members -= mm

/// Pure read returning the number of non-deleted, non-dead thralls in `thralls`.
/datum/team/shadow_hive/proc/count_alive_thralls()
	var/count = 0
	for(var/mob/living/carbon/human/T in thralls)
		if(QDELETED(T))
			continue
		if(T.stat == DEAD)
			continue
		count++
	return count

/// Returns the hive's high-water mark of living thralls (`max_thralls_reached`).
/datum/team/shadow_hive/proc/count_max_thralls()
	return max_thralls_reached

/// Grants the `commune` action to [H] if not already present.
/datum/team/shadow_hive/proc/grant_comm_action(mob/living/carbon/human/H)
	if(!istype(H))
		return
	for(var/datum/action/cooldown/shadowling/commune/existing in H.actions)
		return
	var/datum/action/cooldown/shadowling/commune/A = new
	A.Grant(H)

/// Grants or returns the existing `toggle_night_vision` action on [H].
/datum/team/shadow_hive/proc/grant_night_vision(mob/living/carbon/human/H)
	if(!istype(H))
		return null
	for(var/datum/action/cooldown/shadowling/toggle_night_vision/existing in H.actions)
		return existing
	var/datum/action/cooldown/shadowling/toggle_night_vision/A = new
	A.Grant(H)
	return A

/// Returns the recorded role for [H] in `ling_roles`, or null if [H] is not in `lings`.
/datum/team/shadow_hive/proc/get_ling_role(mob/living/carbon/human/H)
	if(!istype(H))
		return null
	if(!(H in lings))
		return null
	return ling_roles[H]

/// Delays an active emergency shuttle call by [delay_time] and schedules an announcement.
/datum/team/shadow_hive/proc/apply_evac_delay(delay_time = 10 MINUTES)
	if(!SSshuttle || !SSshuttle.emergency)
		return FALSE
	if(SSshuttle.emergency.mode != SHUTTLE_CALL)
		return FALSE
	var/security_num = SSsecurity_level.get_current_level_as_number()
	var/set_coefficient = 1
	switch(security_num)
		if(SEC_LEVEL_GREEN)
			set_coefficient = 2
		if(SEC_LEVEL_BLUE)
			set_coefficient = 1
		else
			set_coefficient = 0.5
	var/new_timer = SSshuttle.emergency.timeLeft(1) + delay_time
	SSshuttle.emergency.setTimer(new_timer)
	var/surplus = new_timer - (SSshuttle.emergency_call_time * set_coefficient)
	if(surplus > 0)
		SSshuttle.block_recall(surplus)
	var/mins = round(delay_time / (1 MINUTES))
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(priority_announce), "Power fluctuations detected in the reactor circuit. Emergency shuttle arrival delayed by [mins] minutes.", "Priority Announcement", 'sound/announcer/announcement/announce_syndi.ogg', null, "[command_name()]: Transportation Division"), rand(2 SECONDS, 6 SECONDS))
	return TRUE

/// Swaps [H] between the Ascended and hatched Shadowling species and updates `is_ascended`.
/datum/team/shadow_hive/proc/shadowling_set_ascended(mob/living/carbon/human/H, ascended = TRUE)
	if(!istype(H))
		return
	if(ascended)
		H.set_species(/datum/species/shadow/shadowling/ascended)
		is_ascended = TRUE
	else
		H.set_species(/datum/species/shadow/shadowling)

/// Creates the default hive objectives if none exist yet and caches the thrall requirement.
/datum/team/shadow_hive/proc/setup_objectives()
	show_roundend_report = TRUE
	if(length(objectives))
		return

	add_objective(new /datum/objective/shadowling/enslave_fraction)
	add_objective(new /datum/objective/shadowling/ascend)

	refresh_ascension_thralls_needed()

/// Returns the hive's team objective list.
/datum/team/shadow_hive/proc/get_objectives()
	return objectives

/// Convenience wrapper to run `sync_hive(actor)` after a lifecycle event.
/datum/team/shadow_hive/proc/sync_after_event(mob/living/carbon/human/actor)
	sync_hive(actor)

/// Synchronizes [actor]'s unlocked abilities against `max_thralls_reached` and form state.
/datum/team/shadow_hive/proc/sync_hive(mob/living/carbon/human/actor)
	if(!istype(actor))
		return
	sanitize()
	refresh_ascension_thralls_needed()
	update_objective_explanations()
	if((actor in lings) && !isshadowling(actor) && !isshadowling_ascended(actor))
		return

	var/actor_role = get_ling_class(actor)
	if(isshadowling_ascended(actor))
		for(var/datum/action/cooldown/shadowling/ability in actor.actions.Copy())
			if(istype(ability, /datum/action/cooldown/shadowling/engine_sabotage))
				continue
			if(istype(ability, /datum/action/cooldown/shadowling/ascend) || \
			   istype(ability, /datum/action/cooldown/shadowling/hatch) || \
			   istype(ability, /datum/action/cooldown/shadowling/election) || \
			   !role_allowed(ability.type, actor_role, actor))
				ability.Remove(actor)
				qdel(ability)
	else if(isshadowling(actor))
		for(var/datum/action/cooldown/shadowling/old_hatch in actor.actions.Copy())
			if(istype(old_hatch, /datum/action/cooldown/shadowling/hatch))
				old_hatch.Remove(actor)
				qdel(old_hatch)

	var/alive_count = count_alive_thralls()
	max_thralls_reached = max(max_thralls_reached, alive_count)
	last_sync_thrall_count = max_thralls_reached

	var/list/new_unlocks = grant_unlocks_for(actor, max_thralls_reached)

	if(actor in thralls)
		if(length(new_unlocks))
			to_chat(actor, span_notice("Hive synchronized. New abilities unlocked: [jointext(new_unlocks, ", ")]."))
		else
			to_chat(actor, span_notice("Hive synchronized. No new abilities unlocked."))
		return

	if(length(new_unlocks))
		to_chat(actor, span_notice("Hive synchronized: [alive_count] living thralls. New abilities unlocked: [jointext(new_unlocks, ", ")]."))
	else
		to_chat(actor, span_notice("Hive synchronized: [alive_count] living thralls. No new abilities unlocked."))

/// Returns TRUE if [H] already owns an action matching [action_type].
/datum/team/shadow_hive/proc/has_action_of_type(mob/living/carbon/human/H, action_type)
	for(var/datum/action/A in H.actions)
		if(istype(A, action_type))
			return TRUE
	return FALSE

/// Resolves [H]'s role constant from this hive (`SHADOWLING_ROLE_THRALL`, `LESSER`, or `MAIN`).
/datum/team/shadow_hive/proc/get_ling_class(mob/living/carbon/human/H)
	if(H in thralls)
		return SHADOWLING_ROLE_THRALL
	if(H in lings)
		return get_ling_role(H) || SHADOWLING_ROLE_MAIN
	return null

/// Checks whether [sample] ability path is permitted for [ling_role] and [H]'s individual ascension state.
/datum/team/shadow_hive/proc/role_allowed(datum/action/cooldown/shadowling/sample, ling_role, mob/living/carbon/human/H)
	var/flags = initial(sample.role_flags)
	if(!flags)
		return FALSE
	if(ispath(sample, /datum/action/cooldown/shadowling/election) && is_shadowling_vote_finished)
		return FALSE

	var/datum/antagonist/shadowling/antag_datum = H?.mind?.has_antag_datum(/datum/antagonist/shadowling, FALSE)
	var/ascended = (ling_role != SHADOWLING_ROLE_LESSER) && (antag_datum?.is_ascended || (H && isshadowling_ascended(H)))

	if(ascended)
		if(ispath(sample, /datum/action/cooldown/shadowling/ascend) || ispath(sample, /datum/action/cooldown/shadowling/hatch))
			return FALSE
		return !!(flags & SL_ASCENDED)

	if(isshadowling(H) && ispath(sample, /datum/action/cooldown/shadowling/hatch))
		return FALSE

	switch(ling_role)
		if(SHADOWLING_ROLE_THRALL)
			return !!(flags & SL_THRALL)
		if(SHADOWLING_ROLE_LESSER)
			return !!(flags & SL_LESSER)
		else
			return !!(flags & (SL_INNATE | SL_THRESHOLD))

/// Computes the living thrall count required to unlock threshold ability [sample] (optionally overriding percentage).
/datum/team/shadow_hive/proc/get_required_thralls_for(datum/action/cooldown/shadowling/sample, percent_override = null)
	var/percent = clamp(isnull(percent_override) ? initial(sample.required_thralls) : percent_override, 0, 100)
	if(percent <= 0)
		return 0

	var/asc_need = get_ascension_thralls_needed()
	var/count = ceil(asc_need * (percent / 100))
	var/min_r = initial(sample.min_req)
	var/max_r = initial(sample.max_req)
	if(max_r > 0)
		return clamp(count, min_r, max_r)
	return max(count, min_r)

/// Grants all eligible Shadowling abilities for [H] given [thrall_count] and returns their names.
/datum/team/shadow_hive/proc/grant_unlocks_for(mob/living/carbon/human/H, thrall_count)
	if(!istype(H))
		return list()

	var/ling_class = get_ling_class(H)
	if(!ling_class)
		return list()
	if(ling_class == SHADOWLING_ROLE_MAIN && !isshadowling(H) && !isshadowling_ascended(H))
		return list()

	var/datum/antagonist/shadowling/antag_datum = H?.mind?.has_antag_datum(/datum/antagonist/shadowling, FALSE)
	var/ascended = (ling_class != SHADOWLING_ROLE_LESSER) && (antag_datum?.is_ascended || isshadowling_ascended(H))

	var/list/unlocked_names = list()

	for(var/path in subtypesof(/datum/action/cooldown/shadowling))
		var/datum/action/cooldown/shadowling/sample = path
		if(!initial(sample.role_flags))
			continue
		if(has_action_of_type(H, path))
			continue
		if(!role_allowed(sample, ling_class, H))
			continue
		if(!ascended)
			var/req_count = get_required_thralls_for(sample)
			if(thrall_count < req_count)
				continue

		var/datum/action/cooldown/shadowling/A = new path()
		A.Grant(H)
		var/n = initial(sample.name)
		if(n)
			unlocked_names += "[n]"

	return unlocked_names

/// Converts a Shadow Thrall or Shadowling [target] into a Lesser Shadowling without duplicate syncs.
/datum/team/shadow_hive/proc/convert_to_lesser(mob/living/carbon/human/target)
	if(!istype(target) || QDELETED(target) || !target.mind)
		return FALSE

	var/datum/antagonist/shadow_thrall/old_thrall = target.mind.has_antag_datum(/datum/antagonist/shadow_thrall, FALSE)
	if(old_thrall)
		old_thrall.silent = TRUE

	var/obj/item/organ/brain/shadow/tumor_thrall/old_tumor = target.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL)
	if(istype(old_tumor))
		old_tumor.mob_remove(target, special = TRUE)
		qdel(old_tumor)

	var/datum/antagonist/shadowling/existing_ling = target.mind.has_antag_datum(/datum/antagonist/shadowling, FALSE)
	if(existing_ling)
		if(existing_ling.is_ascended)
			existing_ling.set_higher(FALSE)
		existing_ling.set_lesser()
		if(!isshadowling(target) && !isshadowling_ascended(target))
			target.shadowling_strip_quirks()
			target.reset_robotic_limbs()
			if(!existing_ling.original_species)
				existing_ling.original_species = target.dna?.species
			target.set_species(/datum/species/shadow/shadowling)
		target.refresh_eye_overlays()
		for(var/datum/action/cooldown/ability in target.actions.Copy())
			if(istype(ability, /datum/action/cooldown/shadowling))
				ability.Remove(target)
				qdel(ability)
		join_member(target, SHADOWLING_ROLE_LESSER)
		sync_after_event(target)
		to_chat(target, span_danger("The hive reshapes your essence — you are now a Lesser Shadowling!"))
		return TRUE

	target.shadowling_strip_quirks()
	target.reset_robotic_limbs()
	var/datum/species/pre_species = target.dna?.species
	target.set_species(/datum/species/shadow/shadowling)

	for(var/datum/action/cooldown/ability in target.actions.Copy())
		if(istype(ability, /datum/action/cooldown/shadowling))
			ability.Remove(target)
			qdel(ability)

	if(old_thrall)
		target.mind.remove_antag_datum(/datum/antagonist/shadow_thrall)

	var/datum/antagonist/shadowling/new_antag = new
	new_antag.set_lesser()
	new_antag.original_species = pre_species
	new_antag.shadow_team = src
	target.mind.add_antag_datum(new_antag)
	target.refresh_eye_overlays()
	return TRUE

/// Spawns a spreading shadow smoke cloud centered at [where] owned by [holder].
/datum/team/shadow_hive/proc/spawn_smoke(turf/where, mob/living/holder, r = 4, ticks = 6, heal = 10, blind = 5 SECONDS, schance = 25, stun = 2 SECONDS)
	if(!istype(where))
		return
	var/datum/effect_system/fluid_spread/smoke/shadow/shadow_smoke = new(where, r, null, holder, ticks, heal, blind, schance, stun)
	shadow_smoke.start()

/// Triggers the one-time Ascension roundend announcement, music, shuttle lockdown, and evac call.
/datum/team/shadow_hive/proc/begin_roundender(mob/living/carbon/human/ascended = null)
	if(roundender_started)
		return
	roundender_started = TRUE

	send_to_playing_players("<span class='shadowradio_win'><b>THE UNIFIED SHADOW CONSUMES THE STATION!</b></span>")
	for(var/mob/player as anything in GLOB.player_list)
		if(player && !isnewplayer(player))
			SEND_SOUND(player, sound(SHADOWLING_RISEN_MUSIC, volume = 70))

	priority_announce(
		text = "Caution! Our long-range sensors have detected an unprecedented surge of paranormal activity. Due to imminent station consumption, immediately mobilize all assets and initiate emergency evacuation procedures. Emergency shuttle launch is authorized and irreversible.",
		title = "[command_name()]: Paranormal Phenomenon Division",
		sound = SSstation.announcer.get_rand_report_sound(),
		has_important_message = TRUE,
	)

	var/datum/hostile_ref = ascended || src
	if(hostile_ref)
		SSshuttle.registerHostileEnvironment(hostile_ref)
	SSshuttle.lockdown = TRUE
	if(!QDELETED(ascended) && get_area(ascended))
		SSshuttle.requestEvac(ascended, "Emergency evacuation authorized due to paranormal threat.")
	else if(SSshuttle.emergency && SSshuttle.canEvac() == TRUE)
		SSshuttle.call_evac_shuttle("Emergency evacuation authorized due to paranormal threat.", null)

/// Grants the `hatch` action to unhatched Shadowling [H] if not already hatched or granted.
/datum/team/shadow_hive/proc/shadowling_grant_hatch(mob/living/carbon/human/H)
	if(!istype(H))
		return null
	if(isshadowling(H) || isshadowling_ascended(H))
		return null
	for(var/datum/action/cooldown/shadowling/hatch/X in H.actions)
		return X
	var/datum/action/cooldown/shadowling/hatch/A = new
	A.Grant(H)
	return A

/// Snapshots ready players or current crewmember minds as the scaling baseline (minimum 1).
/datum/team/shadow_hive/proc/compute_crew_baseline()
	var/baseline = 0
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.ready == PLAYER_READY_TO_PLAY)
			baseline++

	if(!baseline)
		baseline = length(get_crewmember_minds())

	return max(1, baseline)

/// Side-effect-free calculation of living thralls required for Ascension.
/datum/team/shadow_hive/proc/compute_ascension_thralls_needed()
	var/datum/objective/shadowling/enslave_fraction/obj = null
	if(islist(objectives))
		obj = (locate(/datum/objective/shadowling/enslave_fraction) in objectives)

	if(obj)
		return max(1, obj.required_thralls())

	var/baseline = compute_crew_baseline()
	return max(1, CEILING((baseline * SHADOWLING_ASCEND_DEFAULT_PERCENT) / 100, 1))

/// Returns the cached thrall threshold, or computes it without mutating state if unset.
/datum/team/shadow_hive/proc/get_ascension_thralls_needed()
	if(asc_thralls_needed > 0)
		return asc_thralls_needed
	return compute_ascension_thralls_needed()

/// Recomputes and caches `asc_thralls_needed`.
/datum/team/shadow_hive/proc/refresh_ascension_thralls_needed()
	asc_thralls_needed = compute_ascension_thralls_needed()
	return asc_thralls_needed
