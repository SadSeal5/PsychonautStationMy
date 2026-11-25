// MARK: Ability

/// Threshold-30% defensive ability surrounding the caster in a temporary beam-reflecting shroud.
/datum/action/cooldown/shadowling/shadow_barrier
	name = "Shadow Barrier"
	desc = "Surround yourself in a pulsing umbral shroud that reflects energy projectiles."
	button_icon_state = "shadow_barrier"
	cooldown_time = 40 SECONDS
	role_flags = SL_THRESHOLD | SL_ASCENDED
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	max_range = 0
	channel_time = 0
	min_req = 1
	max_req = 20
	required_thralls = 30
	/// Active duration of the beam-reflection barrier.
	var/barrier_duration = 5 SECONDS
	var/static/sfx_activate = 'sound/effects/magic/teleport_app.ogg'
	/// Cached typecache of projectile paths reflected by the barrier (`/obj/projectile/beam`).
	var/list/allowed_projectile_typecache

/// Activates the reflective shroud and schedules automatic dissipation after `barrier_duration`.
/datum/action/cooldown/shadowling/shadow_barrier/Activate(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !can_use(H))
		return FALSE
	if(channel_time > 0 && !perform_channel(H, null))
		return FALSE
	if(!allowed_projectile_typecache)
		allowed_projectile_typecache = typecacheof(list(/obj/projectile/beam))

	if(active)
		deactivate_power(H)

	activate_power(H)
	addtimer(CALLBACK(src, PROC_REF(end_barrier), WEAKREF(H)), barrier_duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	StartCooldown()
	return TRUE

/// Registers `COMSIG_ATOM_PRE_BULLET_ACT` and adds the pulsing purple outline filter.
/datum/action/cooldown/shadowling/shadow_barrier/activate_power(mob/living/carbon/human/H)
	if(!istype(H))
		return FALSE
	RegisterSignal(H, COMSIG_ATOM_PRE_BULLET_ACT, PROC_REF(on_barrier_bullet_act))
	H.add_filter("shadow_barrier_aura", 2, outline_filter("color" = LIGHT_COLOR_PURPLE, "size" = 1.5))
	var/the_filter = H.get_filter("shadow_barrier_aura")
	if(the_filter)
		animate(the_filter, alpha = 0)
		animate(the_filter, alpha = 200, time = 1 SECONDS, loop = -1, easing = SINE_EASING)
		animate(alpha = 60, time = 1 SECONDS, loop = -1, easing = SINE_EASING)

	playsound(H, sfx_activate, 65, TRUE)
	to_chat(H, span_notice("You manifest a protective umbral shroud around yourself!"))
	return ..()

/// Unregisters the bullet-act reflection handler and strips the outline filter.
/datum/action/cooldown/shadowling/shadow_barrier/deactivate_power(mob/living/carbon/human/H)
	if(istype(H))
		UnregisterSignal(H, COMSIG_ATOM_PRE_BULLET_ACT)
		H.remove_filter("shadow_barrier_aura")
		to_chat(H, span_warning("Your umbral shroud dissipates."))
	return ..()

/datum/action/cooldown/shadowling/shadow_barrier/proc/end_barrier(datum/weakref/owner_ref)
	if(!active)
		return
	var/mob/living/carbon/human/H = owner_ref?.resolve()
	deactivate_power(H)

/// Signal handler reflecting beam projectiles hitting the shielded Shadowling.
/datum/action/cooldown/shadowling/shadow_barrier/proc/on_barrier_bullet_act(atom/source, obj/projectile/proj)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = source
	if(!H || QDELETED(H) || !proj || QDELETED(proj) || !active)
		return
	if(!allowed_projectile_typecache[proj.type])
		return
	proj.reflect(H)
	return COMPONENT_BULLET_BLOCKED
