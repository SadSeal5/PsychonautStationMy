// MARK: Effects
/obj/effect/shadow_bind_anchor
	name = "writhing shadows"
	desc = "Tendrils of shadow coil here."
	icon = 'icons/mob/antagonists/shadowling/shadowling_objects.dmi'
	icon_state = "tendril"

	layer = EFFECTS_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE
	obj_flags = IGNORE_DENSITY

	can_buckle = TRUE
	max_buckled_mobs = 1
	buckle_lying = FALSE
	buckle_requires_restraints = FALSE

	var/grapple_time = 10 SECONDS
	var/mob/living/caster

/obj/effect/shadow_bind_anchor/attack_hand(mob/user)
	return TRUE

/obj/effect/shadow_bind_anchor/attackby(obj/item/I, mob/user, params)
	return TRUE

/obj/effect/shadow_bind_anchor/attackby_secondary(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	return

/obj/effect/shadow_bind_anchor/attack_hand_secondary(mob/user, list/modifiers)
	return

/obj/effect/shadow_bind_anchor/Initialize(mapload, mob/living/caster_ref)
	. = ..()
	caster = caster_ref
	START_PROCESSING(SSobj, src)
	addtimer(CALLBACK(src, PROC_REF(_gc_if_empty)), 2 SECONDS)

/obj/effect/shadow_bind_anchor/Destroy()
	STOP_PROCESSING(SSobj, src)
	for(var/mob/living/L in buckled_mobs)
		unbuckle_mob(L, force = TRUE)
	return ..()

/obj/effect/shadow_bind_anchor/process(seconds_per_tick)
	if(!isturf(loc))
		qdel(src)
		return

	if(!has_buckled_mobs())
		qdel(src)
		return

	var/turf/T = get_turf(src)
	if(T.get_lumcount() >= SHADOWLING_DIM_THRESHOLD)
		visible_message(
			span_warning("Bright light dissolves the shadows!"),
			span_userdanger("The light shatters your bindings!")
		)
		release()

/obj/effect/shadow_bind_anchor/proc/apply_to(mob/living/victim)
	if(!istype(victim) || QDELETED(victim) || victim.stat == DEAD)
		qdel(src)
		return FALSE

	if(has_buckled_mobs())
		return FALSE

	if(!buckle_mob(victim, force = TRUE))
		qdel(src)
		return FALSE

	if(isturf(loc))
		visible_message(
			span_danger("Shadows surge around [victim]!"),
			span_userdanger("Shadowy roots ensnare your feet — you cannot move!")
		)

	playsound(victim, 'sound/effects/magic/enter_blood.ogg', 75, TRUE)
	addtimer(CALLBACK(src, PROC_REF(release)), grapple_time, TIMER_STOPPABLE)
	return TRUE

/obj/effect/shadow_bind_anchor/proc/release()
	if(QDELETED(src))
		return
	if(!has_buckled_mobs())
		qdel(src)
		return
	for(var/mob/living/L in buckled_mobs)
		unbuckle_mob(L, force = TRUE)
	QDEL_IN(src, 0.4 SECONDS)

/obj/effect/shadow_bind_anchor/proc/_gc_if_empty()
	if(!has_buckled_mobs())
		qdel(src)

// MARK: Ability
/datum/action/cooldown/shadowling/root
	name = "Shadow Roots"
	desc = "Entangle a target in living shadow roots for 10 seconds. Only works if the target is standing in darkness."
	button_icon_state = "shadow_grasp"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 25 SECONDS
	click_to_activate = TRUE
	unset_after_click = TRUE
	var/targeting = FALSE

/datum/action/cooldown/shadowling/root/is_action_active(atom/movable/screen/movable/action_button/_btn)
	return targeting

/datum/action/cooldown/shadowling/root/unset_click_ability(mob/on_who, refund_cooldown)
	. = ..()
	targeting = FALSE
	apply_button_overlay()

/datum/action/cooldown/shadowling/root/set_click_ability(mob/on_who, refund_cooldown)
	. = ..()
	targeting = TRUE
	apply_button_overlay()

/datum/action/cooldown/shadowling/root/Activate(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE

	var/mob/living/carbon/human/T = target
	if(!istype(T))
		owner.balloon_alert(owner, "invalid target")
		return FALSE
	if(T == H)
		owner.balloon_alert(owner, "cannot target yourself")
		return FALSE

	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(hive)
		if(T in hive.lings)
			owner.balloon_alert(owner, "allies cannot be targeted")
			return FALSE
		if(T in hive.thralls)
			owner.balloon_alert(owner, "allies cannot be targeted")
			return FALSE

	var/turf/tturf = get_turf(T)
	if(!tturf || tturf.get_lumcount() >= SHADOWLING_DIM_THRESHOLD)
		owner.balloon_alert(owner, "target not in darkness")
		return FALSE

	var/obj/effect/shadow_bind_anchor/A = new /obj/effect/shadow_bind_anchor(tturf, H)
	if(!A.apply_to(T))
		qdel(A)
		owner.balloon_alert(owner, "failed to ensnare")
		return FALSE

	StartCooldown()
	return TRUE
