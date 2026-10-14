//Ninja modules for MODsuits

///Cloaking - Lowers the user's visibility, can be interrupted by being touched or attacked.
/obj/item/mod/module/stealth
	name = "\improper MOD prototype cloaking module"
	desc = "A complete retrofitting of the suit, this is a form of visual concealment tech employing esoteric technology \
		to bend light around the user, as well as mimetic materials to make the surface of the suit match the \
		surroundings based off sensor data. For some reason, this tech is rarely seen."
	icon_state = "cloak"
	module_type = MODULE_TOGGLE
	complexity = 4
	active_power_cost = DEFAULT_CHARGE_DRAIN * 2
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 10
	incompatible_modules = list(/obj/item/mod/module/stealth, /obj/item/mod/module/phase)
	cooldown_time = 5 SECONDS
	required_slots = list(ITEM_SLOT_HEAD|ITEM_SLOT_MASK, ITEM_SLOT_OCLOTHING|ITEM_SLOT_ICLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET)
	custom_materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/bluespace = SMALL_MATERIAL_AMOUNT * 5)
	/// Whether or not the cloak turns off on bumping.
	var/bumpoff = TRUE
	/// The alpha applied when the cloak is on.
	var/stealth_alpha = 50

/obj/item/mod/module/stealth/on_activation(mob/activator)
	if(bumpoff)
		RegisterSignal(mod.wearer, COMSIG_LIVING_MOB_BUMP, PROC_REF(unstealth))
	RegisterSignal(mod.wearer, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(mod.wearer, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet_act))
	RegisterSignals(mod.wearer, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_ATOM_ATTACKBY, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_HITBY, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_PAW, COMSIG_CARBON_CUFF_ATTEMPTED), PROC_REF(unstealth))
	animate(mod.wearer, alpha = stealth_alpha, time = 1.5 SECONDS)
	drain_power(use_energy_cost)

/obj/item/mod/module/stealth/on_deactivation(mob/activator, display_message = TRUE, deleting = FALSE)
	if(bumpoff)
		UnregisterSignal(mod.wearer, COMSIG_LIVING_MOB_BUMP)
	UnregisterSignal(mod.wearer, list(COMSIG_LIVING_UNARMED_ATTACK, COMSIG_MOB_ITEM_ATTACK, COMSIG_ATOM_ATTACKBY, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_BULLET_ACT, COMSIG_ATOM_HITBY, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_PAW, COMSIG_CARBON_CUFF_ATTEMPTED))
	animate(mod.wearer, alpha = 255, time = 1.5 SECONDS)

/obj/item/mod/module/stealth/proc/unstealth(datum/source)
	SIGNAL_HANDLER

	to_chat(mod.wearer, span_warning("[src] gets discharged from contact!"))
	do_sparks(2, TRUE, src)
	drain_power(use_energy_cost)
	deactivate()

/obj/item/mod/module/stealth/proc/on_unarmed_attack(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!isliving(target))
		return
	unstealth(source)

/obj/item/mod/module/stealth/proc/on_bullet_act(datum/source, obj/projectile/projectile)
	SIGNAL_HANDLER

	if(!projectile.is_hostile_projectile())
		return
	unstealth(source)

//Advanced Cloaking - Doesn't turf off on bump, less power drain, more stealthy.
/obj/item/mod/module/stealth/ninja
	name = "\improper MOD advanced cloaking module"
	desc = "The latest in stealth technology, this module is a definite upgrade over previous versions. \
		The field has been tuned to be even more responsive and fast-acting, with enough stability to \
		continue operation of the field even if the user bumps into others. \
		The power draw has been reduced drastically, making this perfect for activities like \
		standing near sentry turrets for extended periods of time."
	icon_state = "cloak_ninja"
	bumpoff = FALSE
	stealth_alpha = 20
	active_power_cost = DEFAULT_CHARGE_DRAIN
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 3 SECONDS


/obj/item/mod/module/stealth/ninja/on_activation(mob/activator)
	. = ..()
	ADD_TRAIT(mod.wearer, TRAIT_SILENT_FOOTSTEPS, REF(src))

/obj/item/mod/module/stealth/ninja/on_deactivation(mob/activator, display_message = TRUE, deleting = FALSE)
	. = ..()
	REMOVE_TRAIT(mod.wearer, TRAIT_SILENT_FOOTSTEPS, REF(src))

///Phase Module - Allows movement through walls and obstacles without invisibility.
/obj/item/mod/module/phase/ninja
	name = "\improper MOD phase module"
	desc = "A bleeding-edge Spider Clan modulation unit employing quantum-phase displacement fields. \
		When engaged, it allows the wearer to phase unobstructed through dense matter and reinforced walls, \
		at the cost of rapid power consumption on phase steps. \
		Unlike mimetic stealth, it produces visible shadow flickers instead of concealing the user."
	icon_state = "phase_ninja"
	module_type = MODULE_TOGGLE
	complexity = 4
	active_power_cost = DEFAULT_CHARGE_DRAIN * 6
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 15
	incompatible_modules = list(/obj/item/mod/module/stealth, /obj/item/mod/module/phase)
	cooldown_time = 10 SECONDS
	required_slots = list(ITEM_SLOT_HEAD|ITEM_SLOT_MASK, ITEM_SLOT_OCLOTHING|ITEM_SLOT_ICLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET)
	/// Whether we are currently in the 3-second startup channel
	var/starting_up = FALSE
	/// Whether the startup channel was interrupted by damage
	var/startup_interrupted = FALSE
	/// Active timed action for startup channel so it can be cancelled on damage
	var/datum/timed_action/startup_action

/obj/item/mod/module/phase/ninja/Destroy()
	if(startup_action)
		startup_action.cancel()
		startup_action = null
	if(mod?.wearer)
		UnregisterSignal(mod.wearer, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_ATOM_EMP_ACT))
		unregister_attack_restrictions(mod.wearer)
	if(mod)
		UnregisterSignal(mod, COMSIG_ATOM_EMP_ACT)
	return ..()

/obj/item/mod/module/phase/ninja/emp_act(severity)
	. = ..()
	if(active)
		on_active_emp(src, severity)
	else if(starting_up)
		on_startup_emp(src, severity)

/obj/item/mod/module/phase/ninja/on_part_deactivation(deleting = FALSE)
	if(startup_action)
		startup_action.cancel()
	return ..()

/obj/item/mod/module/phase/ninja/on_uninstall()
	if(startup_action)
		startup_action.cancel()
	return ..()

/obj/item/mod/module/phase/ninja/activate(mob/activator)
	if(starting_up)
		balloon_alert(activator, "calibration in progress!")
		return FALSE
	if(!COOLDOWN_FINISHED(src, cooldown_timer))
		balloon_alert(activator, "on cooldown!")
		return FALSE
	if(!mod.active || mod.activating || !mod.get_charge())
		balloon_alert(activator, "unpowered!")
		return FALSE
	if(!(allow_flags & MODULE_ALLOW_PHASEOUT) && istype(mod.wearer.loc, /obj/effect/dummy/phased_mob))
		to_chat(activator, span_warning("You cannot activate this right now."))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_MODULE_TRIGGERED, mod.wearer) & MOD_ABORT_USE)
		return FALSE

	INVOKE_ASYNC(src, PROC_REF(startup_channel), activator)
	return TRUE

/obj/item/mod/module/phase/ninja/proc/startup_channel(mob/activator)
	starting_up = TRUE
	startup_interrupted = FALSE
	balloon_alert(mod.wearer, "calibrating phase shift...")
	register_attack_restrictions(mod.wearer)
	RegisterSignal(mod.wearer, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_startup_damage))
	RegisterSignal(mod.wearer, COMSIG_ATOM_EMP_ACT, PROC_REF(on_startup_emp))
	if(mod)
		RegisterSignal(mod, COMSIG_ATOM_EMP_ACT, PROC_REF(on_startup_emp))

	var/datum/timed_action/action = new(mod.wearer, mod.wearer, 3 SECONDS, show_progress = TRUE, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM, extra_checks = CALLBACK(src, PROC_REF(check_startup_validity)))
	startup_action = action
	var/success = action.await()
	startup_action = null

	if(mod?.wearer)
		UnregisterSignal(mod.wearer, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_ATOM_EMP_ACT))
	if(mod)
		UnregisterSignal(mod, COMSIG_ATOM_EMP_ACT)

	if(!success || startup_interrupted)
		if(mod?.wearer)
			unregister_attack_restrictions(mod.wearer)
		starting_up = FALSE
		if(startup_interrupted)
			if(mod?.wearer)
				to_chat(mod.wearer, span_warning("Disruption breaks your phase calibration sequence!"))
				do_sparks(3, TRUE, mod.wearer)
			start_cooldown(10 SECONDS)
			startup_interrupted = FALSE
		return

	starting_up = FALSE
	active = TRUE
	SEND_SIGNAL(src, COMSIG_MODULE_ACTIVATED)
	SEND_SIGNAL(mod, COMSIG_MOD_MODULE_ACTIVATED, src)
	on_activation(activator)
	update_clothing_slots()

/obj/item/mod/module/phase/ninja/proc/check_startup_validity()
	if(startup_interrupted)
		return FALSE
	if(!mod || !mod.wearer || HAS_TRAIT(mod.wearer, TRAIT_INCAPACITATED))
		return FALSE
	if(!mod.active || mod.activating || !mod.get_charge())
		return FALSE
	if(loc != mod)
		return FALSE
	return TRUE

/obj/item/mod/module/phase/ninja/proc/on_startup_damage(mob/living/source, damage_amount, damagetype, def_zone)
	SIGNAL_HANDLER

	if(damage_amount <= 0 || startup_interrupted)
		return
	startup_interrupted = TRUE
	if(startup_action)
		startup_action.cancel()

/obj/item/mod/module/phase/ninja/proc/on_startup_emp(atom/source, severity, protection)
	SIGNAL_HANDLER

	if(startup_interrupted)
		return
	startup_interrupted = TRUE
	if(startup_action)
		startup_action.cancel()

/obj/item/mod/module/phase/ninja/proc/register_attack_restrictions(mob/living/wearer)
	if(!wearer)
		return
	RegisterSignal(wearer, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(wearer, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(wearer, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_attack))

/obj/item/mod/module/phase/ninja/proc/unregister_attack_restrictions(mob/living/wearer)
	if(!wearer)
		return
	UnregisterSignal(wearer, list(COMSIG_LIVING_UNARMED_ATTACK, COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_ATTACK_RANGED))

/obj/item/mod/module/phase/ninja/proc/on_unarmed_attack(mob/living/source, atom/attack_target, proximity_flag, modifiers)
	SIGNAL_HANDLER

	if(!isliving(attack_target) || attack_target == mod?.wearer)
		return
	to_chat(mod.wearer, span_warning("Dimensional phase interference prevents you from attacking while out of phase!"))
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/item/mod/module/phase/ninja/proc/on_item_attack(mob/living/source, mob/living/target_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	SIGNAL_HANDLER

	to_chat(mod.wearer, span_warning("Dimensional phase interference prevents you from attacking while out of phase!"))
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/item/mod/module/phase/ninja/proc/on_ranged_attack(mob/living/source, atom/target, modifiers)
	SIGNAL_HANDLER

	if(!isliving(target) || target == mod?.wearer)
		return
	to_chat(mod.wearer, span_warning("Dimensional phase interference prevents you from attacking while out of phase!"))
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/item/mod/module/phase/ninja/on_activation(mob/activator)
	ADD_TRAIT(mod.wearer, TRAIT_MOVE_PHASING, REF(src))
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(on_wearer_moved))
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_CAN_PASS_THROUGH, PROC_REF(on_can_pass_through))
	RegisterSignal(mod.wearer, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_active_damage))
	RegisterSignal(mod.wearer, COMSIG_ATOM_EMP_ACT, PROC_REF(on_active_emp))
	if(mod)
		RegisterSignal(mod, COMSIG_ATOM_EMP_ACT, PROC_REF(on_active_emp))
	new /obj/effect/temp_visual/dir_setting/ninja/phase(get_turf(mod.wearer), mod.wearer.dir)
	playsound(mod.wearer, 'sound/effects/phasein.ogg', 50, TRUE)
	drain_power(use_energy_cost)

/obj/item/mod/module/phase/ninja/on_deactivation(mob/activator, display_message = TRUE, deleting = FALSE)
	if(mod?.wearer)
		REMOVE_TRAIT(mod.wearer, TRAIT_MOVE_PHASING, REF(src))
		UnregisterSignal(mod.wearer, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_CAN_PASS_THROUGH, COMSIG_MOB_APPLY_DAMAGE, COMSIG_ATOM_EMP_ACT))
		unregister_attack_restrictions(mod.wearer)
		new /obj/effect/temp_visual/dir_setting/ninja/phase/out(get_turf(mod.wearer), mod.wearer.dir)
		playsound(mod.wearer, 'sound/effects/phasein.ogg', 50, TRUE)
		var/turf/current_turf = get_turf(mod.wearer)
		if(current_turf?.density || istype(current_turf, /turf/closed))
			var/turf/open/safe
			for(var/turf/open/candidate in orange(1, mod.wearer))
				if(!candidate.density)
					safe = candidate
					break
			if(!safe)
				safe = find_safe_turf(mod.wearer.z)
			if(safe)
				mod.wearer.forceMove(safe)
	if(mod)
		UnregisterSignal(mod, COMSIG_ATOM_EMP_ACT)
	if(!deleting)
		start_cooldown(10 SECONDS)

/obj/item/mod/module/phase/ninja/proc/on_active_damage(mob/living/source, damage_amount, damagetype, def_zone)
	SIGNAL_HANDLER

	if(damage_amount <= 0 || !active)
		return
	if(mod?.wearer)
		balloon_alert(mod.wearer, "phase disrupted by damage!")
		to_chat(mod.wearer, span_warning("Taking damage disrupts your phase displacement field, forcing you back into phase!"))
		do_sparks(4, TRUE, mod.wearer)
	deactivate()

/obj/item/mod/module/phase/ninja/proc/on_active_emp(atom/source, severity, protection)
	SIGNAL_HANDLER

	if(!active)
		return
	if(mod?.wearer)
		balloon_alert(mod.wearer, "phase collapsed by EMP!")
		to_chat(mod.wearer, span_warning("Electromagnetic interference collapses your phase displacement field!"))
		do_sparks(5, TRUE, mod.wearer)
	deactivate()

/obj/item/mod/module/phase/ninja/proc/on_wearer_moved(mob/living/source, atom/oldloc, direction, forced, list/old_locs)
	SIGNAL_HANDLER

	if(!mod || !mod.wearer)
		return
	new /obj/effect/temp_visual/dir_setting/ninja/shadow(oldloc, mod.wearer.dir)
	new /obj/effect/temp_visual/dir_setting/ninja/phase(get_turf(mod.wearer), mod.wearer.dir)
	if(!drain_power(use_energy_cost))
		to_chat(mod.wearer, span_warning("[src] drains all available power and shuts down!"))
		deactivate()

/obj/item/mod/module/phase/ninja/proc/on_can_pass_through(datum/source, atom/blocker, movement_dir)
	SIGNAL_HANDLER

	return COMSIG_COMPONENT_PERMIT_PASSAGE


///Camera Vision - Prevents flashes, blocks tracking.
/obj/item/mod/module/welding/camera_vision
	name = "\improper MOD camera vision module"
	desc = "A module installed into the suit's helmet. This specialized piece of technology is built for subterfuge, \
		replacing the standard visor with a nanotech display; capable of displaying specialized imagery at \
		just the right frequency to jam all known forms of camera tracking and facial recognition, \
		as well as automatically dimming incoming flashes of light to protect the user's eyes. Become the unseen."
	icon_state = "welding_camera"
	removable = FALSE
	complexity = 0
	overlay_state_inactive = null
	required_slots = list(ITEM_SLOT_HEAD|ITEM_SLOT_EYES|ITEM_SLOT_MASK)

/obj/item/mod/module/welding/camera_vision/on_part_activation()
	RegisterSignal(mod.wearer, COMSIG_LIVING_CAN_TRACK, PROC_REF(can_track))
	var/obj/item/clothing/head_cover = mod.get_part_from_slot(ITEM_SLOT_HEAD) || mod.get_part_from_slot(ITEM_SLOT_MASK) || mod.get_part_from_slot(ITEM_SLOT_EYES)
	if(istype(head_cover))
		//this is a screen that displays an image, so flash sensitives can use this to protect against flashes.
		head_cover.flash_protect = FLASH_PROTECTION_WELDER_HYPER_SENSITIVE


/obj/item/mod/module/welding/camera_vision/on_part_deactivation(deleting = FALSE)
	if(deleting)
		return
	var/obj/item/clothing/head_cover = mod.get_part_from_slot(ITEM_SLOT_HEAD) || mod.get_part_from_slot(ITEM_SLOT_MASK) || mod.get_part_from_slot(ITEM_SLOT_EYES)
	if(istype(head_cover))
		head_cover.flash_protect = initial(head_cover.flash_protect)
	UnregisterSignal(mod.wearer, COMSIG_LIVING_CAN_TRACK)

/obj/item/mod/module/welding/camera_vision/proc/can_track(datum/source, mob/user)
	SIGNAL_HANDLER

	return COMPONENT_CANT_TRACK

//Ninja Star Dispenser - Dispenses ninja stars.
/obj/item/mod/module/dispenser/ninja
	name = "\improper MOD ninja star dispenser module"
	desc = "This piece of Spider Clan technology can exploit known energy-matter equivalence principles, \
		using the nanites already hosted in the wearer's suit to transmute into monomolecular shuriken. \
		While these lack the intense bleeding edge of conventional throwing stars, \
		they have been set to electrify fleeing targets; and branded with the Spider Clan symbol."
	icon_state = "dispenser_ninja"
	dispense_type = /obj/item/throwing_star/stamina/ninja
	cooldown_time = 0.5 SECONDS

/obj/item/throwing_star/stamina/ninja
	name = "energy throwing star"
	desc = "An evolution of the traditional steel shuriken, commonly used by Spider Clan initiates. \
		When thrown or embedded, its internal energy emitter releases an electromagnetic pulse."
	icon_state = "eshuriken"
	force = 8
	throwforce = 12
	armour_penetration = 75
	item_flags = DROPDEL
	embed_type = /datum/embedding/throwing_star/stamina/energy
	custom_materials = null
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE

/obj/item/throwing_star/stamina/ninja/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_UNCATCHABLE, INNATE_TRAIT)

/obj/item/throwing_star/stamina/ninja/on_thrown(mob/living/carbon/user, atom/target)
	item_flags &= ~DROPDEL // Throwing = dropping = dropdel, not ideal. Remove it before that happens
	return ..()

/obj/item/throwing_star/stamina/ninja/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	item_flags |= DROPDEL // Just in case, re-apply drop del now
	hit_atom.emp_act(EMP_HEAVY)
	new /obj/effect/temp_visual/emp/pulse(get_turf(src))
	new /obj/effect/temp_visual/emp(get_turf(hit_atom))
	playsound(src, 'sound/effects/empulse.ogg', 60, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	visible_message("[src] emits an electromagnetic pulse upon impact!")
	if(isturf(loc)) // if we didn't embed in anything, go away
		qdel(src)

/datum/embedding/throwing_star/stamina/energy
	COOLDOWN_DECLARE(emp_cd)

/datum/embedding/throwing_star/stamina/energy/on_successful_embed(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	COOLDOWN_START(src, emp_cd, 6 SECONDS)
	parent.item_flags |= DROPDEL // Just in case again, re-apply drop del now

/datum/embedding/throwing_star/stamina/energy/process_effect(seconds_per_tick)
	if(!COOLDOWN_FINISHED(src, emp_cd))
		return

	owner.emp_act(EMP_LIGHT)
	COOLDOWN_START(src, emp_cd, 6 SECONDS)
	playsound(owner, 'sound/effects/empulse.ogg', 30, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	owner.show_message("[parent] flares brightly, releasing an electromagnetic pulse!", MSG_VISUAL)
	new /obj/effect/temp_visual/emp(get_turf(owner))

//Grappling Kunai Dispenser - Dispenses tethered grappling kunai.
/obj/item/mod/module/dispenser/ninja/kunai
	name = "\improper MOD grappling kunai dispenser module"
	desc = "An advanced rapid-fabrication module utilizing the suit's nanite reserves to synthesize weighted Spider Clan kunai \
		tethered to monomolecular micro-cables. When thrown, the kunai drags struck adversaries directly to the user with a stunning shock, \
		or anchors into walls and structures to haul the wearer rapidly forward."
	icon_state = "dispenser_kunai"
	dispense_type = /obj/item/throwing_star/kunai/ninja
	cooldown_time = 7 SECONDS

/obj/item/throwing_star/kunai/ninja
	name = "grappling kunai"
	desc = "A forged titanium-alloy kunai threaded with a high-tensile Spider Clan nanite cable. \
		When thrown, it embeds violently, dragging living targets or reeling its thrower forward to solid walls."
	icon = 'icons/obj/weapons/thrown.dmi'
	icon_state = "kunai_ninja"
	inhand_icon_state = "kunai"
	force = 8
	throwforce = 12
	throw_speed = 1
	armour_penetration = 75
	item_flags = DROPDEL
	custom_materials = null
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE
	/// Reference to the thrower mob
	var/datum/weakref/thrower_ref
	/// Visual tether cable beam connecting thrower to kunai
	var/datum/beam/tether_beam

/obj/item/throwing_star/kunai/ninja/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_UNCATCHABLE, INNATE_TRAIT)

/obj/item/throwing_star/kunai/ninja/Destroy()
	QDEL_NULL(tether_beam)
	return ..()

/obj/item/throwing_star/kunai/ninja/safe_throw_at(atom/target, range, speed, atom/thrower, spin = FALSE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE)
	return ..(target, range, speed, thrower, FALSE, diagonals_first, callback, force, gentle)

/obj/item/throwing_star/kunai/ninja/throw_at(atom/target, range, speed, mob/thrower, spin = FALSE, diagonals_first = FALSE, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	return ..(target, range, speed, thrower, FALSE, diagonals_first, callback, force, gentle, quickstart, throw_type_path)

/obj/item/throwing_star/kunai/ninja/ranged_interact_with_atom(atom/target, mob/living/user, list/modifiers)
	if(!target || target == user)
		return NONE
	user.throw_item(target)
	return ITEM_INTERACT_SUCCESS

/obj/item/throwing_star/kunai/ninja/on_thrown(mob/living/carbon/user, atom/target)
	item_flags &= ~DROPDEL
	. = ..()
	if(!.)
		return FALSE
	QDEL_NULL(tether_beam)
	item_flags &= ~DROPDEL
	thrower_ref = WEAKREF(user)
	icon_state = "kunai_projectile"
	var/target_angle = get_angle(user, target)
	transform = turn(matrix(), target_angle)
	if(isturf(user.loc) && isturf(loc))
		tether_beam = user.Beam(src, icon_state = "ninja_cable", maxdistance = 15)
	return .

/proc/ninja_kunai_smooth_landing(mob/living/ninja, datum/beam/zip_beam)
	qdel(zip_beam)
	if(QDELETED(ninja))
		return
	ninja.SetKnockdown(0)
	ninja.SetParalyzed(0)
	ninja.SetStun(0)
	ninja.set_resting(FALSE)

/obj/item/throwing_star/kunai/ninja/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	item_flags |= DROPDEL
	QDEL_NULL(tether_beam)
	transform = null
	icon_state = "kunai_ninja"
	var/mob/living/thrower = thrower_ref?.resolve()
	if(isliving(hit_atom))
		var/mob/living/victim = hit_atom
		playsound(src, 'sound/items/weapons/pierce.ogg', 60, TRUE)
		victim.apply_damage(10, STAMINA)
		victim.Knockdown(2.5 SECONDS)
		do_sparks(2, TRUE, victim)
		if(thrower && thrower != victim && get_dist(thrower, victim) > 1)
			victim.visible_message(span_danger("[thrower] snags [victim] with [src] and yanks [victim.p_them()] close!"), span_userdanger("[thrower] hooks you with [src] and yanks you across the room!"))
			playsound(victim, 'sound/items/fulton/fultext_deploy.ogg', 50, TRUE)
			var/datum/beam/pull_beam = thrower.Beam(victim, icon_state = "ninja_cable", maxdistance = 15, time = 3 SECONDS)
			victim.throw_at(target = thrower, range = get_dist(victim, thrower), speed = 1.5, thrower = thrower, spin = FALSE, gentle = TRUE, callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), pull_beam))
	else if(hit_atom.density || istype(hit_atom, /turf/closed) || isstructure(hit_atom) || ismachinery(hit_atom))
		if(thrower && get_dist(thrower, hit_atom) > 1)
			thrower.visible_message(span_danger("[thrower] grapples onto [hit_atom] and zips forward!"), span_notice("You hook [hit_atom] with [src] and haul yourself forward!"))
			playsound(thrower, 'sound/items/fulton/fultext_deploy.ogg', 50, TRUE)
			var/datum/beam/zip_beam = thrower.Beam(hit_atom, icon_state = "ninja_cable", maxdistance = 15, time = 3 SECONDS)
			thrower.throw_at(target = get_turf(hit_atom), range = get_dist(thrower, hit_atom), speed = 2, thrower = thrower, spin = FALSE, gentle = TRUE, callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ninja_kunai_smooth_landing), thrower, zip_beam))
	if(isturf(loc))
		qdel(src)

///Hacker - This module hooks onto your right-clicks with empty hands and causes ninja actions.
/obj/item/mod/module/hacker
	name = "\improper MOD hacker module"
	desc = "Built for one purpose, electronic warfare, this module is built into the hands. \
		Using near-field communication alongside precise electro-stimulation of the wires in machines, \
		this decker's dream is normally used to pass through doors like a phantom. \
		It's also capable of non-precise electro-stimulation of an assassin-saboteur's opponents on disarming attacks."
	icon_state = "hacker"
	removable = FALSE
	incompatible_modules = list(/obj/item/mod/module/hacker)
	required_slots = list(ITEM_SLOT_GLOVES)
	/// Whether or not the communication console hack was used to summon another antagonist.
	var/communication_console_hack_success = FALSE
	/// How many times the module has been used to force open doors.
	var/door_hack_counter = 0

/// Minimum amount of energy we can drain in a single drain action
#define NINJA_MIN_DRAIN (0.2 * STANDARD_CELL_CHARGE)
/// Maximum amount of energy we can drain in a single drain action
#define NINJA_MAX_DRAIN (0.4 * STANDARD_CELL_CHARGE)

/atom/proc/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	return NONE

/obj/item/mod/module/hacker/on_part_activation()
	RegisterSignal(mod.wearer, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(hack))

/obj/item/mod/module/hacker/on_part_deactivation(deleting = FALSE)
	UnregisterSignal(mod.wearer, COMSIG_LIVING_UNARMED_ATTACK)

/obj/item/mod/module/hacker/proc/hack(mob/living/carbon/human/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER

	if(!LAZYACCESS(modifiers, RIGHT_CLICK) || !proximity)
		return NONE
	target.add_fingerprint(mod.wearer)
	return target.ninjadrain_act(mod.wearer, src)

/obj/item/mod/module/hacker/proc/charge_message(atom/drained_atom, drain_amount)
	if(drain_amount)
		to_chat(mod.wearer, span_notice("Gained <B>[drain_amount]</B> units of energy from [drained_atom]."))
	else
		to_chat(mod.wearer, span_warning("[drained_atom] has run dry of energy, you must find another source!"))

//Security Records, Ninja objective This notifies the AI and sets everyone on arrest.
/obj/machinery/computer/records/security/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	if(!can_hack(ninja, feedback = TRUE))
		return NONE

	AI_notify_hack()
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/machinery/computer/records/security/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!do_after(ninja, 20 SECONDS, src, extra_checks = CALLBACK(src, PROC_REF(can_hack), ninja), cog_icon = null))
		return
	for(var/datum/record/crew/target in GLOB.manifest.general)
		target.wanted_status = WANTED_ARREST
	update_all_security_huds()

	var/datum/antagonist/ninja/ninja_antag = ninja.mind.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja_antag)
		return
	var/datum/objective/security_scramble/objective = locate() in ninja_antag.objectives
	if(objective)
		objective.completed = TRUE

/obj/machinery/computer/records/security/proc/can_hack(mob/living/hacker, feedback = FALSE)
	if(machine_stat & (NOPOWER|BROKEN))
		if(feedback && hacker)
			balloon_alert(hacker, "can't hack!")
		return FALSE
	var/area/console_area = get_area(src)
	if(!console_area || !(console_area.area_flags & VALID_TERRITORY))
		if(feedback && hacker)
			balloon_alert(hacker, "signal too weak!")
		return FALSE
	return TRUE

//APC, this drains emaggs the apc and drains power to supply your modsuit
/obj/machinery/power/apc/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/machinery/power/apc/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/maxcapacity = FALSE //Safety check for batteries
	var/drain = 0 //Drain amount from batteries
	var/drain_total = 0
	if(!cell?.charge)
		hacking_module.charge_message(src, drain_total)
		return
	var/datum/effect_system/basic/spark_spread/spark_system = new(loc, 5, FALSE)
	while(cell.charge> 0 && !maxcapacity)
		drain = rand(NINJA_MIN_DRAIN, NINJA_MAX_DRAIN)
		if(cell.charge < drain)
			drain = cell.charge
		if(hacking_module.mod.get_charge() + drain > hacking_module.mod.get_max_charge())
			drain = hacking_module.mod.get_max_charge() - hacking_module.mod.get_charge()
			maxcapacity = TRUE//Reached maximum battery capacity.
		if (do_after(ninja, 1 SECONDS, target = src, cog_icon = null))
			spark_system.start()
			playsound(loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
			cell.use(drain)
			hacking_module.mod.add_charge(drain)
			drain_total += drain
		else
			break
	if(!(obj_flags & EMAGGED))
		flick("apc-spark", hacking_module)
		playsound(loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		obj_flags |= EMAGGED
		locked = FALSE
		update_appearance()
	hacking_module.charge_message(src, drain_total)

//SMES, Drains power to supply your modsuit
/obj/machinery/power/smes/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/machinery/power/smes/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/maxcapacity = FALSE //Safety check for batteries
	var/drain = 0 //Drain amount from batteries
	var/drain_total = 0
	var/datum/effect_system/basic/spark_spread/spark_system = new(loc, 5, FALSE)
	while(charge > 0 && !maxcapacity)
		drain = rand(NINJA_MIN_DRAIN, NINJA_MAX_DRAIN)
		if(charge < drain)
			drain = charge
		if(hacking_module.mod.get_charge() + drain > hacking_module.mod.get_max_charge())
			drain = hacking_module.mod.get_max_charge() - hacking_module.mod.get_charge()
			maxcapacity = TRUE
		if (do_after(ninja, 1 SECONDS, target = src, cog_icon = null))
			spark_system.start()
			playsound(loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
			charge -= drain
			hacking_module.mod.add_charge(drain)
			drain_total += drain
			maxcapacity = TRUE//Reached maximum battery capacity.
		else
			break
	hacking_module.charge_message(src, drain_total)

//CELL, Drains power, to supply your modsuit
/obj/item/stock_parts/power_store/cell/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/item/stock_parts/power_store/cell/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/drain_total = 0
	if(charge && !do_after(ninja, 3 SECONDS, target = src, cog_icon = null))
		drain_total = charge
		if(hacking_module.mod.get_charge() + charge > hacking_module.mod.get_max_charge())
			drain_total = hacking_module.mod.get_max_charge() - hacking_module.mod.get_charge()
		hacking_module.mod.add_charge(drain_total)
		use(drain_total)
		corrupt()
		update_appearance()
	hacking_module.charge_message(src, drain_total)

//RD SERVER, Ninja objective will download the RnD files and destroy source code hard drive.
/obj/machinery/rnd/server/master/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	// If the traitor theft objective is still present, this will destroy it...
	if(!source_code_hdd)
		return ..()
	to_chat(ninja, span_notice("Hacking \the [src]..."))
	AI_notify_hack()
	to_chat(ninja, span_notice("Encrypted source code detected. Overloading storage device..."))
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/machinery/rnd/server/master/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!do_after(ninja, 30 SECONDS, target = src, cog_icon = null))
		return
	overload_source_code_hdd()
	to_chat(ninja, span_notice("Sabotage complete. Storage device overloaded."))
	var/datum/antagonist/ninja/ninja_antag = ninja.mind.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja_antag)
		return
	var/datum/objective/research_secrets/objective = locate() in ninja_antag.objectives
	if(objective)
		objective.completed = TRUE

/obj/machinery/rnd/server/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	to_chat(ninja, span_notice("Research notes detected. Corrupting data..."))
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/machinery/rnd/server/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!do_after(ninja, 30 SECONDS, target = src, cog_icon = null))
		return
	stored_research.adjust_all_points(-INFINITY)
	to_chat(ninja, span_notice("Sabotage complete. Research notes corrupted."))
	var/datum/antagonist/ninja/ninja_antag = ninja.mind.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja_antag)
		return
	var/datum/objective/research_secrets/objective = locate() in ninja_antag.objectives
	if(objective)
		objective.completed = TRUE


//COMMUNICATIONS CONSOLE, Ninja objective hacking it summons random threat.
/obj/machinery/computer/communications/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	if(hacking_module.communication_console_hack_success)
		return NONE
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/machinery/computer/communications/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!try_hack_console(ninja))
		return

	hacking_module.communication_console_hack_success = TRUE
	var/datum/antagonist/ninja/ninja_antag = ninja.mind.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja_antag)
		return
	var/datum/objective/terror_message/objective = locate() in ninja_antag.objectives
	if(objective)
		objective.completed = TRUE

//AIRLOCK, Ninja objective. Hacking it forces the airlock open and emaggs it
/obj/machinery/door/airlock/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	if(!operating && density && hasPower() && !(obj_flags & EMAGGED) && hacking_module.mod.subtract_charge(DEFAULT_CHARGE_DRAIN * 5))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom, emag_act))
		hacking_module.door_hack_counter++
		var/datum/antagonist/ninja/ninja_antag = ninja.mind.has_antag_datum(/datum/antagonist/ninja)
		if(!ninja_antag)
			return NONE
		var/datum/objective/door_jack/objective = locate() in ninja_antag.objectives
		if(objective && objective.doors_required == hacking_module.door_hack_counter)
			ninja.balloon_alert(ninja, "all doors hacked")
		if(objective && objective.doors_required <= hacking_module.door_hack_counter)
			objective.completed = TRUE
	return COMPONENT_CANCEL_ATTACK_CHAIN

//WIRE, Drains power from powernet and supplies your modsuit
/obj/structure/cable/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/structure/cable/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/maxcapacity = FALSE //Safety check
	var/drain = 0 //Drain amount
	var/drain_total = 0
	var/datum/powernet/wire_powernet = powernet
	while(!maxcapacity && src)
		drain = (round((rand(NINJA_MIN_DRAIN, NINJA_MAX_DRAIN))/2))
		var/drained = 0
		if(wire_powernet && do_after(ninja, 1 SECONDS, target = src, cog_icon = null))
			drained = min(drain, delayed_surplus())
			add_delayedload(drained)
			if(drained < drain)//if no power on net, drain apcs
				for(var/obj/machinery/power/terminal/affected_terminal in wire_powernet.nodes)
					if(istype(affected_terminal.master, /obj/machinery/power/apc))
						var/obj/machinery/power/apc/AP = affected_terminal.master
						if(AP.operating && AP.cell && AP.cell.charge > 0)
							AP.cell.charge = max(0, AP.cell.charge - 5)
							drained += 5
		else
			break
		if(hacking_module.mod.get_charge() + drain > hacking_module.mod.get_max_charge())
			drain = hacking_module.mod.get_max_charge() - hacking_module.mod.get_charge()
			maxcapacity = TRUE
		drain_total += drain
		hacking_module.mod.add_charge(drain)
		do_sparks(5, cardinal_only = FALSE, source = hacking_module.mod)
	hacking_module.charge_message(src, drain_total)

//MECH, Drains power from the mech to supply your modsuit.
/obj/vehicle/sealed/mecha/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	to_chat(occupants, "[icon2html(src, occupants)][span_danger("Warning: Unauthorized access through sub-route 4, block H, detected.")]")
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/vehicle/sealed/mecha/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/maxcapacity = FALSE //Safety check
	var/drain = 0 //Drain amount
	var/drain_total = 0
	if(get_charge())
		while(cell.charge > 0 && !maxcapacity)
			drain = rand(NINJA_MIN_DRAIN, NINJA_MAX_DRAIN)
			if(cell.charge < drain)
				drain = cell.charge
			if(hacking_module.mod.get_charge() + drain > hacking_module.mod.get_max_charge())
				drain = hacking_module.mod.get_max_charge() - hacking_module.mod.get_charge()
				maxcapacity = TRUE
			if (do_after(ninja, 1 SECONDS, target = src, cog_icon = null))
				spark_system.start()
				playsound(loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
				cell.use(drain)
				hacking_module.mod.add_charge(drain)
				drain_total += drain
			else
				break
	hacking_module.charge_message(src, drain_total)

//BORG, Ninja objective converts a borg to a syndicate version
/mob/living/silicon/robot/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module || (has_faction(ROLE_NINJA)))
		return NONE

	to_chat(src, span_danger("Warni-***BZZZZZZZZZRT*** UPLOADING SPYDERPATCHER VERSION 9.5.2..."))
	INVOKE_ASYNC(src, PROC_REF(ninjadrain_charge), ninja, hacking_module)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/mob/living/silicon/robot/proc/ninjadrain_charge(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!do_after(ninja, 6 SECONDS, target = src, cog_icon = null))
		return
	spark_system.start()
	playsound(loc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	to_chat(src, span_danger("UPLOAD COMPLETE. NEW CYBORG MODEL DETECTED.  INSTALLING..."))
	faction = list(ROLE_NINJA)
	bubble_icon = "syndibot"
	UnlinkSelf()
	ionpulse = TRUE
	replace_law_set(/datum/ai_laws/ninja_override)
	model.transform_to(pick(/obj/item/robot_model/syndicate, /obj/item/robot_model/syndicate_medical, /obj/item/robot_model/saboteur))

	var/datum/antagonist/ninja/ninja_antag = ninja.mind.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja_antag)
		return
	var/datum/objective/cyborg_hijack/objective = locate() in ninja_antag.objectives
	if(objective)
		objective.completed = TRUE

//CARBON MOBS, shoving causes 3 second knockdown
/mob/living/carbon/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!ninja || !hacking_module)
		return NONE
	//20 uses for a standard cell. 200 for high capacity cells.
	if(hacking_module.mod.subtract_charge(DEFAULT_CHARGE_DRAIN*10))
		//Got that electric touch
		do_sparks(5, FALSE, loc)
		visible_message(span_danger("[ninja] electrocutes [src] with [ninja.p_their()] touch!"), span_userdanger("[ninja] electrocutes you with [ninja.p_their()] touch!"))
		addtimer(CALLBACK(src, PROC_REF(ninja_knockdown)), 0.3 SECONDS)
	return NONE

/mob/living/carbon/proc/ninja_knockdown()
	Knockdown(3 SECONDS)
	set_jitter_if_lower(3 SECONDS)

//CAMERAS, emps cameras disabling AI vision
/obj/machinery/camera/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(isEmpProof(TRUE))
		balloon_alert(ninja, "camera is shielded!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(!hacking_module.mod.subtract_charge(DEFAULT_CHARGE_DRAIN * 5))
		return

	emp_act(EMP_HEAVY)
	return COMPONENT_CANCEL_ATTACK_CHAIN

//BOTS, overloads them and causes a explosion
/mob/living/basic/bot/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	to_chat(src, span_boldwarning("Your circutry suddenly begins heating up!"))
	if(!do_after(ninja, 1.5 SECONDS, target = src, cog_icon = null))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(!hacking_module.mod.subtract_charge(DEFAULT_CHARGE_DRAIN * 7))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	do_sparks(number = 3, cardinal_only = FALSE, source = src)
	playsound(get_turf(src), 'sound/machines/warning-buzzer.ogg', 35, TRUE)
	balloon_alert(ninja, "stand back!")
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(explosion), src, 0, 1, 2, 3), 2.5 SECONDS)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/mob/living/basic/bot/medbot/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/static/list/death_cry = list(
		MEDIBOT_VOICED_NO_SAD,
		MEDIBOT_VOICED_OH_FUCK,
	)
	speak(pick(death_cry))
	return ..()

//ENERGY WEAPONS, drains power from the weapon to supply your modsuit
/obj/item/gun/energy/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(cell.charge == 0)
		balloon_alert(ninja, "no energy!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(!do_after(ninja, 1.5 SECONDS, target = src, cog_icon = null))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	hacking_module.mod.add_charge(cell.charge)
	hacking_module.charge_message(src, cell.charge)
	cell.charge = 0
	update_appearance()
	visible_message(span_warning("[ninja] drains the energy from the [src]!"))
	do_sparks(number = 3, cardinal_only = FALSE, source = src)
	return COMPONENT_CANCEL_ATTACK_CHAIN

//VENDING MACHINES, overload vending machines to throw its suppy at people
/obj/machinery/vending/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(shoot_inventory)
		balloon_alert(ninja, "already hacked!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(!do_after(ninja, 2 SECONDS, target = src, cog_icon = null))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(!hacking_module.mod.subtract_charge(DEFAULT_CHARGE_DRAIN * 5))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	do_sparks(number = 3, cardinal_only = FALSE, source = src)
	balloon_alert(ninja, "system overloaded!")
	wires.on_pulse(WIRE_THROW)
	return COMPONENT_CANCEL_ATTACK_CHAIN

//RECYCLER, emaggs the recycler disabling its safety
/obj/machinery/recycler/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(obj_flags & EMAGGED)
		balloon_alert(ninja, "already hacked!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	AI_notify_hack()
	if(!do_after(ninja, 30 SECONDS, target = src, cog_icon = null))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	do_sparks(3, cardinal_only = FALSE, source = src)
	emag_act(ninja)

	return COMPONENT_CANCEL_ATTACK_CHAIN

//ELEVATOR CONTROLS//
/obj/machinery/elevator_control_panel/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(obj_flags & EMAGGED)
		balloon_alert(ninja, "already hacked!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(!do_after(ninja, 2 SECONDS, target = src, cog_icon = null))
		return COMPONENT_CANCEL_ATTACK_CHAIN

	do_sparks(3, cardinal_only = FALSE, source = src)
	emag_act(ninja)

	return COMPONENT_CANCEL_ATTACK_CHAIN

//TRAM CONTROLS, overloads the tram causing tram malfunction event only once per round
/obj/machinery/computer/tram_controls/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	var/datum/round_event/tram_malfunction/malfunction_event = locate(/datum/round_event/tram_malfunction) in SSevents.running
	if(malfunction_event)
		balloon_alert(ninja, "tram is already malfunctioning!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	if(specific_transport_id != TRAMSTATION_LINE_1)
		balloon_alert(ninja, "cannot hack this tram!")
		return COMPONENT_CANCEL_ATTACK_CHAIN

	AI_notify_hack()

	if(!do_after(ninja, 20 SECONDS, target = src, cog_icon = null)) //Shorter due to how incredibly easy it is for someone to (even accidentally) interrupt.
		return COMPONENT_CANCEL_ATTACK_CHAIN

	force_event(/datum/round_event_control/tram_malfunction, "ninja interference")
	malfunction_event = locate(/datum/round_event/tram_malfunction) in SSevents.running
	malfunction_event.end_when *= 2
	for(var/obj/machinery/transport/guideway_sensor/sensor as anything in SStransport.sensors)
		// Since faults are now used instead of straight event end_when var, we make a few of them malfunction
		if(prob(rand(15, 30)))
			sensor.local_fault()

	return COMPONENT_CANCEL_ATTACK_CHAIN

//WINDOOR, emaggs the door open
/obj/machinery/door/window/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(!operating && density && hasPower() && !(obj_flags & EMAGGED) && hacking_module.mod.subtract_charge(DEFAULT_CHARGE_DRAIN * 5))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom, emag_act))
	return COMPONENT_CANCEL_ATTACK_CHAIN

//BUTTONS, emaggs the button removing access requirements
/obj/machinery/button/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	if(is_operational && !(obj_flags & EMAGGED))
		emag_act(ninja)
	return COMPONENT_CANCEL_ATTACK_CHAIN

//FIRELOCKS, forces the firelock open.
/obj/machinery/door/firedoor/ninjadrain_act(mob/living/carbon/human/ninja, obj/item/mod/module/hacker/hacking_module)
	crack_open()

#undef NINJA_MIN_DRAIN
#undef NINJA_MAX_DRAIN
///Weapon Recall - Teleports your katana to you, prevents gun use.
/obj/item/mod/module/weapon_recall
	name = "\improper MOD weapon recall module"
	desc = "The cornerstone of a clanmember's life as a blademaster, and a module symbolizing their eternal bond with their weapon. \
		This hooks to the micro bluespace drive inside an energy katana's handle, capable of recalling it to the user's \
		skilled hands wherever they are. However, those that make such a bond with their weapon are cursed to \
		fusing their existence with acts of combat, with a singular purpose; Cutting Down Their Opponent. \
		Their hand a hand that is cutting, their body a body that is cutting, their mind, a mind that is cutting. \
		Ranged weapons are forbidden."
	icon_state = "recall"
	removable = FALSE
	module_type = MODULE_USABLE
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 2
	incompatible_modules = list(/obj/item/mod/module/weapon_recall)
	cooldown_time = 0.5 SECONDS
	required_slots = list(ITEM_SLOT_GLOVES, ITEM_SLOT_BACK|ITEM_SLOT_BELT)
	/// The item linked to the module that will get recalled.
	var/obj/item/linked_weapon
	/// The accepted typepath we can link to.
	var/accepted_type = /obj/item/energy_katana

/obj/item/mod/module/weapon_recall/on_part_activation()
	mod.wearer.add_traits(list(TRAIT_NOGUNS, TRAIT_TOSS_GUN_HARD), REF(src))

/obj/item/mod/module/weapon_recall/on_part_deactivation(deleting = FALSE)
	mod.wearer.remove_traits(list(TRAIT_NOGUNS, TRAIT_TOSS_GUN_HARD), REF(src))

/obj/item/mod/module/weapon_recall/on_use()
	if(!linked_weapon)
		var/obj/item/weapon_to_link = mod.wearer.is_holding_item_of_type(accepted_type)
		if(!weapon_to_link)
			balloon_alert(mod.wearer, "no linked weapon!")
			return
		set_weapon(weapon_to_link)
		balloon_alert(mod.wearer, "[linked_weapon.name] linked")
		return
	if(linked_weapon in mod.wearer.get_all_contents())
		balloon_alert(mod.wearer, "already on self!")
		return
	var/distance = get_dist(mod.wearer, linked_weapon)
	var/in_view = (linked_weapon in view(mod.wearer)) && !(linked_weapon in get_turf(mod.wearer))
	if(!in_view && !drain_power(use_energy_cost * distance))
		balloon_alert(mod.wearer, "not enough charge!")
		return
	linked_weapon.forceMove(linked_weapon.drop_location())
	if(in_view)
		do_sparks(5, FALSE, linked_weapon)
		mod.wearer.visible_message(span_danger("[linked_weapon] flies towards [mod.wearer]!"),span_warning("You hold out your hand and [linked_weapon] flies towards you!"))
		linked_weapon.throw_at(mod.wearer, distance+1, linked_weapon.throw_speed, mod.wearer)
	else
		recall_weapon()

/obj/item/mod/module/weapon_recall/proc/set_weapon(obj/item/weapon)
	linked_weapon = weapon
	RegisterSignal(linked_weapon, COMSIG_MOVABLE_PRE_IMPACT, PROC_REF(catch_weapon))
	RegisterSignal(linked_weapon, COMSIG_QDELETING, PROC_REF(deleted_weapon))

/obj/item/mod/module/weapon_recall/proc/recall_weapon(caught = FALSE)
	linked_weapon.forceMove(get_turf(src))
	var/alert = ""
	if(mod.wearer.put_in_hands(linked_weapon))
		alert = "[linked_weapon.name] teleports to your hand"
	else if(mod.wearer.equip_to_slot_if_possible(linked_weapon, ITEM_SLOT_BELT, disable_warning = TRUE))
		alert = "[linked_weapon.name] sheathes itself in your belt"
	else
		alert = "[linked_weapon.name] teleports under you"
	if(caught)
		if(mod.wearer.is_holding(linked_weapon))
			alert = "you catch [linked_weapon.name]"
		else
			alert = "[linked_weapon.name] lands under you"
	else
		do_sparks(5, FALSE, linked_weapon)
	if(alert)
		balloon_alert(mod.wearer, alert)

/obj/item/mod/module/weapon_recall/proc/catch_weapon(obj/item/source, atom/hit_atom, datum/thrownthing/thrownthing)
	SIGNAL_HANDLER

	if(!mod)
		return
	if(hit_atom != mod.wearer)
		return
	INVOKE_ASYNC(src, PROC_REF(recall_weapon), TRUE)
	return COMPONENT_MOVABLE_IMPACT_NEVERMIND

/obj/item/mod/module/weapon_recall/proc/deleted_weapon(obj/item/source)
	SIGNAL_HANDLER

	linked_weapon = null

//Reinforced DNA Lock - Gibs if wrong DNA, emp-proof.
/obj/item/mod/module/dna_lock/reinforced
	name = "\improper MOD reinforced DNA lock module"
	desc = "A module which engages with the various locks and seals tied to the suit's systems, \
		enabling it to only be worn by someone corresponding with the user's exact DNA profile. \
		Due to utilizing a skintight dampening shield, this one is entirely sealed against electromagnetic interference; \
		it also dutifully protects the secrets of the Spider Clan from unknowing outsiders."
	icon_state = "dnalock_ninja"
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 0.5

/obj/item/mod/module/dna_lock/reinforced/on_mod_activation(datum/source, mob/user)
	. = ..()
	if(. != MOD_CANCEL_ACTIVATE || !isliving(user) || user != mod.wearer)
		return
	if(mod.ai_assistant == user)
		to_chat(mod.ai_assistant, span_danger("<B>fATaL EERRoR</B>: 381200-*#00CODE <B>BLUE</B>\nAI INTErFERenCE DEtECted\nACTi0N DISrEGArdED"))
		return
	var/mob/living/living_user = user
	to_chat(living_user, span_danger("<B>fATaL EERRoR</B>: 382200-*#00CODE <B>RED</B>\nUNAUTHORIZED USE DETECteD\nCoMMENCING SUB-R0UTIN3 13...\nTERMInATING U-U-USER..."))
	living_user.investigate_log("has been gibbed by using a MODsuit equipped with [src].", INVESTIGATE_DEATHS)
	living_user.gib(DROP_ALL_REMAINS)

/obj/item/mod/module/dna_lock/reinforced/on_emp(datum/source, severity)
	return

//EMP Pulse - In addition to normal shielding, can also launch an EMP itself.
/obj/item/mod/module/emp_shield/pulse
	name = "\improper MOD EMP pulse module"
	desc = "This module is normally set to activate on dramatic gestures, inverting and expanding the suit's \
		EMP dampening shield to cause an electromagnetic pulse of its own. While this won't interfere with the wearer, \
		it will piss off everyone around them."
	icon_state = "emp_pulse"
	module_type = MODULE_USABLE
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 10
	cooldown_time = 8 SECONDS

/obj/item/mod/module/emp_shield/pulse/on_use(mob/activator)
	playsound(src, 'sound/effects/empulse.ogg', 60, TRUE)
	empulse(src, heavy_range = 4, light_range = 6, emp_source = src)
	drain_power(use_energy_cost)

/// Ninja Status Readout - Like the normal status display (see the base type), but with a clock.
/obj/item/mod/module/status_readout/ninja
	name = "\improper MOD Spider Clan status readout module"
	desc = "A once-common module, this technology unfortunately went out of fashion in the safer regions of space; \
		and, according to the extra markings on this particular unit's casing, right into the arachnid grip of the Spider Clan. \
		Like other similar units, this one hooks into the suit's spine, and is capable of capturing and displaying \
		all possible biometric data of the wearer; sleep, nutrition, fitness, fingerprints, \
		and even useful information such as their overall health and wellness. This one comes with a clock that calibrates to the \
		local system time, and an operational ID number display. The vital monitor's speaker has been removed."
	display_time = TRUE
	sensor_boost = FALSE
	death_sound = null
	death_sound_volume = null

///Energy Net - Ensnares enemies in a net that prevents movement.
/obj/item/mod/module/energy_net
	name = "\improper MOD energy net module"
	desc = "A custom-built net-thrower. While conventional implementations of this capturing device \
		utilize monomolecular fibers or cutting razorwire, this uses hardlight technology to deploy a \
		trapping field capable of immobilizing even the strongest opponents."
	icon_state = "energy_net"
	removable = FALSE
	module_type = MODULE_ACTIVE
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 6
	incompatible_modules = list(/obj/item/mod/module/energy_net, /obj/item/mod/module/hologram_decoy)
	cooldown_time = 5 SECONDS
	required_slots = list(ITEM_SLOT_GLOVES)
	/// List of all energy nets this module made.
	var/list/energy_nets = list()

/obj/item/mod/module/energy_net/on_part_deactivation(deleting)
	for(var/obj/structure/energy_net/net as anything in energy_nets)
		net.atom_destruction(ENERGY)

/obj/item/mod/module/energy_net/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(IS_SPACE_NINJA(mod.wearer) && isliving(target))
		mod.wearer.say("Get over here!", forced = type)
	var/obj/projectile/net = new /obj/projectile/energy_net(mod.wearer.loc, src)
	net.aim_projectile(target, mod.wearer)
	net.firer = mod.wearer
	playsound(src, 'sound/items/weapons/punchmiss.ogg', 25, TRUE)
	INVOKE_ASYNC(net, TYPE_PROC_REF(/obj/projectile, fire))
	drain_power(use_energy_cost)

/obj/item/mod/module/energy_net/proc/add_net(obj/structure/energy_net/net)
	energy_nets += net
	RegisterSignal(net, COMSIG_QDELETING, PROC_REF(remove_net))

/obj/item/mod/module/energy_net/proc/remove_net(obj/structure/energy_net/net)
	SIGNAL_HANDLER
	energy_nets -= net

/obj/projectile/energy_net
	name = "energy net"
	icon_state = "net_projectile"
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	damage = 0
	range = 9
	hitsound = 'sound/items/fulton/fultext_deploy.ogg'
	hitsound_wall = 'sound/items/fulton/fultext_deploy.ogg'
	/// Reference to the beam following the projectile.
	var/line
	/// Reference to the energy net module.
	var/datum/weakref/net_module

/obj/projectile/energy_net/Initialize(mapload, net_module)
	. = ..()
	src.net_module = WEAKREF(net_module)

/obj/projectile/energy_net/fire(setAngle)
	if(firer)
		line = firer.Beam(src, "net_beam", 'icons/obj/clothing/modsuit/mod_modules.dmi')
	return ..()

/obj/projectile/energy_net/on_hit(mob/living/target, blocked = 0, pierce_hit)
	. = ..()
	if(!istype(target))
		return
	if(locate(/obj/structure/energy_net) in get_turf(target))
		return
	var/obj/structure/energy_net/net = new /obj/structure/energy_net(target.drop_location())
	var/obj/item/mod/module/energy_net/module = net_module?.resolve()
	if(module)
		module.add_net(net)
	firer?.visible_message(span_danger("[firer] caught [target] with an energy net!"), span_notice("You caught [target] with an energy net!"))
	if(target.buckled)
		target.buckled.unbuckle_mob(target, force = TRUE)
	net.buckle_mob(target, force = TRUE)

/obj/projectile/energy_net/Destroy()
	QDEL_NULL(line)
	return ..()

/obj/structure/energy_net
	name = "energy net"
	desc = "It's a net made of green energy."
	icon = 'icons/effects/effects.dmi'
	icon_state = "energynet"
	density = TRUE //Can't pass through.
	anchored = TRUE //Can't drag/grab the net.
	layer = ABOVE_ALL_MOB_LAYER
	plane = ABOVE_GAME_PLANE
	max_integrity = 60 //How much health it has.
	can_buckle = TRUE
	buckle_lying = 0
	buckle_prevents_pull = TRUE

/obj/structure/energy_net/Initialize(mapload)
	. = ..()
	var/image/underlay = image(icon, "energynet_underlay")
	underlay.layer = BELOW_MOB_LAYER
	SET_PLANE_EXPLICIT(underlay, GAME_PLANE, src)
	add_overlay(underlay)
	ADD_TRAIT(src, TRAIT_DANGEROUS_BUCKLE, INNATE_TRAIT)

/obj/structure/energy_net/play_attack_sound(damage, damage_type = BRUTE, damage_flag = 0)
	if(damage_type == BRUTE || damage_type == BURN)
		playsound(src, 'sound/items/weapons/slash.ogg', 80, TRUE)

/obj/structure/energy_net/atom_destruction(damage_flag)
	for(var/mob/recovered_mob as anything in buckled_mobs)
		recovered_mob.visible_message(span_notice("[recovered_mob] is recovered from the energy net!"), span_notice("You are recovered from the energy net!"), span_hear("You hear a grunt."))
	return ..()

/obj/structure/energy_net/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/energy_net/user_buckle_mob(mob/living/buckled_mob, mob/user, check_loc = TRUE)
	return//We only want our target to be buckled

/obj/structure/energy_net/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	return//The net must be destroyed to free the target

///Holographic Decoy Module - Projects a lifelike hologram decoy while cloaking the user, then detonates in an EMP flash.
/obj/item/mod/module/hologram_decoy
	name = "\improper MOD holographic decoy module"
	desc = "A state-of-the-art Spider Clan misdirection system. When activated, projects a lifelike holographic decoy of the user that runs towards targets, absorbing attacks. The user enters brief optical camouflage. Upon taking damage or after 5 seconds, the hologram overloads with an electromagnetic flash pulse, disorienting pursuers."
	icon_state = "decoy_ninja"
	module_type = MODULE_USABLE
	complexity = 3
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 24
	incompatible_modules = list(/obj/item/mod/module/energy_net, /obj/item/mod/module/hologram_decoy)
	cooldown_time = 24 SECONDS
	required_slots = list(ITEM_SLOT_GLOVES)

/obj/item/mod/module/hologram_decoy/ninja
	removable = FALSE

/obj/item/mod/module/hologram_decoy/ninja/on_use(mob/activator)
	var/mob/living/ninja = mod?.wearer
	if(!istype(ninja))
		return
	if(!drain_power(use_energy_cost))
		return

	playsound(ninja, 'sound/effects/phasein.ogg', 50, TRUE)
	do_sparks(2, TRUE, ninja)

	var/mob/living/basic/illusion/ninja_decoy/decoy = new(ninja.loc)
	decoy.setup_decoy(ninja)

	animate(ninja, alpha = 25, time = 0.5 SECONDS)
	ninja.alpha = 25
	ADD_TRAIT(ninja, TRAIT_SILENT_FOOTSTEPS, REF(src))
	to_chat(ninja, span_notice("You engage optical camouflage as a holographic decoy deploys!"))
	addtimer(CALLBACK(src, PROC_REF(end_stealth), WEAKREF(ninja)), 2.5 SECONDS)

/obj/item/mod/module/hologram_decoy/ninja/proc/end_stealth(datum/weakref/ninja_ref)
	var/mob/living/ninja = ninja_ref?.resolve()
	if(!ninja || QDELETED(ninja))
		return
	var/obj/item/mod/module/stealth/stealth_mod = locate() in mod?.modules
	if(stealth_mod?.active)
		animate(ninja, alpha = stealth_mod.stealth_alpha, time = 0.5 SECONDS)
		ninja.alpha = stealth_mod.stealth_alpha
	else
		animate(ninja, alpha = initial(ninja.alpha), time = 0.5 SECONDS)
		ninja.alpha = initial(ninja.alpha)
	REMOVE_TRAIT(ninja, TRAIT_SILENT_FOOTSTEPS, REF(src))

/mob/living/basic/illusion/ninja_decoy
	name = "holographic decoy"
	desc = "A flickering cybernetic hologram projecting the appearance of a Space Ninja."
	ai_controller = null
	maxHealth = 25
	health = 25
	speed = -0.3
	density = TRUE
	var/detonated = FALSE
	var/datum/weakref/creator_ref

/mob/living/basic/illusion/ninja_decoy/Initialize(mapload)
	. = ..()
	RegisterSignals(src, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_ATOM_ATTACKBY, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_BULLET_ACT, COMSIG_ATOM_HITBY, COMSIG_ATOM_HULK_ATTACK), PROC_REF(on_attacked))
	addtimer(CALLBACK(src, PROC_REF(detonate)), 5 SECONDS)

/mob/living/basic/illusion/ninja_decoy/proc/on_attacked()
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(detonate))

/mob/living/basic/illusion/ninja_decoy/on_damage_taken(mob/living/source)
	detonate()

/mob/living/basic/illusion/ninja_decoy/death(gibbed)
	detonate()
	return ..()

/mob/living/basic/illusion/ninja_decoy/Bump(atom/obstacle)
	. = ..()
	if(isliving(obstacle))
		var/mob/living/target = obstacle
		var/mob/living/creator = creator_ref?.resolve()
		if(target != creator && (!target.mind || !IS_SPACE_NINJA(target)))
			detonate()

/mob/living/basic/illusion/ninja_decoy/proc/setup_decoy(mob/living/creator)
	creator_ref = WEAKREF(creator)
	parent_mob_ref = WEAKREF(creator)
	name = creator.name
	appearance = creator.appearance
	alpha = 255
	invisibility = INVISIBILITY_NONE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	setDir(creator.dir)
	transform = initial(transform)
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y

	var/mob/living/closest_target = null
	var/closest_dist = 8
	for(var/mob/living/candidate in range(7, src))
		if(candidate == creator || candidate == src || candidate.stat == DEAD)
			continue
		if(candidate.mind && IS_SPACE_NINJA(candidate))
			continue
		var/dist = get_dist(src, candidate)
		if(dist < closest_dist)
			closest_dist = dist
			closest_target = candidate

	if(closest_target)
		walk_towards(src, closest_target, 3)
	else
		walk(src, creator.dir, 3)

/mob/living/basic/illusion/ninja_decoy/proc/detonate()
	if(detonated || QDELETED(src))
		return
	detonated = TRUE
	walk(src, 0)
	var/turf/epicenter = get_turf(src)
	if(epicenter)
		playsound(epicenter, 'sound/effects/empulse.ogg', 75, TRUE)
		playsound(epicenter, 'sound/items/weapons/flashbang.ogg', 75, TRUE)
		do_sparks(5, TRUE, epicenter)
		new /obj/effect/temp_visual/emp/pulse(epicenter)
		new /obj/effect/dummy/lighting_obj(epicenter, 4, 3, COLOR_WHITE, 1)
		empulse(epicenter, heavy_range = 0, light_range = 2, emp_source = src)
		var/mob/living/creator = creator_ref?.resolve()
		for(var/mob/living/victim in viewers(3, epicenter))
			if(victim == src)
				continue
			victim.flash_act(intensity = 2, override_blindness_check = FALSE, affect_silicon = TRUE, visual = TRUE, length = 3 SECONDS)
			if(victim != creator && (!victim.mind || !IS_SPACE_NINJA(victim)))
				victim.adjust_confusion(3 SECONDS)
				victim.adjust_dizzy(5 SECONDS)
				victim.Knockdown(1.5 SECONDS)
				victim.Paralyze(0.5 SECONDS)
	qdel(src)

///Adrenaline Boost - Stops all stuns the ninja is affected with, increases his speed.
/obj/item/mod/module/adrenaline_boost
	name = "\improper MOD adrenaline boost module"
	desc = "The secrets of the Spider Clan are many. The exact specifications of their suits, \
		the techniques they use to make every singular cut make their enemies weep with admiration, \
		but one of their greatest mysteries is the chemical compound their assassin-saboteurs use in times of need. \
		It's capable of clearing any fatigue whatsoever from the user, any immobilizing effect, and can even \
		cure total paralysis. All that's known is that the fluid requires radiation to properly 'cook,' \
		so this module demands radium to be refilled with."
	icon_state = "adrenaline_boost"
	removable = FALSE
	module_type = MODULE_USABLE
	allow_flags = MODULE_ALLOW_INCAPACITATED
	incompatible_modules = list(/obj/item/mod/module/adrenaline_boost, /obj/item/mod/module/nanite_repair)
	cooldown_time = 12 SECONDS
	required_slots = list(ITEM_SLOT_BACK|ITEM_SLOT_BELT)
	/// What reagent we need to refill?
	var/reagent_required = /datum/reagent/uranium/radium
	/// How much of a reagent we need to refill the boost.
	var/reagent_required_amount = 20

/obj/item/mod/module/adrenaline_boost/Initialize(mapload)
	. = ..()
	create_reagents(reagent_required_amount)
	reagents.add_reagent(reagent_required, reagent_required_amount)

/obj/item/mod/module/adrenaline_boost/used()
	if(!reagents.has_reagent(reagent_required, reagent_required_amount))
		balloon_alert(mod.wearer, "no charge!")
		return FALSE
	return ..()

/obj/item/mod/module/adrenaline_boost/on_use(mob/activator)
	if(IS_SPACE_NINJA(mod.wearer))
		mod.wearer.say(pick_list_replacements(NINJA_FILE, "lines"), forced = type)
	to_chat(mod.wearer, span_notice("You have used the adrenaline boost."))
	mod.wearer.SetAllImmobility(0)
	mod.wearer.adjust_stamina_loss(-200)
	mod.wearer.remove_status_effect(/datum/status_effect/speech/stutter)
	mod.wearer.reagents.add_reagent(/datum/reagent/medicine/stimulants, 5)
	reagents.remove_reagent(reagent_required, reagents.total_volume * 0.75)
	addtimer(CALLBACK(src, PROC_REF(boost_aftereffects), mod.wearer), 7 SECONDS)

/obj/item/mod/module/adrenaline_boost/on_install()
	. = ..()
	RegisterSignal(mod, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(try_boost))

/obj/item/mod/module/adrenaline_boost/on_uninstall(deleting = FALSE)
	. = ..()
	UnregisterSignal(mod, COMSIG_ATOM_ITEM_INTERACTION)

/obj/item/mod/module/adrenaline_boost/proc/try_boost(source, mob/user, obj/item/attacking_item)
	SIGNAL_HANDLER
	if(charge_boost(attacking_item))
		return COMPONENT_NO_AFTERATTACK
	return NONE

/obj/item/mod/module/adrenaline_boost/proc/charge_boost(obj/item/attacking_item)
	if(!attacking_item.is_open_container())
		return FALSE
	if(reagents.has_reagent(reagent_required, reagent_required_amount))
		balloon_alert(mod.wearer, "already charged!")
		return FALSE
	if(!attacking_item.reagents.trans_to(src, reagent_required_amount, target_id = reagent_required))
		return FALSE
	balloon_alert(mod.wearer, "charge [reagents.has_reagent(reagent_required, reagent_required_amount) ? "fully" : "partially"] reloaded")
	return TRUE

/obj/item/mod/module/adrenaline_boost/proc/boost_aftereffects(mob/affected_mob)
	if(!affected_mob)
		return
	reagents.trans_to(affected_mob, reagents.total_volume)
	to_chat(affected_mob, span_danger("You are beginning to feel the after-effect of the injection."))

///Nanite Cellular Repair Matrix - Rapidly regenerates heavy brute and burn damage using nanite charges.
/obj/item/mod/module/nanite_repair/ninja
	name = "\improper MOD nanite cellular repair module"
	desc = "A specialized biomedical restoration system housing concentrated Spider Clan restorative nanomachines. \
		When triggered, the matrix surges through the operative's bloodstream to rapidly clot open lacerations with synthetic \
		coagulants, fuse damaged tissue, and regenerate burns. Consumes zero suit power, utilizing self-contained \
		nanite charges refueled with radium."
	icon_state = "nanite_repair"
	removable = FALSE
	module_type = MODULE_USABLE
	allow_flags = MODULE_ALLOW_INCAPACITATED
	complexity = 0
	cooldown_time = 15 SECONDS
	use_energy_cost = 0
	incompatible_modules = list(/obj/item/mod/module/adrenaline_boost, /obj/item/mod/module/nanite_repair)
	required_slots = list(ITEM_SLOT_BACK|ITEM_SLOT_BELT)
	/// Current remaining charges
	var/charges = 3
	/// Maximum charge capacity
	var/max_charges = 3
	/// Radium reagent required per charge
	var/radium_per_charge = 5

/obj/item/mod/module/nanite_repair/ninja/used(mob/activator)
	if(charges <= 0)
		balloon_alert(mod.wearer, "depleted! needs radium")
		return FALSE
	return ..()

/obj/item/mod/module/nanite_repair/ninja/on_use(mob/activator)
	charges--
	if(IS_SPACE_NINJA(mod.wearer))
		mod.wearer.say("Engaging cellular reconstruction matrix!", forced = type)
	to_chat(mod.wearer, span_notice("You engage the nanite cellular repair matrix. Medical nanites rapidly seal your wounds! ([charges] / [max_charges] charges remaining)"))
	if(charges <= 0)
		balloon_alert(mod.wearer, "0 / [max_charges] charges remaining - needs radium!")
		to_chat(mod.wearer, span_warning("Nanite cellular repair matrix is now depleted! Radium required to replenish nanite cartridges (5u per charge)."))
	else
		balloon_alert(mod.wearer, "[charges] / [max_charges] charges remaining")
	playsound(mod.wearer, 'sound/items/hypospray.ogg', 50, TRUE)
	mod.wearer.reagents?.add_reagent(/datum/reagent/medicine/coagulant, 2)
	INVOKE_ASYNC(src, PROC_REF(cellular_repair_cycle), mod.wearer)

/obj/item/mod/module/nanite_repair/ninja/on_install()
	. = ..()
	RegisterSignal(mod, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(try_reload))

/obj/item/mod/module/nanite_repair/ninja/on_uninstall(deleting = FALSE)
	. = ..()
	UnregisterSignal(mod, COMSIG_ATOM_ITEM_INTERACTION)

/obj/item/mod/module/nanite_repair/ninja/proc/try_reload(source, mob/user, obj/item/attacking_item)
	SIGNAL_HANDLER

	if(!attacking_item.is_open_container())
		return NONE
	if(charges >= max_charges)
		balloon_alert(user, "already fully charged!")
		return COMPONENT_NO_AFTERATTACK
	var/datum/reagents/reagent_holder = attacking_item.reagents
	if(!reagent_holder)
		return NONE
	var/radium_available = reagent_holder.get_reagent_amount(/datum/reagent/uranium/radium)
	if(radium_available < radium_per_charge)
		balloon_alert(user, "needs at least [radium_per_charge]u radium per charge!")
		return COMPONENT_NO_AFTERATTACK

	var/missing_charges = max_charges - charges
	var/charges_to_restore = clamp(floor(radium_available / radium_per_charge), 1, missing_charges)
	var/radium_to_consume = charges_to_restore * radium_per_charge
	reagent_holder.remove_reagent(/datum/reagent/uranium/radium, radium_to_consume)
	charges += charges_to_restore
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)

	if(charges >= max_charges)
		balloon_alert(user, "fully recharged! ([charges]/[max_charges])")
		to_chat(user, span_notice("Nanite matrix fully replenished with [radium_to_consume]u radium. ([charges]/[max_charges] charges)"))
	else
		balloon_alert(user, "recharged +[charges_to_restore] charge\s! ([charges]/[max_charges])")
		to_chat(user, span_notice("Nanite matrix partially replenished with [radium_to_consume]u radium. ([charges]/[max_charges] charges)"))
	return COMPONENT_NO_AFTERATTACK

/obj/item/mod/module/nanite_repair/ninja/proc/cellular_repair_cycle(mob/living/carbon/human/target)
	for(var/i in 1 to 15)
		if(QDELETED(target) || !mod || !mod.wearer || target != mod.wearer)
			break
		target.adjust_brute_loss(-5)
		target.adjust_fire_loss(-5)
		target.adjust_blood_volume(2)
		new /obj/effect/temp_visual/heal(get_turf(target), COLOR_HEALING_CYAN)
		playsound(target, 'sound/effects/spray.ogg', 25, TRUE)
		sleep(1 SECONDS)
	if(!QDELETED(target) && target == mod?.wearer)
		to_chat(target, span_notice("Nanite cellular repair complete."))

