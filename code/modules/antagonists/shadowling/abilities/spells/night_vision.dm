#define NV_OFF 0
#define NV_LOW 1
#define NV_MID 2
#define NV_HI  3

// MARK: Ability

/// Cycles eye color cutoffs through low, mid, high, and off night-vision presets for hive members.
/datum/action/cooldown/shadowling/toggle_night_vision
	name = "Night Vision"
	desc = "Toggle between night vision intensity levels."
	button_icon_state = "shadow_nightvision"
	cooldown_time = 0 SECONDS
	role_flags = SL_INNATE | SL_THRALL | SL_LESSER | SL_ASCENDED

	/// 0 = OFF, 1/2/3 – LEVELS
	var/nv_level = NV_OFF
	/// Original eye color cutoffs restored when toggling night vision off.
	var/list/original_cutoffs = null

	/// NV Presets
	var/list/cut_low  = list(20, 10, 40)
	var/list/cut_mid  = list(35, 18, 65)
	var/list/cut_high = list(50, 25, 90)

/// Restores [original_cutoffs] and resets `nv_level` when deactivated.
/datum/action/cooldown/shadowling/toggle_night_vision/deactivate_power(mob/living/carbon/human/H)
	if(istype(H) && nv_level != NV_OFF)
		var/obj/item/organ/eyes/E = H.get_organ_slot(ORGAN_SLOT_EYES)
		if(istype(E))
			E.color_cutoffs = original_cutoffs ? original_cutoffs.Copy() : null
			H.update_sight()
		nv_level = NV_OFF
	return ..()

/datum/action/cooldown/shadowling/toggle_night_vision/do_effect(mob/living/carbon/human/H, atom/_)
	if(!istype(H))
		return FALSE

	var/obj/item/organ/eyes/E = H.get_organ_slot(ORGAN_SLOT_EYES)
	if(!istype(E))
		H.balloon_alert(H, "requires eyes")
		return FALSE

	switch(nv_level)
		if(NV_OFF)
			original_cutoffs = E.color_cutoffs ? E.color_cutoffs.Copy() : null
			E.color_cutoffs = cut_low.Copy()
			nv_level = NV_LOW
		if(NV_LOW)
			E.color_cutoffs = cut_mid.Copy()
			nv_level = NV_MID
		if(NV_MID)
			E.color_cutoffs = cut_high.Copy()
			nv_level = NV_HI
		else
			E.color_cutoffs = original_cutoffs ? original_cutoffs.Copy() : null
			nv_level = NV_OFF

	H.update_sight()
	if(nv_level == NV_OFF)
		deactivate_power(H)
	else
		activate_power(H)
	return TRUE

#undef NV_OFF
#undef NV_LOW
#undef NV_MID
#undef NV_HI
