/**
 * # Dual Nanite Daggers
 *
 * A specialized Spider Clan primary weapon.
 * Strikes twice in rapid succession. Slashes from behind deal critical damage and silence the victim.
 * Right-clicking a living target allows the ninja to shadow step behind them and strike immediately.
 */
/obj/item/nanite_daggers
	name = "\improper dual nanite daggers"
	desc = "A pair of twin high-frequency nanite daggers designed for silent infiltration. Wielded in one hand, they strike in rapid succession. Slashes from behind inflict grievous critical damage and silence the victim's vocal cords."
	desc_controls = "Right-click target to shadow step behind them."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "nanite_daggers"
	inhand_icon_state = "nanite_daggers"
	worn_icon_state = "energy_katana"
	icon_angle = 35
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 16
	throwforce = 20
	block_chance = 25
	armour_penetration = 60
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_BELT
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	block_sound = 'sound/items/weapons/block_blade.ogg'
	pickup_sound = 'sound/items/unsheath.ogg'
	drop_sound = 'sound/items/sheath.ogg'
	attack_verb_continuous = list("slashes", "stabs", "punctures", "carves")
	attack_verb_simple = list("slash", "stab", "puncture", "carve")
	item_flags = NEEDS_PERMIT
	max_integrity = 200
	var/charges = 1
	var/max_charges = 1
	var/charge_timer

/obj/item/nanite_daggers/Destroy()
	if(charge_timer)
		deltimer(charge_timer)
		charge_timer = null
	return ..()

/obj/item/nanite_daggers/examine(mob/user)
	. = ..()
	. += span_notice("It has [charges]/[max_charges] shadow step charges available.")

/obj/item/nanite_daggers/attack(mob/living/target_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(. == TRUE)
		return
	if(!isliving(target_mob) || QDELETED(target_mob))
		return

	var/bonus_damage = 0
	if(user.dir == target_mob.dir)
		bonus_damage = 16
		target_mob.apply_status_effect(/datum/status_effect/silenced, 3 SECONDS)
		to_chat(user, span_danger("Backstab! [target_mob] is silenced!"))
		balloon_alert(user, "backstab!")

	target_mob.apply_damage(16 + bonus_damage, BRUTE, def_zone = user.zone_selected, sharpness = SHARP_EDGED)
	playsound(target_mob, 'sound/items/weapons/bladeslice.ogg', 50, TRUE)
	do_sparks(2, TRUE, target_mob)

/obj/item/nanite_daggers/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || interacting_with == user)
		return NONE
	if(!(interacting_with in view(user)))
		balloon_alert(user, "not in sight!")
		return ITEM_INTERACT_BLOCKING
	if(charges <= 0)
		balloon_alert(user, "no charges!")
		return ITEM_INTERACT_BLOCKING

	var/turf/target_turf = get_turf(interacting_with)
	if(!target_turf)
		return NONE

	var/turf/behind = get_step(target_turf, REVERSE_DIR(interacting_with.dir))
	if(!behind || behind.density || istype(behind, /turf/closed))
		behind = null
		for(var/step_dir in list(turn(interacting_with.dir, 90), turn(interacting_with.dir, -90), interacting_with.dir))
			var/turf/candidate = get_step(target_turf, step_dir)
			if(candidate && !candidate.density && !istype(candidate, /turf/closed))
				behind = candidate
				break

	if(!behind)
		balloon_alert(user, "nowhere to step!")
		return ITEM_INTERACT_BLOCKING

	var/turf/old_loc = get_turf(user)
	new /obj/effect/temp_visual/dir_setting/ninja/shadow(old_loc, user.dir)
	user.forceMove(behind)
	new /obj/effect/temp_visual/dir_setting/ninja/shadow(behind, user.dir)
	user.setDir(get_dir(user, interacting_with))

	melee_attack_chain(user, interacting_with)

	charges--
	start_recharge()
	return ITEM_INTERACT_SUCCESS

/obj/item/nanite_daggers/proc/start_recharge()
	if(charge_timer || charges >= max_charges)
		return
	charge_timer = addtimer(CALLBACK(src, PROC_REF(recharge_tick)), 8 SECONDS, TIMER_STOPPABLE)

/obj/item/nanite_daggers/proc/recharge_tick()
	charge_timer = null
	if(charges < max_charges)
		charges++
		if(ismob(loc))
			to_chat(loc, span_notice("[src] recovered a shadow step charge ([charges]/[max_charges])."))
		if(charges < max_charges)
			start_recharge()
