// Space Ninja Loadout Selection & Spawn Invisibility Management

#define NINJA_SLOT_STEALTH_DEFAULT 1
#define NINJA_SLOT_STEALTH_PHASE 2

#define NINJA_SLOT_STAR_DEFAULT 1
#define NINJA_SLOT_STAR_KUNAI 2

#define NINJA_SLOT_HEAL_DEFAULT 1
#define NINJA_SLOT_HEAL_NANITE 2

#define NINJA_SLOT_TRAP_DEFAULT 1
#define NINJA_SLOT_TRAP_SHADOW 2

/datum/antagonist/ninja
	/// Active slot selections
	var/loadout_stealth = NINJA_SLOT_STEALTH_DEFAULT
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
 * Sets alpha = 0, observer invisibility, godmode protection, registers break signals,
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
	ADD_TRAIT(ninja, TRAIT_GODMODE, REF(src))

	RegisterSignal(ninja, COMSIG_MOVABLE_MOVED, PROC_REF(on_setup_break_signal))
	RegisterSignals(ninja, list(
		COMSIG_LIVING_UNARMED_ATTACK,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_ATTACK_RANGED,
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_ATTACK_HAND,
		COMSIG_ATOM_BULLET_ACT,
	), PROC_REF(on_setup_break_signal))

	setup_timer = addtimer(CALLBACK(src, PROC_REF(end_setup_phase)), 3 MINUTES, TIMER_STOPPABLE)

	to_chat(ninja, span_boldnotice("Spider Clan temporal concealment field active. Shadows envelop your cybernetic form. You are shielded from vacuum and undetected by station sensors. Moving, attacking, or confirming your mission parameters will disengage the veil."))
	ui_interact(ninja)

/**
 * Signal handler triggered when the ninja moves or attacks during setup phase.
 */
/datum/antagonist/ninja/proc/on_setup_break_signal(datum/source)
	SIGNAL_HANDLER
	end_setup_phase()

/**
 * Ends the setup phase: restores alpha, removes invisibility and protection, unregisters signals,
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
		UnregisterSignal(ninja, list(
			COMSIG_MOVABLE_MOVED,
			COMSIG_LIVING_UNARMED_ATTACK,
			COMSIG_MOB_ITEM_ATTACK,
			COMSIG_MOB_ATTACK_RANGED,
			COMSIG_ATOM_ATTACKBY,
			COMSIG_ATOM_ATTACK_HAND,
			COMSIG_ATOM_BULLET_ACT,
		))
		ninja.alpha = 255
		ninja.invisibility = INVISIBILITY_NONE
		REMOVE_TRAIT(ninja, TRAIT_GODMODE, REF(src))
		new /obj/effect/temp_visual/dir_setting/ninja(get_turf(ninja), ninja.dir)
		to_chat(ninja, span_warning("The shadows recede as your cybernetic systems calibrate. You are now exposed to the void."))

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

	// Slot 1: Stealth vs Phasing
	if(loadout_stealth == NINJA_SLOT_STEALTH_PHASE)
		swap_module(mod, /obj/item/mod/module/stealth/ninja, /obj/item/mod/module/phase/ninja)
	else
		swap_module(mod, /obj/item/mod/module/phase/ninja, /obj/item/mod/module/stealth/ninja)

	// Slot 2: Shuriken vs Kunai
	if(loadout_star == NINJA_SLOT_STAR_KUNAI)
		swap_module(mod, /obj/item/mod/module/dispenser/ninja, /obj/item/mod/module/dispenser/ninja/kunai)
	else
		swap_module(mod, /obj/item/mod/module/dispenser/ninja/kunai, /obj/item/mod/module/dispenser/ninja)

	// Slot 3: Adrenaline vs Nanite Repair
	if(loadout_heal == NINJA_SLOT_HEAL_NANITE)
		swap_module(mod, /obj/item/mod/module/adrenaline_boost, /obj/item/mod/module/nanite_repair/ninja)
	else
		swap_module(mod, /obj/item/mod/module/nanite_repair/ninja, /obj/item/mod/module/adrenaline_boost)

	// Slot 4: Energy Net vs Shadow Bind
	if(loadout_trap == NINJA_SLOT_TRAP_SHADOW)
		swap_module(mod, /obj/item/mod/module/energy_net, /obj/item/mod/module/shadow_bind/ninja)
	else
		swap_module(mod, /obj/item/mod/module/shadow_bind/ninja, /obj/item/mod/module/energy_net)

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
	data["slot_stealth"] = loadout_stealth
	data["slot_star"] = loadout_star
	data["slot_heal"] = loadout_heal
	data["slot_trap"] = loadout_trap
	data["confirmed"] = loadout_confirmed
	data["mod_icon"] = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	return data

/datum/antagonist/ninja/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("set_slot")
			var/slot = params["slot"]
			var/value = text2num(params["value"])
			switch(slot)
				if("stealth")
					loadout_stealth = value
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
