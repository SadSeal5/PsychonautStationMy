// Space Ninja Loadout Selection & Spawn Invisibility Management

#define NINJA_SLOT_WEAPON_KATANA 1
#define NINJA_SLOT_WEAPON_KUSARIGAMA 2
#define NINJA_SLOT_WEAPON_DAGGERS 3

#define NINJA_SLOT_STAR_DEFAULT 1
#define NINJA_SLOT_STAR_KUNAI 2

#define NINJA_SLOT_HEAL_DEFAULT 1
#define NINJA_SLOT_HEAL_NANITE 2

#define NINJA_SLOT_TRAP_DEFAULT 1
#define NINJA_SLOT_TRAP_DECOY 2

/datum/antagonist/ninja
	/// Active slot selections
	var/loadout_weapon = NINJA_SLOT_WEAPON_KATANA
	var/loadout_star = NINJA_SLOT_STAR_DEFAULT
	var/loadout_heal = NINJA_SLOT_HEAL_DEFAULT
	var/loadout_trap = NINJA_SLOT_TRAP_DEFAULT

	/// Whether loadout has been confirmed
	var/loadout_confirmed = FALSE
	/// Whether the ninja is currently in the setup phase (cloaked + invulnerable)
	var/in_setup_phase = FALSE
	/// Stoppable timer ID for the 3-minute timeout
	var/setup_timer

/**
 * Starts the ninja setup phase upon gaining the antag datum:
 * Sets alpha = 0, observer invisibility, godmode protection, immobilizes and blocks hands,
 * and opens the AntagInfoNinja UI.
 */
/datum/antagonist/ninja/proc/start_setup_phase()
	if(in_setup_phase)
		return
	var/mob/living/carbon/human/ninja = owner?.current
	if(!istype(ninja))
		return

	in_setup_phase = TRUE
	ninja.alpha = 0
	ninja.invisibility = INVISIBILITY_OBSERVER
	ADD_TRAIT(ninja, TRAIT_IMMOBILIZED, REF(src))
	ADD_TRAIT(ninja, TRAIT_HANDS_BLOCKED, REF(src))
	ADD_TRAIT(ninja, TRAIT_GODMODE, REF(src))

	setup_timer = addtimer(CALLBACK(src, PROC_REF(end_setup_phase)), 3 MINUTES, TIMER_STOPPABLE)

	to_chat(ninja, span_boldnotice("Spider Clan temporal concealment field active. Shadows envelop your cybernetic form. Movement and interaction are suspended while calibrating. Confirm your loadout parameters or close this interface to disengage the veil."))
	ui_interact(ninja)

/**
 * Ends the setup phase: restores alpha, removes invisibility and protection/immobilization traits,
 * applies the chosen loadout, and updates open AntagInfoNinja interfaces.
 */
/datum/antagonist/ninja/proc/end_setup_phase()
	if(!in_setup_phase)
		return
	in_setup_phase = FALSE
	if(setup_timer)
		deltimer(setup_timer)
		setup_timer = null

	var/mob/living/carbon/human/ninja = owner?.current
	if(istype(ninja))
		ninja.alpha = 255
		ninja.invisibility = INVISIBILITY_NONE
		REMOVE_TRAIT(ninja, TRAIT_IMMOBILIZED, REF(src))
		REMOVE_TRAIT(ninja, TRAIT_HANDS_BLOCKED, REF(src))
		REMOVE_TRAIT(ninja, TRAIT_GODMODE, REF(src))
		new /obj/effect/temp_visual/dir_setting/ninja(get_turf(ninja), ninja.dir)
		to_chat(ninja, span_warning("The shadows recede as your cybernetic systems calibrate. You are now exposed to the void."))

		if(loadout_weapon != NINJA_SLOT_WEAPON_KATANA)
			var/new_sheath_type
			switch(loadout_weapon)
				if(NINJA_SLOT_WEAPON_KUSARIGAMA)
					new_sheath_type = /obj/item/storage/belt/sheath/ninja/kusarigama
				if(NINJA_SLOT_WEAPON_DAGGERS)
					new_sheath_type = /obj/item/storage/belt/sheath/ninja/daggers
			if(new_sheath_type)
				var/obj/item/storage/belt/sheath/ninja/old_sheath = locate(/obj/item/storage/belt/sheath/ninja) in ninja.get_all_contents()
				var/target_slot = ITEM_SLOT_SUITSTORE
				if(old_sheath)
					var/slot = ninja.get_slot_by_item(old_sheath)
					if(slot)
						target_slot = slot
					qdel(old_sheath)
				var/obj/item/energy_katana/old_katana = locate(/obj/item/energy_katana) in ninja.get_all_contents()
				if(old_katana)
					qdel(old_katana)
				var/obj/item/storage/belt/sheath/ninja/new_sheath = new new_sheath_type(ninja)
				ninja.equip_to_slot_if_possible(new_sheath, target_slot, disable_warning = TRUE)
				var/obj/item/mod/control/mod = ninja.back
				if(!istype(mod))
					mod = locate(/obj/item/mod/control) in ninja.get_all_contents()
				if(istype(mod))
					var/obj/item/mod/module/weapon_recall/recall = locate(/obj/item/mod/module/weapon_recall) in mod.modules
					if(recall)
						var/obj/item/new_weapon = locate(new_sheath.stored_blade) in new_sheath.contents
						if(!new_weapon)
							new_weapon = locate(new_sheath.stored_blade) in ninja.get_all_contents()
						if(new_weapon)
							recall.set_weapon(new_weapon)

	apply_loadout()
	SStgui.update_uis(src)


/**
 * Applies the selected loadout to the ninja's MODsuit, swapping modules and updating pinned actions.
 */
/datum/antagonist/ninja/proc/apply_loadout()
	var/mob/living/carbon/human/ninja = owner?.current
	if(!istype(ninja))
		return
	var/obj/item/mod/control/mod = ninja.back
	if(!istype(mod))
		mod = locate(/obj/item/mod/control) in ninja.get_all_contents()
	if(!istype(mod))
		return

	// Core Module: Ensure Advanced Mimetic Stealth is present and pinned
	var/obj/item/mod/module/stealth/ninja/stealth_mod = locate(/obj/item/mod/module/stealth/ninja) in mod.modules
	if(!stealth_mod)
		stealth_mod = new(mod)
		mod.install(stealth_mod)
		stealth_mod.pin(ninja)

	// Slot 1: Shuriken vs Kunai
	if(loadout_star == NINJA_SLOT_STAR_KUNAI)
		swap_module(mod, /obj/item/mod/module/dispenser/ninja, /obj/item/mod/module/dispenser/ninja/kunai)
	else
		swap_module(mod, /obj/item/mod/module/dispenser/ninja/kunai, /obj/item/mod/module/dispenser/ninja)

	// Slot 2: Adrenaline vs Nanite Repair
	if(loadout_heal == NINJA_SLOT_HEAL_NANITE)
		swap_module(mod, /obj/item/mod/module/adrenaline_boost, /obj/item/mod/module/nanite_repair/ninja)
	else
		swap_module(mod, /obj/item/mod/module/nanite_repair/ninja, /obj/item/mod/module/adrenaline_boost)

	// Slot 3: Energy Net vs Holographic Decoy
	if(loadout_trap == NINJA_SLOT_TRAP_DECOY)
		swap_module(mod, /obj/item/mod/module/energy_net, /obj/item/mod/module/hologram_decoy/ninja)
	else
		swap_module(mod, /obj/item/mod/module/hologram_decoy/ninja, /obj/item/mod/module/energy_net)

	loadout_confirmed = TRUE

/**
 * Helper to swap an existing module type for a new module type in the MODsuit.
 */
/datum/antagonist/ninja/proc/swap_module(obj/item/mod/control/mod, old_type, new_type)
	var/obj/item/mod/module/existing = locate(new_type) in mod.modules
	if(existing)
		return existing
	var/obj/item/mod/module/to_remove = locate(old_type) in mod.modules
	if(to_remove)
		mod.uninstall(to_remove, deleting = TRUE)
		qdel(to_remove)
	var/obj/item/mod/module/new_module = new new_type(mod)
	mod.install(new_module)
	var/mob/living/carbon/human/ninja = owner?.current
	if(ninja)
		new_module.pin(ninja)
	if(istype(mod, /obj/item/mod/control/pre_equipped))
		var/obj/item/mod/control/pre_equipped/pre = mod
		pre.default_pins[new_type] = list(REF(ninja))
	return new_module

/datum/antagonist/ninja/ui_data(mob/user)
	var/list/data = list()
	data["objectives"] = get_objectives()
	data["can_change_objective"] = can_assign_self_objectives
	data["in_setup"] = in_setup_phase
	data["loadout_weapon"] = loadout_weapon
	data["slot_star"] = loadout_star
	data["slot_heal"] = loadout_heal
	data["slot_trap"] = loadout_trap
	data["confirmed"] = loadout_confirmed
	data["mod_icon"] = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	data["weapon_icon"] = 'icons/obj/weapons/sword.dmi'
	return data

/datum/antagonist/ninja/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("select_weapon")
			var/choice = text2num(params["choice"])
			if(choice in list(NINJA_SLOT_WEAPON_KATANA, NINJA_SLOT_WEAPON_KUSARIGAMA, NINJA_SLOT_WEAPON_DAGGERS))
				loadout_weapon = choice
			return TRUE
		if("set_slot")
			var/slot = params["slot"]
			var/value = text2num(params["value"])
			switch(slot)
				if("star")
					loadout_star = value
				if("heal")
					loadout_heal = value
				if("trap")
					loadout_trap = value
			return TRUE
		if("confirm")
			apply_loadout()
			end_setup_phase()
			to_chat(ui.user, span_notice("Spider Clan loadout synchronized."))
			SStgui.update_uis(src)
			return TRUE

/datum/antagonist/ninja/ui_close(mob/user)
	. = ..()
	if(in_setup_phase)
		end_setup_phase()
		if(user)
			to_chat(user, span_notice("Spider Clan loadout synchronized."))

#undef NINJA_SLOT_WEAPON_KATANA
#undef NINJA_SLOT_WEAPON_KUSARIGAMA
#undef NINJA_SLOT_WEAPON_DAGGERS
#undef NINJA_SLOT_STAR_DEFAULT
#undef NINJA_SLOT_STAR_KUNAI
#undef NINJA_SLOT_HEAL_DEFAULT
#undef NINJA_SLOT_HEAL_NANITE
#undef NINJA_SLOT_TRAP_DEFAULT
#undef NINJA_SLOT_TRAP_DECOY

