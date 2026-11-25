// MARK: Status Effects

/// Low-alpha stealth status effect granted to Shadow Thralls; breaks on light, movement, damage, clicking, or speech.
/datum/status_effect/shadow/stealth
	id = "shadowling_stealth"
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE
	tick_interval = 1 SECONDS
	duration = -1
	/// Alpha captured prior to entering stealth so non-default alpha is restored on exit.
	var/prev_alpha = 255
	/// When TRUE, entering non-darkness automatically breaks stealth.
	var/cancel_on_bright = TRUE

/// Reduces owner alpha to 80 and registers movement, damage, click, and speech break signals.
/datum/status_effect/shadow/stealth/on_apply()
	. = ..()
	if(!owner)
		return

	for(var/datum/action/cooldown/shadowling/stealth/A in owner.actions)
		A.active = TRUE
		A.apply_button_overlay()

	prev_alpha = owner.alpha
	owner.alpha = 80
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(_break_on_move))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(_break_on_damage))
	RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(_break_on_action))
	RegisterSignal(owner, COMSIG_MOB_SAY, PROC_REF(_break_on_action))

/// Restores owner alpha/invisibility and unregisters stealth break signals.
/datum/status_effect/shadow/stealth/on_remove()
	. = ..()
	if(!owner)
		return

	for(var/datum/action/cooldown/shadowling/stealth/A in owner.actions)
		A.active = FALSE
		A.apply_button_overlay()

	owner.alpha = prev_alpha
	owner.invisibility = initial(owner.invisibility)
	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOB_APPLY_DAMAGE,
		COMSIG_MOB_CLICKON,
		COMSIG_MOB_SAY,
	))

/datum/status_effect/shadow/stealth/tick(seconds_between_ticks)
	. = ..()
	if(!owner)
		return
	if(cancel_on_bright)
		var/turf/T = get_turf(owner)
		if(!T)
			return
		if(T.get_lumcount() >= SHADOWLING_DIM_THRESHOLD)
			owner.remove_status_effect(type)

/// Signal handler removing stealth when the thrall moves.
/datum/status_effect/shadow/stealth/proc/_break_on_move(datum/source)
	SIGNAL_HANDLER
	owner.remove_status_effect(type)

/// Signal handler removing stealth when the thrall takes positive damage.
/datum/status_effect/shadow/stealth/proc/_break_on_damage(datum/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		owner.remove_status_effect(type)

/// Signal handler removing stealth when the thrall clicks or speaks.
/datum/status_effect/shadow/stealth/proc/_break_on_action(datum/source)
	SIGNAL_HANDLER
	owner.remove_status_effect(type)

// MARK: Ability

/// Thrall ability granting darkness-bound invisibility until broken by light or action.
/datum/action/cooldown/shadowling/stealth
	name = "Shadow Stealth"
	desc = "Blend into the darkness. Breaks on movement, taking damage, or performing actions."
	button_icon_state = "shadow_stealth"
	cooldown_time = 6 SECONDS
	role_flags = SL_THRALL

/datum/action/cooldown/shadowling/stealth/activate_power(mob/living/carbon/human/H)
	if(!istype(H))
		return FALSE
	H.apply_status_effect(/datum/status_effect/shadow/stealth)
	return ..()

/datum/action/cooldown/shadowling/stealth/deactivate_power(mob/living/carbon/human/H)
	if(istype(H))
		H.remove_status_effect(/datum/status_effect/shadow/stealth)
	return ..()

/datum/action/cooldown/shadowling/stealth/do_effect(mob/living/carbon/human/H, atom/_)
	if(H.has_status_effect(/datum/status_effect/shadow/stealth))
		deactivate_power(H)
		to_chat(H, span_notice("You step out of the shadows."))
		return TRUE

	if(is_dark(H))
		activate_power(H)
		to_chat(H, span_notice("You blend into the shadows."))
		return TRUE

	H.balloon_alert(H, "too bright")
	return FALSE
