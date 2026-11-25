// MARK: Hook Projectile

/// Shadow hand projectile fired by Shadow Roots secondary mode to pull hit mobs or items toward the caster.
/obj/projectile/magic/shadow_hand_sl
	name = "shadow hand"
	icon = 'icons/mob/antagonists/shadowling/shadowling_objects.dmi'
	icon_state = "shadow_hand"
	pass_flags = PASSTABLE
	damage = 0
	damage_type = BRUTE
	range = 8
	speed = 0.8

	/// Prevents duplicate throw/on_hit processing for a single projectile.
	var/hit_committed = FALSE
	/// Visual chain beam linking the firer to the flying shadow hand.
	var/datum/beam/chain

/// Fires the shadow hand projectile and attaches the visual chain beam to the firer.
/obj/projectile/magic/shadow_hand_sl/fire(setAngle)
	if(firer)
		chain = firer.Beam(
			BeamTarget = src,
			icon = 'icons/mob/antagonists/shadowling/shadowling_objects.dmi',
			icon_state = "shadow_grabber",
			time = INFINITY,
			maxdistance = INFINITY,
			emissive = FALSE
		)
	return ..()

/// Scans entered turfs for eligible living mobs or unanchored items to pull.
/obj/projectile/magic/shadow_hand_sl/Moved(atom/oldloc, dir, forced = FALSE, list/old_locs, momentum_change = FALSE)
	. = ..()
	if(hit_committed)
		return .

	var/turf/cur_turf = get_turf(src)
	if(!istype(cur_turf))
		return .

	var/atom/movable/candidate = null

	for(var/mob/living/L in cur_turf)
		if(_eligible_mob(L))
			candidate = L
			break

	if(!candidate)
		for(var/obj/item/I in cur_turf)
			if(_eligible_item(I))
				candidate = I
				break

	if(candidate)
		Bump(candidate)

	return .

/// Returns TRUE if [L] is alive, unanchored, not throwing, and not the firer.
/obj/projectile/magic/shadow_hand_sl/proc/_eligible_mob(mob/living/L)
	if(!istype(L))
		return FALSE
	if(L == firer)
		return FALSE
	if(L.stat == DEAD)
		return FALSE
	if(L.anchored)
		return FALSE
	if(L.throwing)
		return FALSE
	return TRUE

/// Returns TRUE if [I] is an unanchored item resting directly on a turf.
/obj/projectile/magic/shadow_hand_sl/proc/_eligible_item(obj/item/I)
	if(!istype(I))
		return FALSE
	if(I.anchored)
		return FALSE
	if(!isturf(I.loc))
		return FALSE
	return TRUE

/// Pulls the struck movable target back toward [firer] upon impact.
/obj/projectile/magic/shadow_hand_sl/on_hit(atom/movable/target, blocked = 0, pierce_hit)
	. = ..()
	if(hit_committed)
		return BULLET_ACT_BLOCK

	hit_committed = TRUE

	if(!isliving(firer))
		return BULLET_ACT_HIT

	var/mob/living/caster = firer

	var/turf/caster_turf = get_turf(caster)
	var/turf/hit_turf = get_turf(target)

	if(!istype(caster_turf))
		return BULLET_ACT_HIT

	if(!istype(hit_turf))
		return BULLET_ACT_HIT

	if(!ismovable(target))
		return BULLET_ACT_HIT

	var/atom/movable/mov = target

	if(mov.anchored)
		return BULLET_ACT_HIT

	if(isliving(mov))
		var/mob/living/victim = mov
		if(victim.throwing)
			return BULLET_ACT_HIT

	var/turf/dest_turf = get_step(caster, get_dir(caster, mov))
	if(!istype(dest_turf))
		dest_turf = caster_turf

	mov.throw_at(
		target = dest_turf,
		range = 8,
		speed = 2,
		thrower = caster,
		diagonals_first = TRUE,
		gentle = TRUE
	)

	playsound(caster_turf, hitsound, 70, TRUE)

	return BULLET_ACT_HIT

/obj/projectile/magic/shadow_hand_sl/Destroy()
	if(!hit_committed && istype(firer))
		var/mob/living/L = firer
		L.balloon_alert(L, "missed!")

	if(chain && !QDELETED(chain))
		qdel(chain)
	chain = null
	return ..()
