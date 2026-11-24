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
		if(interacting_with == user)
			return NONE
		return jaunt.attack_teleport(user, interacting_with) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
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

/datum/action/innate/dash/ninja/GiveAction(mob/viewer) //this action should be invisible, as its handled by right-click
	return

/datum/action/innate/dash/ninja/HideFrom(mob/viewer)
	return

/// Returns TRUE if target is a valid human-tier enemy for execute dash/step refunds.
/proc/is_ninja_execute_target(mob/living/target)
	if(QDELETED(target) || istype(target, /mob/living/basic/illusion/ninja_decoy))
		return FALSE
	if((target.mind && IS_SPACE_NINJA(target)) || target.has_faction(ROLE_NINJA))
		return FALSE
	return ishuman(target) || (target.mind && target.mob_size >= MOB_SIZE_HUMAN)

/// Teleports to a tile adjacent to a mob, then attacks it
/datum/action/innate/dash/ninja/proc/attack_teleport(mob/living/user, mob/living/stabbing)
	if(!istype(stabbing) || stabbing == user)
		return FALSE
	if(HAS_TRAIT(user, TRAIT_PACIFISM) || HAS_TRAIT(user, TRAIT_CANT_ATTACK))
		return FALSE
	var/obj/item/sword = target
	var/was_adjacent = user.Adjacent(stabbing)
	var/dashed = !was_adjacent
	if(!was_adjacent)
		var/list/turf/line = get_line(user, stabbing)
		if(length(line) <= 1 || !teleport(user, line[length(line) - 1]))
			return FALSE
	if(!stabbing.IsReachableBy(user, sword?.reach))
		return FALSE
	var/was_conscious = (stabbing.stat == STABLE)
	sword.melee_attack_chain(user, stabbing)
	if(dashed && was_conscious && is_ninja_execute_target(stabbing) && stabbing.stat >= SOFT_CRIT)
		refund_charge()
		sword.balloon_alert(user, "execute! dash refunded")
	if(dashed && prob(5) && check_holidays(APRIL_FOOLS))
		user.say("Heh, nothin' personnel kid!", forced = "*teleports behind you**")
	return TRUE
