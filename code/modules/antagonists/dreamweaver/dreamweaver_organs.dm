/datum/action/cooldown/spell/touch/mind_touch
/datum/action/cooldown/spell/aoe/dread_wave
/datum/action/cooldown/spell/jaunt/astral_walk
/datum/action/cooldown/spell/pointed/mind_web
/datum/action/cooldown/spell/aoe/nightmare_cascade

/obj/item/organ/brain/shadow/dreamweaver
	name = "psionic mass"
	desc = "A pulsating growth extracted from the skull of a Dreamweaver. It hums with psychic energy."
	icon = 'icons/obj/medical/organs/organs.dmi'
	icon_state = "brain-x-d"
	shade_color = "violet"

	var/datum/action/cooldown/spell/touch/mind_touch/mind_touch_spell
	var/datum/action/cooldown/spell/aoe/dread_wave/dread_wave_spell
	var/datum/action/cooldown/spell/jaunt/astral_walk/astral_walk_spell
	var/datum/action/cooldown/spell/pointed/mind_web/mind_web_spell
	var/datum/action/cooldown/spell/aoe/nightmare_cascade/cascade_spell

/obj/item/organ/brain/shadow/dreamweaver/on_mob_insert(mob/living/carbon/brain_owner)
	. = ..()

	if(brain_owner.dna.species.id != SPECIES_DREAMWEAVER)
		brain_owner.set_species(/datum/species/shadow/dreamweaver, replace_missing = FALSE)
		visible_message(span_warning("[brain_owner] thrashes as [src] takes root in [brain_owner.p_their()] body!"))

	mind_touch_spell = new(brain_owner)
	mind_touch_spell.Grant(brain_owner)

	dread_wave_spell = new(brain_owner)
	dread_wave_spell.Grant(brain_owner)

	astral_walk_spell = new(brain_owner)
	astral_walk_spell.Grant(brain_owner)

	mind_web_spell = new(brain_owner)
	mind_web_spell.Grant(brain_owner)

	cascade_spell = new(brain_owner)
	if(brain_owner.mind?.has_antag_datum(/datum/antagonist/dreamweaver))
		cascade_spell.Grant(brain_owner)

/obj/item/organ/brain/shadow/dreamweaver/on_mob_remove(mob/living/carbon/brain_owner)
	. = ..()
	QDEL_NULL(mind_touch_spell)
	QDEL_NULL(dread_wave_spell)
	QDEL_NULL(astral_walk_spell)
	QDEL_NULL(mind_web_spell)
	QDEL_NULL(cascade_spell)

/obj/item/organ/brain/shadow/dreamweaver/on_life(seconds_per_tick)
	. = ..()

	var/turf/owner_turf = owner.loc
	if(!isturf(owner_turf))
		return
	if(owner_turf.check_lumcount_below(SHADOW_SPECIES_LIGHT_THRESHOLD))
		owner.apply_status_effect(/datum/status_effect/psi_regen)
	else
		owner.adjust_brute_loss(0.5 * seconds_per_tick)

/datum/status_effect/psi_regen
	id = "psi_regen"
	status_type = STATUS_EFFECT_REFRESH
	duration = 4 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/psi_regen

/datum/status_effect/psi_regen/on_apply()
	. = ..()
	if(!.)
		return FALSE
	restore_psi()

/datum/status_effect/psi_regen/refresh(effect, ...)
	. = ..()
	restore_psi()

/datum/status_effect/psi_regen/tick(seconds_between_ticks)
	. = ..()
	restore_psi()

/datum/status_effect/psi_regen/proc/restore_psi()
	var/datum/antagonist/dreamweaver/dreamweaver_antag = owner?.mind?.has_antag_datum(/datum/antagonist/dreamweaver)
	if(dreamweaver_antag)
		dreamweaver_antag.psi_charges = min(dreamweaver_antag.psi_charges + 2, dreamweaver_antag.psi_max)

/atom/movable/screen/alert/status_effect/psi_regen
	name = "Psychic Convergence"
	desc = "The darkness feeds your mind. Psi charges regenerating."
	use_user_hud_icon = USER_HUD_STYLE_INHERIT
	overlay_state = "lightless"
