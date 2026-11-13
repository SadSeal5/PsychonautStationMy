/**
 * # Plasma Kusarigama
 *
 * A specialized Spider Clan primary weapon.
 * Features extended 2-tile melee reach, and right-click tether whip to trip and disarm targets at up to 4 tiles.
 */
/obj/item/plasma_kusarigama
	name = "\improper plasma kusarigama"
	desc = "A Spider Clan chained scythe and heavy ballast infused with superheated plasma. Features extended reach, and can wrap around enemy limbs to trip and disarm targets at a distance."
	desc_controls = "Right-click target to trip and disarm."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "plasma_kusarigama"
	inhand_icon_state = "plasma_kusarigama"
	worn_icon_state = "plasma_kusarigama"
	icon_angle = 35
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 24
	throwforce = 24
	block_chance = 40
	armour_penetration = 40
	reach = 2
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BELT
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	block_sound = 'sound/items/weapons/block_blade.ogg'
	pickup_sound = 'sound/items/unsheath.ogg'
	drop_sound = 'sound/items/sheath.ogg'
	attack_verb_continuous = list("slashes", "slices", "sweeps", "hooks", "whips")
	attack_verb_simple = list("slash", "slice", "sweep", "hook", "whip")
	item_flags = NEEDS_PERMIT
	max_integrity = 200
	COOLDOWN_DECLARE(trip_timer)
	var/trip_cooldown = 6 SECONDS

/obj/item/plasma_kusarigama/examine(mob/user)
	. = ..()
	if(COOLDOWN_FINISHED(src, trip_timer))
		. += span_notice("The chain ballast is ready to trip and disarm targets.")
	else
		. += span_warning("The chain ballast is rewinding ([round(COOLDOWN_TIMELEFT(src, trip_timer) / 10, 0.1)]s left).")

/obj/item/plasma_kusarigama/attack_secondary(mob/living/victim, mob/living/user, list/modifiers, list/attack_modifiers)
	ranged_interact_with_atom_secondary(victim, user, modifiers)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/plasma_kusarigama/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || interacting_with == user)
		return NONE
	if(user.incapacitated || user.buckled || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return ITEM_INTERACT_BLOCKING
	if(!isturf(user.loc))
		return ITEM_INTERACT_BLOCKING
	if(!(interacting_with in view(user)) || user.z != interacting_with.z)
		return ITEM_INTERACT_BLOCKING
	if(get_dist(user, interacting_with) > 4)
		balloon_alert(user, "target too far!")
		return ITEM_INTERACT_BLOCKING

	var/turf/user_turf = get_turf(user)
	var/turf/target_turf = get_turf(interacting_with)
	for(var/turf/line_turf in (get_line(user_turf, target_turf) - user_turf))
		if(line_turf.density)
			balloon_alert(user, "blocked by terrain!")
			return ITEM_INTERACT_BLOCKING
		for(var/obj/obstacle in line_turf)
			if(obstacle.density && !HAS_TRAIT(obstacle, TRAIT_CLIMBABLE))
				balloon_alert(user, "blocked by obstacle!")
				return ITEM_INTERACT_BLOCKING
	for(var/obj/obstacle in user_turf)
		if(obstacle.density && (obstacle.flags_1 & ON_BORDER_1) && obstacle.dir == get_dir(user_turf, target_turf))
			balloon_alert(user, "blocked by obstacle!")
			return ITEM_INTERACT_BLOCKING

	if(!COOLDOWN_FINISHED(src, trip_timer))
		balloon_alert(user, "on cooldown!")
		return ITEM_INTERACT_BLOCKING

	COOLDOWN_START(src, trip_timer, trip_cooldown)
	user.Beam(interacting_with, icon_state = "ninja_cable", maxdistance = 5, time = 0.5 SECONDS)
	playsound(interacting_with, 'sound/items/weapons/whip.ogg', 50, TRUE)

	var/mob/living/target = interacting_with
	var/was_lying = (target.body_position == LYING_DOWN)
	log_combat(user, target, "tripped and disarmed with", src)
	target.Knockdown(2 SECONDS)
	var/obj/item/disarmed_item
	var/obj/item/held = target.get_active_held_item()
	if(held && target.dropItemToGround(held))
		disarmed_item = held
	else
		for(var/obj/item/other_held as anything in target.held_items)
			if(other_held && target.dropItemToGround(other_held))
				disarmed_item = other_held
				break

	var/reeled_in = FALSE
	if(was_lying && !target.anchored && !target.buckled && target.move_resist < MOVE_FORCE_OVERPOWERING && isturf(target.loc) && get_dist(user, target) > 2)
		target.throw_at(target = get_turf(user), range = min(2, get_dist(target, user) - 1), speed = 1.5, thrower = user, spin = FALSE, gentle = TRUE)
		reeled_in = TRUE

	if(disarmed_item && reeled_in)
		target.visible_message(span_danger("[user]'s kusarigama chain rips [disarmed_item] from [target]'s grip and drags [target.p_them()] closer!"), span_userdanger("[user]'s kusarigama chain rips [disarmed_item] out of your hands and drags you closer!"))
		balloon_alert(user, "disarmed & reeled in!")
	else if(disarmed_item)
		target.visible_message(span_danger("[user]'s kusarigama chain wraps around [target]'s wrist, violently wrenching [disarmed_item] from their grip!"), span_userdanger("[user]'s kusarigama chain rips [disarmed_item] out of your hands!"))
		balloon_alert(user, "tripped & disarmed!")
	else if(reeled_in)
		target.visible_message(span_danger("[user]'s kusarigama chain hooks [target] and drags [target.p_them()] closer!"), span_userdanger("[user]'s kusarigama hooks you and drags you closer!"))
		balloon_alert(user, "reeled in!")
	else
		target.visible_message(span_danger("[user]'s kusarigama chain sweeps [target]'s legs out, slamming them to the ground!"), span_userdanger("[user]'s kusarigama sweeps your legs out!"))
		balloon_alert(user, "tripped & disarmed!")

	return ITEM_INTERACT_SUCCESS
