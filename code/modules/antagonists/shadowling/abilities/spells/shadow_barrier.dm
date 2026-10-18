/datum/action/cooldown/shadowling/shadow_barrier
	name = "Shadow Barrier"
	desc = "Raise an umbral barrier that reflects frontal energy projectiles."
	button_icon_state = "shadow_barrier"
	cooldown_time = 40 SECONDS
	requires_dark_user = FALSE
	requires_dark_target = FALSE
	max_range = 0
	channel_time = 0
	min_req = 1
	max_req = 20
	required_thralls = 30
	var/barrier_duration = 5 SECONDS
	var/barrier_active = FALSE
	var/static/sfx_activate = 'sound/effects/magic/teleport_app.ogg'
	var/list/allowed_projectile_typecache

/datum/action/cooldown/shadowling/shadow_barrier/Destroy()
	if(barrier_active && istype(owner, /mob/living/carbon/human))
		end_barrier(WEAKREF(owner))
	return ..()

/datum/action/cooldown/shadowling/shadow_barrier/Trigger(mob/clicker, trigger_flags, atom/target)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !can_use(H))
		return FALSE
	if(channel_time > 0 && !PerformChannel(H, null))
		return FALSE
	if(!allowed_projectile_typecache)
		allowed_projectile_typecache = typecacheof(list(/obj/projectile/beam))

	if(barrier_active)
		end_barrier(WEAKREF(H))

	barrier_active = TRUE
	RegisterSignal(H, COMSIG_ATOM_PRE_BULLET_ACT, PROC_REF(on_barrier_bullet_act))
	RegisterSignal(H, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_dir_change))
	RegisterSignal(H, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_update_overlays))
	H.update_appearance(UPDATE_OVERLAYS)

	playsound(H, sfx_activate, 65, TRUE)
	addtimer(CALLBACK(src, PROC_REF(end_barrier), WEAKREF(H)), barrier_duration)
	StartCooldown()
	return TRUE

/datum/action/cooldown/shadowling/shadow_barrier/proc/on_update_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/H = source
	if(!H || QDELETED(H) || !barrier_active)
		return

	var/mutable_appearance/barrier = mutable_appearance('icons/mob/antagonists/shadowling/shadowling_objects.dmi', "shadow_barrier")
	barrier.dir = H.dir
	barrier.layer = ABOVE_MOB_LAYER

	switch(H.dir)
		if(NORTH)
			barrier.pixel_y = 7
		if(SOUTH)
			barrier.pixel_y = -7
		if(EAST)
			barrier.pixel_x = 7
		if(WEST)
			barrier.pixel_x = -7

	overlays += barrier

/datum/action/cooldown/shadowling/shadow_barrier/proc/on_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/H = source
	if(H && barrier_active)
		H.update_appearance(UPDATE_OVERLAYS)

/datum/action/cooldown/shadowling/shadow_barrier/proc/end_barrier(datum/weakref/owner_ref)
	var/mob/living/carbon/human/H = owner_ref?.resolve()
	barrier_active = FALSE
	if(H)
		UnregisterSignal(H, list(COMSIG_ATOM_PRE_BULLET_ACT, COMSIG_ATOM_DIR_CHANGE, COMSIG_ATOM_UPDATE_OVERLAYS))
		H.update_appearance(UPDATE_OVERLAYS)

/datum/action/cooldown/shadowling/shadow_barrier/proc/on_barrier_bullet_act(atom/source, obj/projectile/proj)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = source
	if(!H || QDELETED(H) || !proj || QDELETED(proj) || !barrier_active)
		return
	if(!allowed_projectile_typecache[proj.type])
		return
	if(proj.dir != REVERSE_DIR(H.dir))
		return
	proj.reflect(H)
	return COMPONENT_BULLET_PIERCED
