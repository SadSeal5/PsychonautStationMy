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
	icon_state = "energy_katana"
	inhand_icon_state = "energy_katana"
	worn_icon_state = "energy_katana"
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
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_BELT
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

/obj/item/plasma_kusarigama/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || interacting_with == user)
		return NONE
	if(get_dist(user, interacting_with) > 4)
		balloon_alert(user, "target too far!")
		return ITEM_INTERACT_BLOCKING
	if(!COOLDOWN_FINISHED(src, trip_timer))
		balloon_alert(user, "on cooldown!")
		return ITEM_INTERACT_BLOCKING

	COOLDOWN_START(src, trip_timer, trip_cooldown)
	user.Beam(interacting_with, icon_state = "ninja_cable", maxdistance = 5, time = 0.5 SECONDS)
	playsound(interacting_with, 'sound/items/weapons/whip.ogg', 50, TRUE)

	var/mob/living/target = interacting_with
	target.Knockdown(2 SECONDS)
	var/obj/item/held = target.get_active_held_item()
	if(held)
		target.dropItemToGround(held)
		target.visible_message(span_danger("[user]'s kusarigama chain wraps around [target]'s wrist, violently wrenching [held] from their grip!"), span_userdanger("[user]'s kusarigama chain rips [held] out of your hands!"))
	else
		target.visible_message(span_danger("[user]'s kusarigama chain sweeps [target]'s legs out, slamming them to the ground!"), span_userdanger("[user]'s kusarigama sweeps your legs out!"))

	balloon_alert(user, "tripped & disarmed!")
	return ITEM_INTERACT_SUCCESS
