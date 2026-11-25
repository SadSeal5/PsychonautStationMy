// MARK: Ability

/// One-time hive leader ability delaying the emergency shuttle arrival by 10 minutes.
/datum/action/cooldown/shadowling/engine_sabotage
	name = "Engine Sabotage"
	desc = "Call upon the Unified Shadow to disrupt the evacuation shuttle engines, delaying its arrival by 10 minutes."
	button_icon_state = "shadow_sabotage"
	cooldown_time = 0
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	max_range = 0
	channel_time = 0

/// Checks whether Engine Sabotage has not yet been used this round.
/datum/action/cooldown/shadowling/engine_sabotage/IsAvailable(feedback = FALSE)
	if(!..())
		return FALSE
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	if(!hive)
		return FALSE
	if(hive.is_shadowling_engine_sabotage_used)
		if(feedback && owner)
			to_chat(owner, span_warning("Engine Sabotage has already been used this round."))
		return FALSE
	return TRUE

/datum/action/cooldown/shadowling/engine_sabotage/Grant(mob/grantee)
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	if(!hive)
		return FALSE
	if(hive.is_shadowling_engine_sabotage_used)
		qdel(src)
		return FALSE
	return ..()

/// Delays the evac shuttle by 10 minutes, marks sabotage used, and removes it from the hive.
/datum/action/cooldown/shadowling/engine_sabotage/do_effect(mob/living/carbon/human/H, atom/_)
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	if(!hive)
		return FALSE
	if(hive.is_shadowling_engine_sabotage_used)
		return FALSE
	var/success = hive.apply_evac_delay(10 MINUTES)
	if(!success)
		return FALSE
	hive.is_shadowling_engine_sabotage_used = TRUE
	to_chat(H, span_boldnotice("You disrupt the power conduits — evacuation is delayed by 10 minutes."))
	cleanup_from_all_hive(hive)
	remove_after_use()
	return TRUE

/// Removes all Engine Sabotage actions from every Shadowling and thrall in [hive].
/datum/action/cooldown/shadowling/engine_sabotage/proc/cleanup_from_all_hive(datum/team/shadow_hive/hive)
	if(!hive)
		return
	for(var/mob/living/carbon/human/M as anything in hive.get_all_members())
		remove_from_mob(M)

/datum/action/cooldown/shadowling/engine_sabotage/proc/remove_from_mob(mob/living/carbon/human/M)
	if(!istype(M))
		return
	for(var/datum/action/cooldown/shadowling/engine_sabotage/A in M.actions)
		A.Remove(M)
		qdel(A)
