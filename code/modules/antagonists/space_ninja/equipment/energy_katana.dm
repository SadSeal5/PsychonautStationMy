/**
 * # Energy Katana
 *
 * The space ninja's katana.
 *
 * The katana that only space ninja spawns with.  Comes with 30 force and throwforce, along with a signature special jaunting system.
 * Upon clicking on a tile when right clicking, the user will teleport to that tile, assuming their target was not dense.
 * The katana has 3 dashes stored at maximum, and upon using the dash, it will return 20 seconds after it was used.
 * It also has a special feature where if it is tossed at a space ninja who owns it (determined by the ninja suit), the ninja will catch the katana instead of being hit by it.
 *
 */
/obj/item/energy_katana
	name = "energy katana"
	desc = "A katana infused with strong energy."
	desc_controls = "Right-click to dash."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "energy_katana"
	inhand_icon_state = "energy_katana"
	worn_icon_state = "energy_katana"
	icon_angle = 35
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 30
	throwforce = 30
	block_chance = 50
	armour_penetration = 50
	w_class = WEIGHT_CLASS_BULKY
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	pickup_sound = 'sound/items/unsheath.ogg'
	drop_sound = 'sound/items/sheath.ogg'
	block_sound = 'sound/items/weapons/block_blade.ogg'
	attack_verb_continuous = list("attacks", "slashes", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "slice", "tear", "lacerate", "rip", "dice", "cut")
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_BELT
	sharpness = SHARP_EDGED
	max_integrity = 200
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	item_flags = NEEDS_PERMIT
	var/datum/effect_system/basic/spark_spread/spark_system
	var/datum/action/innate/dash/ninja/jaunt

/obj/item/energy_katana/Initialize(mapload)
	. = ..()
	jaunt = new(src)
	spark_system = new(src, 5, FALSE)
	spark_system.attach(src)

/obj/item/energy_katana/examine(mob/user)
	. = ..()
	if(!QDELETED(jaunt))
		. += span_notice("It has [jaunt.current_charges]/[jaunt.max_charges] combat dash charges remaining.")

/obj/item/energy_katana/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(isliving(interacting_with))
		jaunt.attack_teleport(user, interacting_with)
		return ITEM_INTERACT_SUCCESS
	if(jaunt.teleport(user, interacting_with))
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/item/energy_katana/equipped(mob/user, slot, initial)
	. = ..()
	if(!QDELETED(jaunt))
		jaunt.Grant(user, src)

/obj/item/energy_katana/dropped(mob/user)
	. = ..()
	if(!QDELETED(jaunt))
		jaunt.Remove(user)

/obj/item/energy_katana/Destroy()
	QDEL_NULL(spark_system)
	QDEL_NULL(jaunt)
	return ..()

/datum/action/innate/dash/ninja
	current_charges = 3
	max_charges = 3
	charge_rate = 200
	beam_length = 1 SECONDS
	recharge_sound = null
	var/list/pending_charge_timers = list()

/datum/action/innate/dash/ninja/Destroy()
	for(var/timer_id in pending_charge_timers)
		deltimer(timer_id)
	pending_charge_timers.Cut()
	return ..()

/datum/action/innate/dash/ninja/GiveAction(mob/viewer) //this action should be invisible, as its handled by right-click
	return

/datum/action/innate/dash/ninja/HideFrom(mob/viewer)
	return

/datum/action/innate/dash/ninja/teleport(mob/user, atom/target)
	if(!IsAvailable(feedback = TRUE))
		return FALSE

	var/turf/current_turf = get_turf(user)
	var/turf/target_turf = get_turf(target)
	if(!(target in view(user.client?.view || world.view, user)))
		user.balloon_alert(user, "out of view!")
		return FALSE
	if(target_turf.is_blocked_turf_ignore_climbable())
		user.balloon_alert(user, "destination blocked!")
		return FALSE
	if(!do_teleport(user, target_turf, no_effects = TRUE))
		user.balloon_alert(user, "dash blocked!")
		return FALSE

	var/obj/spot_one = new phaseout(current_turf, user.dir)
	var/obj/spot_two = new phasein(target_turf, user.dir)
	spot_one.Beam(spot_two, beam_effect, time = beam_length)
	playsound(target_turf, dash_sound, 25, TRUE)
	current_charges--
	pending_charge_timers += addtimer(CALLBACK(src, PROC_REF(charge)), charge_rate, TIMER_STOPPABLE)
	owner?.update_mob_action_buttons()
	SEND_SIGNAL(src, COMSIG_DASH_ACTION_DASHED)
	return TRUE

/datum/action/innate/dash/ninja/charge()
	if(length(pending_charge_timers))
		pending_charge_timers.Cut(1, 2)
	return ..()

/datum/action/innate/dash/ninja/proc/refund_charge()
	if(length(pending_charge_timers))
		var/timer_id = pending_charge_timers[length(pending_charge_timers)]
		pending_charge_timers.Cut(length(pending_charge_timers))
		deltimer(timer_id)
	if(current_charges < max_charges)
		current_charges = min(current_charges + 1, max_charges)
		SEND_SIGNAL(src, COMSIG_DASH_ACTION_CHARGED)
		owner?.update_mob_action_buttons()

/// Teleports to a tile adjacent to a mob, then attacks it
/datum/action/innate/dash/ninja/proc/attack_teleport(mob/living/user, mob/living/stabbing)
	var/list/turf/line = get_line(user, stabbing)
	var/obj/item/sword = target
	if(length(line) <= 1 || !teleport(user, line[length(line) - 1])) // teleports to the second last turf, should be adjacent to the target
		return
	if(!stabbing.IsReachableBy(user, sword?.reach))
		return
	var/was_conscious = (stabbing.stat == STABLE)
	sword.melee_attack_chain(user, stabbing)
	if(!QDELETED(stabbing) && was_conscious && stabbing.stat >= SOFT_CRIT)
		refund_charge()
		sword.balloon_alert(user, "execute! dash refunded")
	if(prob(5) && check_holidays(APRIL_FOOLS))
		user.say("Heh, nothin' personnel kid!", forced = "*teleports behind you**")
