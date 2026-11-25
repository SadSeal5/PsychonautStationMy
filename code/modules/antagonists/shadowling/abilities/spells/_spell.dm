// MARK: Base Ability

/// Base cooldown action for all Shadowling and Shadow Thrall abilities.
/datum/action/cooldown/shadowling
	name = "Shadowling Ability"
	desc = "Innate power of the brood."
	button_icon = 'icons/mob/antagonists/shadowling/shadowling_actions.dmi'
	button_icon_state = ""
	background_icon = 'icons/mob/antagonists/shadowling/shadowling_actions.dmi'
	background_icon_state = "bg_shadowling"
	overlay_icon = 'icons/mob/antagonists/shadowling/shadowling_actions.dmi'
	overlay_icon_state = "bg_shadowling_border"
	active_overlay_icon_state = "bg_shadowling_border_active"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED | AB_CHECK_OPEN_TURF
	cooldown_time = 10 SECONDS
	/// Bitflags (`SL_INNATE`, `SL_THRESHOLD`, `SL_ASCENDED`, `SL_THRALL`, `SL_LESSER`) controlling unlock eligibility and UI category.
	var/role_flags = NONE
	/// Whether this toggle/click-intercept ability is currently active.
	var/active = FALSE
	/// Percentage of hive ascension thralls needed to unlock (`SL_THRESHOLD` abilities).
	var/required_thralls = 0
	/// Whether the caster must stand in darkness (`get_lumcount() < SHADOWLING_DIM_THRESHOLD`).
	var/requires_dark_user = FALSE
	/// Whether targets must stand in darkness.
	var/requires_dark_target = FALSE
	/// Maximum cast or target acquisition range in tiles (0 for self/unbounded).
	var/max_range = 0
	/// Channel duration before [do_effect()] fires (deciseconds).
	var/channel_time = 0
	/// Whether channeling aborts if the caster enters bright light.
	var/cancel_on_bright = TRUE
	/// Minimum clamped thrall requirement for threshold scaling.
	var/min_req = 0
	/// Maximum clamped thrall requirement for threshold scaling.
	var/max_req = 100

/datum/action/cooldown/shadowling/Remove(mob/remove_from)
	if(active && ishuman(remove_from))
		deactivate_power(remove_from)
	return ..()

/datum/action/cooldown/shadowling/Destroy()
	if(active && ishuman(owner))
		deactivate_power(owner)
	return ..()

/datum/action/cooldown/shadowling/set_click_ability(mob/on_who)
	. = ..()
	active = TRUE
	apply_button_overlay()

/datum/action/cooldown/shadowling/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	active = FALSE
	apply_button_overlay()

/// Marks the ability active and refreshes its HUD button overlay.
/datum/action/cooldown/shadowling/proc/activate_power(mob/living/carbon/human/H)
	active = TRUE
	if(!QDELETED(src) && owner)
		apply_button_overlay()
	return TRUE

/// Marks the ability inactive and refreshes its HUD button overlay.
/datum/action/cooldown/shadowling/proc/deactivate_power(mob/living/carbon/human/H)
	active = FALSE
	if(!QDELETED(src) && owner)
		apply_button_overlay()
	return TRUE

/// Safely removes and deletes one-shot abilities (such as Hatch or Ascension) after completion.
/datum/action/cooldown/shadowling/proc/remove_after_use()
	if(owner)
		Remove(owner)
	if(!QDELETED(src))
		qdel(src)

/// Blocks non-phase, non-strike abilities while the owner is phased inside a shadow dummy.
/datum/action/cooldown/shadowling/IsAvailable(feedback = FALSE)
	if(istype(owner?.loc, /obj/effect/dummy/phased_mob/shadowling))
		if(!istype(src, /datum/action/cooldown/shadowling/shadow_phase) && \
		   !istype(src, /datum/action/cooldown/shadowling/shadow_strike))
			if(feedback)
				owner.balloon_alert(owner, "ability unavailable while phased")
			return FALSE

	return ..()

/// Validates hive connection, membership, hatched status, lighting requirements, and availability for [H].
/datum/action/cooldown/shadowling/proc/can_use(mob/living/carbon/human/H)
	var/datum/team/shadow_hive/hive = get_hive()
	if(!hive || QDELETED(hive))
		owner.balloon_alert(owner, "hive connection severed")
		return FALSE
	if(!(H in hive.lings) && !(H in hive.thralls))
		owner.balloon_alert(owner, "not a member of the hive")
		return FALSE
	if(!istype(src, /datum/action/cooldown/shadowling/hatch) && !istype(src, /datum/action/cooldown/shadowling/commune))
		if(H in hive.lings)
			if(!isshadowling(H) && !isshadowling_ascended(H) && hive.get_ling_role(H) != SHADOWLING_ROLE_LESSER)
				owner.balloon_alert(owner, "must hatch first")
				return FALSE
	if(requires_dark_user && !is_dark(H))
		owner.balloon_alert(owner, "too bright")
		return FALSE
	if(!IsAvailable(TRUE))
		owner.balloon_alert(owner, "ability unavailable")
		return FALSE
	return TRUE

/// Returns a valid Shadow Hive team datum, resolving via owner's antagonist datum or recreating the global singleton.
/datum/action/cooldown/shadowling/proc/get_hive()
	var/datum/antagonist/shadowling/antag = get_shadowling_antag_of(owner, include_subtypes = TRUE)
	if(antag)
		return antag.get_hive()
	if(QDELETED(GLOB.shadowling_hive))
		GLOB.shadowling_hive = new /datum/team/shadow_hive
	return GLOB.shadowling_hive

/// Returns TRUE if [M] is registered as a Shadowling or Thrall in the hive.
/datum/action/cooldown/shadowling/proc/is_hive_ally(mob/living/M)
	if(!istype(M))
		return FALSE
	var/datum/team/shadow_hive/hive = get_hive()
	if(!hive)
		return FALSE
	return (M in hive.lings) || (M in hive.thralls)

/// Verifies that this ability and [H] remain valid, living, owning Shadowlings mid-ritual.
/datum/action/cooldown/shadowling/proc/is_valid_caster(mob/living/carbon/human/H)
	return !QDELETED(src) && !QDELETED(H) && owner == H && H.stat != DEAD && !!H.mind?.has_antag_datum(/datum/antagonist/shadowling, FALSE)

/// Refreshes button status overlays for all Shadowling actions owned by [H].
/datum/action/cooldown/shadowling/proc/refresh_owner_actions(mob/living/carbon/human/H = owner)
	if(!istype(H))
		return
	for(var/datum/action/cooldown/shadowling/A in H.actions)
		A.build_all_button_icons(UPDATE_BUTTON_STATUS, TRUE)

/// Applies [modifier_path] slow to [L] and schedules automatic removal bound to [L]'s lifetime.
/datum/action/cooldown/shadowling/proc/apply_timed_slow(mob/living/L, modifier_path, duration)
	if(!istype(L) || !modifier_path)
		return
	L.add_movespeed_modifier(modifier_path)
	addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, remove_movespeed_modifier), modifier_path), duration, TIMER_UNIQUE | TIMER_OVERRIDE)

/// Returns turfs within [range_tiles] lying inside [fov_deg] degrees in front of [H].
/datum/action/cooldown/shadowling/proc/collect_cone_turfs(mob/living/carbon/human/H, range_tiles, fov_deg)
	var/list/turfs_in_cone = list()
	if(!istype(H))
		return turfs_in_cone
	var/turf/origin = get_turf(H)
	if(!origin)
		return turfs_in_cone
	for(var/turf/T in range(range_tiles, origin))
		if(!in_front_cone(H, T, fov_deg))
			continue
		turfs_in_cone += T
	return turfs_in_cone

/// Per-target validation hook overridden by subclasses.
/datum/action/cooldown/shadowling/proc/validate_target(mob/living/carbon/human/H, atom/target)
	return TRUE

/// Executes the timed `do_after` channel for [H], checking darkness and availability before and after.
/datum/action/cooldown/shadowling/proc/perform_channel(mob/living/carbon/human/H, atom/target)
	if(cancel_on_bright && !is_dark(H))
		return FALSE
	if(!do_after(H, channel_time, target))
		return FALSE
	if(cancel_on_bright && !is_dark(H))
		return FALSE
	if(!IsAvailable(TRUE))
		return FALSE
	return TRUE

/// Returns TRUE when [A]'s turf lumcount is below `SHADOWLING_DIM_THRESHOLD`.
/datum/action/cooldown/shadowling/proc/is_dark(atom/A)
	var/turf/T = get_turf(A)
	if(!T)
		return FALSE
	return (T.get_lumcount() < SHADOWLING_DIM_THRESHOLD)

/// Effect hook implemented by each Shadowling ability.
/datum/action/cooldown/shadowling/proc/do_effect(mob/living/carbon/human/H, atom/target)
	return FALSE

/// Standard activation pipeline: validates usage, collects/validates targets, channels, applies effect, and starts cooldown.
/datum/action/cooldown/shadowling/Activate(atom/target)
	if(!istype(owner))
		return FALSE
	if(!can_use(owner))
		return FALSE
	var/atom/explicit = (target == owner) ? null : target
	var/list/targets = collect_targets(owner, explicit)
	if(!validate_targets(owner, targets))
		owner.balloon_alert(owner, "no valid targets")
		return FALSE
	if(channel_time > 0)
		if(!perform_channel(owner, null))
			return FALSE
	var/success = do_effect_on_targets(owner, targets)
	if(QDELETED(src))
		return TRUE
	if(success)
		StartCooldown()
		return TRUE
	return FALSE

/// Returns the list of candidate targets for [H], defaulting to [explicit] or [H] itself.
/datum/action/cooldown/shadowling/proc/collect_targets(mob/living/carbon/human/H, atom/explicit)
	if(explicit)
		return list(explicit)
	return list(H)

/// Checks range, target darkness, and [validate_target()] for every target in [targets].
/datum/action/cooldown/shadowling/proc/validate_targets(mob/living/carbon/human/H, list/targets)
	if(!islist(targets) || !length(targets))
		return TRUE
	for(var/atom/T in targets)
		if(max_range > 0)
			if(get_dist(H, T) > max_range)
				return FALSE
		if(requires_dark_target && !is_dark(T))
			return FALSE
		if(!validate_target(H, T))
			return FALSE
	return TRUE

/// Invokes [do_effect()] across [targets] and returns TRUE if at least one succeeded.
/datum/action/cooldown/shadowling/proc/do_effect_on_targets(mob/living/carbon/human/H, list/targets)
	if(!islist(targets) || !length(targets))
		return do_effect(H, null)
	var/success = FALSE
	for(var/atom/A in targets)
		if(do_effect(H, A))
			success = TRUE
	return success

/// Returns the smallest angular difference in degrees between angles [a] and [b].
/datum/action/cooldown/shadowling/proc/glare_angle_diff(a, b)
	var/d = abs(a - b) % 360
	if(d > 180)
		d = 360 - d
	return d

/// Returns TRUE if [A] lies within a cone of [full_angle] degrees in front of [H].
/datum/action/cooldown/shadowling/proc/in_front_cone(mob/living/carbon/human/H, atom/A, full_angle = 90)
	if(!istype(H) || !A)
		return FALSE
	var/turf/from_turf = get_turf(H)
	var/turf/to_turf = get_turf(A)
	if(!from_turf || !to_turf)
		return FALSE
	if(!H.dir)
		return TRUE
	var/ang_forward = dir2angle(H.dir)
	var/ang_to = get_angle(from_turf, to_turf)
	var/half = full_angle * 0.5
	if(glare_angle_diff(ang_forward, ang_to) <= half)
		return TRUE
	return FALSE

/// Returns the `/datum/antagonist/shadowling` datum attached to [H]'s mind, if any.
/datum/action/cooldown/shadowling/proc/get_shadowling_antag_of(mob/living/carbon/human/H, include_subtypes = FALSE)
	if(!istype(H))
		return null
	return H.mind?.has_antag_datum(/datum/antagonist/shadowling, include_subtypes)

/// Starts the action cooldown, halved when the owner has ascended.
/datum/action/cooldown/shadowling/StartCooldown(time_override)
	var/duration = time_override || cooldown_time
	var/datum/antagonist/shadowling/A = get_shadowling_antag_of(owner)
	var/mult = A?.is_ascended ? SHADOWLING_ASCENDED_CD_MULT : 1
	var/calculated_cd = duration * mult
	..(override_cooldown_time = calculated_cd)

/datum/action/cooldown/shadowling/apply_button_overlay(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	if(!current_button)
		build_all_button_icons(UPDATE_BUTTON_OVERLAY, TRUE)
		return

	SEND_SIGNAL(src, COMSIG_ACTION_OVERLAY_APPLY, current_button, force)

	if(!overlay_icon || !overlay_icon_state)
		return

	var/use_state = overlay_icon_state
	if(active_overlay_icon_state && is_action_active(current_button))
		use_state = active_overlay_icon_state

	if(current_button.active_overlay_icon_state == use_state && !force)
		return

	current_button.cut_overlay(current_button.button_overlay)
	current_button.button_overlay = mutable_appearance(icon = overlay_icon, icon_state = use_state)
	current_button.add_overlay(current_button.button_overlay)
	current_button.active_overlay_icon_state = use_state

/datum/action/cooldown/shadowling/is_action_active(atom/movable/screen/movable/action_button/_btn)
	return active
