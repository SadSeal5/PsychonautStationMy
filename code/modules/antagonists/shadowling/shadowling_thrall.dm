// MARK: Antagonist

/// Antagonist datum for crewmembers enthralled by a Shadowling.
/datum/antagonist/shadow_thrall
	parent_type = /datum/antagonist/shadowling
	name = "Shadow Thrall"
	antagpanel_category = "Shadowling"
	antag_hud_name = "shadowling_thrall"

	is_thrall = TRUE
	ling_role = SHADOWLING_ROLE_THRALL

/datum/antagonist/shadow_thrall/can_be_owned(datum/mind/new_owner)
	if(new_owner?.has_antag_datum(/datum/antagonist/shadowling, TRUE))
		return FALSE
	return ..()

/// Sends the thrall greeting, plays the stinger, and announces objectives.
/datum/antagonist/shadow_thrall/greet()
	if(silent || !owner?.current)
		return
	play_stinger()
	to_chat(owner.current, span_userdanger("A freezing whisper permeates your mind... You have been enslaved as a Shadow Thrall!"))
	to_chat(owner.current, span_boldnotice("Obey your Shadowling masters and help them achieve Ascension."))
	owner.announce_objectives()
	antag_memory += "You were enthralled into the <b>Shadow Hive</b> as a Shadow Thrall.<br>"

/// Notifies the mind that it has been freed from thralldom.
/datum/antagonist/shadow_thrall/farewell()
	if(silent || !owner?.current)
		return
	to_chat(owner.current, span_notice("The binding cold recedes from your mind. You are yourself once more!"))

/// Returns the hive status summary displayed in the admin antag panel.
/datum/antagonist/shadow_thrall/antag_panel_data()
	var/datum/team/shadow_hive/hive = get_hive()
	var/alive_thralls = hive ? hive.count_alive_thralls() : 0
	var/needed_thralls = hive ? hive.get_ascension_thralls_needed() : 0
	var/alive_lings = 0
	if(hive)
		for(var/mob/living/carbon/human/ling in hive.lings)
			if(!QDELETED(ling) && ling.stat != DEAD)
				alive_lings++
	return "Role: Thrall | Hive Shadowlings: [alive_lings] | Hive Thralls: [alive_thralls]/[needed_thralls]"

/// Registers the thrall in the hive and inserts the thrall tumor if missing.
/datum/antagonist/shadow_thrall/on_gain()
	. = ..()

	var/mob/living/carbon/H = owner?.current
	if(istype(H) && !H.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL))
		var/obj/item/organ/brain/shadow/tumor_thrall/tumor = new
		tumor.Insert(H)

/// Strips the thrall tumor from the old body and ensures the new body receives one after mind transfer.
/datum/antagonist/shadow_thrall/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	if(old_body == new_body)
		return

	if(iscarbon(old_body))
		var/mob/living/carbon/old_carbon = old_body
		var/obj/item/organ/brain/shadow/tumor_thrall/old_tumor = old_carbon.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL)
		if(istype(old_tumor))
			old_tumor.mob_remove(old_carbon, special = TRUE)
			qdel(old_tumor)

	var/mob/living/carbon/H = new_body
	if(istype(H) && !H.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL))
		var/obj/item/organ/brain/shadow/tumor_thrall/tumor = new
		tumor.Insert(H)

/// Removes any remaining thrall tumor after the antagonist datum leaves the mind.
/datum/antagonist/shadow_thrall/on_removal()
	. = ..()
	// Run after the parent: mob_remove() clears the organ slot before calling on_mob_remove(),
	// so the tumor's own remove_antag_datum() cannot re-enter this proc in a loop.
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H))
		return
	var/obj/item/organ/brain/shadow/tumor_thrall/tumor = H.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL)
	if(istype(tumor))
		tumor.Remove(H)

// MARK: Objectives

/// Base objective type for Shadow Thralls.
/datum/objective/shadow_thrall
	name = "Thrall Objective"
	admin_grantable = TRUE

/// Requires the thrall to survive the round while still enthralled.
/datum/objective/shadow_thrall/survive
	name = "Survive"
	explanation_text = "Survive until the end of the round while remaining a thrall of the Shadow."

/datum/objective/shadow_thrall/survive/check_completion()
	if(!owner || !owner.current)
		return FALSE
	if(owner.current.stat == DEAD)
		return FALSE
	return !!owner.has_antag_datum(/datum/antagonist/shadow_thrall, TRUE)

/// Succeeds if at least one hive Shadowling reaches the Ascended species.
/datum/objective/shadow_thrall/assist_ascension
	name = "Assist Ascension"
	explanation_text = "Help the shadowlings ascend: at least one Ascended Shadowling must exist by the end of the round."

/datum/objective/shadow_thrall/assist_ascension/check_completion()
	var/datum/team/shadow_hive/hive = team || GLOB.shadowling_hive
	if(!hive || QDELETED(hive))
		return FALSE
	if(hive.is_ascended)
		return TRUE
	for(var/mob/living/carbon/human/L in hive.lings)
		if(isshadowling_ascended(L))
			return TRUE
	return FALSE

/// Succeeds if any hive Shadowling is alive or ascended at roundend.
/datum/objective/shadow_thrall/save_shadowlings
	name = "Save your Masters"
	explanation_text = "If the shadowlings are dead or missing: rally the thralls, gather your strength, and find and save your Masters."

/datum/objective/shadow_thrall/save_shadowlings/check_completion()
	var/datum/team/shadow_hive/hive = team || GLOB.shadowling_hive
	if(!hive || QDELETED(hive))
		return FALSE
	for(var/mob/living/carbon/human/L in hive.lings)
		if(isshadowling_ascended(L) || (L.stat != DEAD && !QDELETED(L)))
			return TRUE
	return FALSE
