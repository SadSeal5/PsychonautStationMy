// MARK: Surgery

/// Neurosurgery step extracting a parasitic thrall tumor using a lit flashlight.
/datum/surgery_operation/organ/shadow_thrall_tumor
	name = "Shadow Thrall Tumor Extraction"
	rnd_name = "Neurosurgery (Shadow Thrall Tumor Extraction)"
	desc = "Extract the parasitic hive node from the patient's brain."
	target_type = /obj/item/organ/brain/shadow/tumor_thrall
	implements = list(/obj/item/flashlight = 0.5)
	time = 10 SECONDS
	all_surgery_states_required = SURGERY_SKIN_OPEN|SURGERY_BONE_SAWED
	any_surgery_states_blocked = SURGERY_VESSELS_UNCLAMPED

/datum/surgery_operation/organ/shadow_thrall_tumor/tool_check(obj/item/tool)
	if(!istype(tool, /obj/item/flashlight))
		return FALSE
	var/obj/item/flashlight/flashlight = tool
	return flashlight.light_on

/datum/surgery_operation/organ/shadow_thrall_tumor/state_check(obj/item/organ/brain/shadow/tumor_thrall/organ)
	if(!istype(organ))
		return FALSE
	if(!organ.owner)
		return FALSE
	return organ.owner.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL) == organ

/datum/surgery_operation/organ/shadow_thrall_tumor/on_success(obj/item/organ/brain/shadow/tumor_thrall/organ, mob/living/surgeon, obj/item/tool, list/operation_args)
	if(!organ || QDELETED(organ))
		return
	organ.mob_remove(organ.owner, special = FALSE, movement_flags = NO_ID_TRANSFER)
	qdel(organ)

// MARK: Organs

/// Shadowling mutant brain organ replacing standard brains on transformation.
/obj/item/organ/brain/shadow/shadowling
	name = "shadowling swarm brain"
	desc = "A writhing mass of shadowy matter binding its host to the Hive."
	slot = ORGAN_SLOT_BRAIN

/// Parasitic non-vital brain-slot organ binding a crewmember as a Shadow Thrall.
/obj/item/organ/brain/shadow/tumor_thrall
	name = "shadow thrall tumor"
	desc = "A parasitic hive node that enmeshes the host's mind."
	slot = ORGAN_SLOT_BRAIN_THRALL
	/// Set TRUE once extracted so re-insertion will not re-enthrall a host.
	var/inert = FALSE

/obj/item/organ/brain/shadow/tumor_thrall/Initialize(mapload)
	. = ..()
	organ_flags &= ~ORGAN_VITAL

/// Grants the `shadow_thrall` antagonist datum and examine tell when an active tumor is inserted.
/obj/item/organ/brain/shadow/tumor_thrall/Insert(mob/living/carbon/receiver, special = FALSE, movement_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!inert)
		if(!(receiver?.mind?.has_antag_datum(/datum/antagonist/shadowling, TRUE)))
			receiver?.mind?.add_antag_datum(/datum/antagonist/shadow_thrall)
		RegisterSignal(receiver, COMSIG_ATOM_EXAMINE, PROC_REF(on_holder_examine))
		if(!receiver?.mind)
			to_chat(receiver, span_danger("A freezing whisper permeates your mind... You have been enslaved!"))

/// Marks the tumor inert, removes the thrall antagonist datum, and unregisters examine cues.
/obj/item/organ/brain/shadow/tumor_thrall/on_mob_remove(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	inert = TRUE
	name = "inert shadowling swarm tumor"
	desc = "A withered shadowy tumor, stripped of its brood connection."
	var/had_mind = !!organ_owner?.mind
	if(!special)
		organ_owner?.mind?.remove_antag_datum(/datum/antagonist/shadow_thrall)
	UnregisterSignal(organ_owner, COMSIG_ATOM_EXAMINE)
	if(organ_owner && !had_mind)
		to_chat(organ_owner, span_notice("The binding cold recedes from your mind. You are yourself once more!"))

	. = ..()

/// Appends a close-range unmasked examine cue revealing thralldom.
/obj/item/organ/brain/shadow/tumor_thrall/proc/on_holder_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = source
	if(!istype(H) || !ismob(user))
		return
	if(H.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL) != src)
		return
	if(!user.Adjacent(H))
		return
	if(H.wear_mask)
		return
	examine_list += span_warning("[capitalize(H.p_their())] face is unnaturally contorted and hollow.")
