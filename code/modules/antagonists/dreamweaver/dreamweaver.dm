/datum/antagonist/dreamweaver
	name = "\improper Dreamweaver"
	antagpanel_category = ANTAG_GROUP_ABOMINATIONS
	pref_flag = ROLE_DREAMWEAVER
	show_in_antagpanel = TRUE
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	ui_name = "AntagInfoGeneric"
	suicide_cry = "FOR THE COLLECTIVE UNCONSCIOUS!!"
	preview_outfit = /datum/outfit/dreamweaver
	stinger_sound = 'sound/effects/magic/ethereal_exit.ogg'

	var/psi_charges = 50
	var/psi_max = 100
	var/cascade_used = FALSE
	var/list/mind_web_targets

/datum/antagonist/dreamweaver/greet()
	. = ..()
	to_chat(owner.current, span_reallybig(span_boldannounce("You are the Dreamweaver!")))
	to_chat(owner.current, span_boldnotice("Manipulate reality and warp the consciousness of the station's crew."))
	to_chat(owner.current, span_notice("You gain psychic energy in darkness, but suffer in bright light. Use your abilities to spread hallucinations and weave minds into your web."))
	owner.announce_objectives()

/datum/antagonist/dreamweaver/on_gain()
	forge_objectives()
	. = ..()
	var/datum/job/dreamweaver/job = SSjob.get_job_type(/datum/job/dreamweaver)
	if(job)
		owner.set_assigned_role(job)
	if(ishuman(owner.current))
		var/mob/living/carbon/human/human_owner = owner.current
		if(human_owner.dna?.species?.id != SPECIES_DREAMWEAVER)
			human_owner.set_species(/datum/species/shadow/dreamweaver)

/datum/antagonist/dreamweaver/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	if(ishuman(new_body))
		var/mob/living/carbon/human/human_target = new_body
		if(human_target.dna?.species?.id != SPECIES_DREAMWEAVER)
			human_target.set_species(/datum/species/shadow/dreamweaver)

/datum/antagonist/dreamweaver/forge_objectives()
	var/datum/objective/dreamweaver_fluff/objective = new()
	objective.owner = owner
	objectives += objective

/datum/antagonist/dreamweaver/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/dreamweaver = mob_override || owner.current
	if(dreamweaver?.mob_mood)
		dreamweaver.mob_mood.mood_modifier -= 1
	dreamweaver.apply_status_effect(/datum/status_effect/dreamweaver_power)

/datum/antagonist/dreamweaver/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/dreamweaver = mob_override || owner.current
	if(dreamweaver?.mob_mood)
		dreamweaver.mob_mood.mood_modifier += 1
	dreamweaver.remove_status_effect(/datum/status_effect/dreamweaver_power)

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
