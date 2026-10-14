/datum/antagonist/dreamweaver
	name = "\improper Dreamweaver"
	antagpanel_category = ANTAG_GROUP_ABOMINATIONS
	pref_flag = ROLE_DREAMWEAVER
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	ui_name = "AntagInfoGeneric"
	suicide_cry = "FOR THE COLLECTIVE UNCONSCIOUS!!"
	preview_outfit = /datum/outfit/dreamweaver

	var/psi_charges = 50
	var/psi_max = 100
	var/cascade_used = FALSE
	var/list/mind_web_targets

/datum/antagonist/dreamweaver/greet()
	. = ..()
	owner.announce_objectives()

/datum/antagonist/dreamweaver/on_gain()
	forge_objectives()
	. = ..()
	var/datum/job/dreamweaver/job = SSjob.get_job_type(/datum/job/dreamweaver)
	if(job)
		owner.set_assigned_role(job)
	if(iscarbon(owner.current))
		var/mob/living/carbon/carbon_owner = owner.current
		var/obj/item/organ/brain/shadow/dreamweaver/brain = carbon_owner.get_organ_slot(ORGAN_SLOT_BRAIN)
		if(!istype(brain))
			brain = new()
			brain.Insert(carbon_owner, special = TRUE, movement_flags = DELETE_IF_REPLACED)

/datum/antagonist/dreamweaver/forge_objectives()
	var/datum/objective/dreamweaver_fluff/objective = new()
	objective.owner = owner
	objectives += objective

/datum/antagonist/dreamweaver/apply_innate_effects(mob/living/mob_override)
	var/mob/living/dreamweaver = mob_override || owner.current
	if(dreamweaver?.mob_mood)
		dreamweaver.mob_mood.mood_modifier -= 1

/datum/antagonist/dreamweaver/remove_innate_effects(mob/living/mob_override)
	var/mob/living/dreamweaver = mob_override || owner.current
	if(dreamweaver?.mob_mood)
		dreamweaver.mob_mood.mood_modifier += 1

/datum/antagonist/dreamweaver/on_removal()
	LAZYNULL(mind_web_targets)
	return ..()

/datum/antagonist/dreamweaver/Destroy()
	LAZYNULL(mind_web_targets)
	return ..()

/datum/outfit/dreamweaver
	name = "Dreamweaver (Preview only)"

/datum/outfit/dreamweaver/post_equip(mob/living/carbon/human/human, visuals_only)
	human.set_species(/datum/species/shadow/dreamweaver)

/datum/job/dreamweaver
	title = ROLE_DREAMWEAVER

