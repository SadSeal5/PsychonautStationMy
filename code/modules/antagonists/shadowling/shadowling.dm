// MARK: Antagonist

/// Core antagonist datum for Shadowlings, managing hive membership, form lifecycle, and admin tools.
/datum/antagonist/shadowling
	name = "Shadowling"
	roundend_category = "Shadowlings"
	antagpanel_category = "Shadowling"
	pref_flag = ROLE_SHADOWLING
	stinger_sound = 'sound/antagonists/shadowlings/shadowling_gain.ogg'
	antag_moodlet = /datum/mood_event/shadowling
	hud_icon = 'icons/mob/huds/antag_hud.dmi'
	antag_hud_name = "shadowling"
	ui_name = "AntagInfoShadowling"

	/// Role identifier within the hive (`SHADOWLING_ROLE_MAIN`, `SHADOWLING_ROLE_LESSER`, or `SHADOWLING_ROLE_THRALL`).
	var/ling_role = SHADOWLING_ROLE_MAIN
	/// Whether this antagonist datum represents a Shadow Thrall rather than a Shadowling.
	var/is_thrall = FALSE
	/// Whether this Shadowling has achieved Ascension.
	var/is_ascended = FALSE

	/// Reference to the shared Shadow Hive team datum.
	var/datum/team/shadow_hive/shadow_team
	/// The species the mob had before hatching, restored on removal.
	var/datum/species/original_species
	/// The max health the mob had before ascending, restored on removal or de-ascension.
	var/original_max_health
	/// Rate-limits manual Broodmind sync actions.
	COOLDOWN_DECLARE(sync_cooldown)

/datum/antagonist/shadowling/can_be_owned(datum/mind/new_owner)
	if(new_owner?.has_antag_datum(type))
		return FALSE
	return ..()

/// Returns a valid Shadow Hive team datum, clearing stale deleted references and recreating the singleton if needed.
/datum/antagonist/shadowling/proc/get_hive()
	if(QDELETED(shadow_team))
		shadow_team = null
	if(QDELETED(GLOB.shadowling_hive))
		GLOB.shadowling_hive = new /datum/team/shadow_hive
	if(!shadow_team)
		shadow_team = GLOB.shadowling_hive
	return shadow_team

/// Generates the roundstart preference preview icon using the Shadowling species.
/datum/antagonist/shadowling/get_preview_icon()
	var/mob/living/carbon/human/dummy/consistent/dummy = new()
	dummy.set_species(/datum/species/shadow/shadowling, icon_update = TRUE)
	return finish_preview_icon(render_preview_outfit(preview_outfit, dummy))

/// Assigns [new_team] or binds to the global `GLOB.shadowling_hive` singleton.
/datum/antagonist/shadowling/create_team(datum/team/shadow_hive/new_team)
	if(istype(new_team) && !QDELETED(new_team))
		shadow_team = new_team
		return
	shadow_team = null
	get_hive()

/// Registers the mind and body in the hive, grants initial abilities, and assigns objectives.
/datum/antagonist/shadowling/on_gain()
	if(!owner)
		return

	var/datum/team/shadow_hive/hive = get_hive()
	hive.setup_objectives()
	hive.add_member(owner)

	var/mob/living/carbon/human/H = owner.current
	if(istype(H))
		hive.join_member(H, ling_role)
		if(!is_thrall)
			hive.shadowling_grant_hatch(H)

	if(is_thrall)
		var/list/thrall_objs = list(
			new /datum/objective/shadow_thrall/survive,
			new /datum/objective/shadow_thrall/assist_ascension,
			new /datum/objective/shadow_thrall/save_shadowlings,
		)
		for(var/datum/objective/O in thrall_objs)
			O.owner = owner
		objectives |= thrall_objs
	else
		objectives |= hive.get_objectives()

	. = ..()

	if(istype(H))
		add_team_hud(H)
		hive.sync_after_event(H)

/// Sends the Shadowling role greeting, plays the stinger, and announces objectives.
/datum/antagonist/shadowling/greet()
	if(silent || !owner?.current)
		return
	play_stinger()
	if(ling_role == SHADOWLING_ROLE_LESSER)
		to_chat(owner.current, span_bolddanger("The darkness rewrites your flesh and mind. You are a Lesser Shadowling!"))
	else
		to_chat(owner.current, span_bolddanger("You are a Shadowling! Stay in the darkness, enthrall the crew, and ascend."))
	owner.announce_objectives()
	antag_memory += "You are a <b>[(ling_role == SHADOWLING_ROLE_LESSER) ? "Lesser Shadowling" : "Shadowling"]</b> of the Shadow Hive.<br>"

/// Notifies the mind when the Shadowling antagonist datum is removed.
/datum/antagonist/shadowling/farewell()
	if(silent || !owner?.current)
		return
	to_chat(owner.current, span_userdanger("The shadow recedes from your mind. You are no longer a Shadowling!"))

/// Returns the current form, role, and hive thrall progress string for the admin antag panel.
/datum/antagonist/shadowling/antag_panel_data()
	var/mob/living/carbon/human/H = owner?.current
	var/form = "Unhatched"
	if(is_ascended || (istype(H) && isshadowling_ascended(H)))
		form = "Ascended"
	else if(istype(H) && isshadowling(H))
		form = "Hatched"

	var/role_label = (ling_role == SHADOWLING_ROLE_LESSER) ? "Lesser" : "Master"
	var/datum/team/shadow_hive/hive = get_hive()
	var/alive_thralls = hive ? hive.count_alive_thralls() : 0
	var/needed_thralls = hive ? hive.get_ascension_thralls_needed() : 0
	return "Form: [form] | Role: [role_label] | Hive Thralls: [alive_thralls]/[needed_thralls]"

/// Returns contextual admin panel commands for managing Shadowling state and hive thralls.
/datum/antagonist/shadowling/get_admin_commands()
	. = ..()
	var/mob/living/carbon/human/H = owner?.current
	if(!is_thrall)
		if(istype(H) && !isshadowling(H) && !isshadowling_ascended(H))
			.["Force Hatch"] = CALLBACK(src, PROC_REF(admin_force_hatch))
		if(istype(H) && !is_ascended)
			.["Force Ascend"] = CALLBACK(src, PROC_REF(admin_force_ascend))
		.["Sync Hive Abilities"] = CALLBACK(src, PROC_REF(admin_sync_hive))
		if(ling_role != SHADOWLING_ROLE_LESSER && !is_ascended)
			.["Convert to Lesser Shadowling"] = CALLBACK(src, PROC_REF(admin_convert_lesser))
		.["Add Thrall (Marked Mob)"] = CALLBACK(src, PROC_REF(admin_add_thrall))
		.["Remove Thrall"] = CALLBACK(src, PROC_REF(admin_remove_thrall))
	else
		.["Sync Hive Abilities"] = CALLBACK(src, PROC_REF(admin_sync_hive))
		.["Convert to Lesser Shadowling"] = CALLBACK(src, PROC_REF(admin_convert_lesser))

/// Admin command to immediately hatch an unhatched Shadowling.
/datum/antagonist/shadowling/proc/admin_force_hatch(mob/admin)
	if(!admin?.client?.holder)
		return
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H) || is_thrall || isshadowling(H) || isshadowling_ascended(H))
		to_chat(admin, span_warning("Target must be an unhatched human Shadowling."))
		return
	var/datum/team/shadow_hive/hive = get_hive()
	for(var/datum/action/cooldown/shadowling/hatch/hatch_act in H.actions.Copy())
		if(hatch_act.channeling)
			hatch_act.fail_ritual(H)
	H.shadowling_strip_quirks()
	H.reset_robotic_limbs()
	if(!original_species)
		original_species = H.dna?.species
	H.set_species(/datum/species/shadow/shadowling)
	hive.sync_after_event(H)
	H.refresh_eye_overlays()
	hive.grant_night_vision(H)
	to_chat(H, span_boldnotice("You shed your disguise and emerge as a true Shadow!"))
	message_admins("[key_name_admin(admin)] forced [key_name_admin(H)] to hatch as a Shadowling.")
	log_admin("[key_name(admin)] forced [key_name(H)] to hatch as a Shadowling.")

/// Admin command to immediately ascend a Shadowling.
/datum/antagonist/shadowling/proc/admin_force_ascend(mob/admin)
	if(!admin?.client?.holder)
		return
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H) || is_thrall || is_ascended)
		to_chat(admin, span_warning("Target must be a non-ascended human Shadowling."))
		return
	var/datum/team/shadow_hive/hive = get_hive()
	for(var/datum/action/cooldown/shadowling/hatch/hatch_act in H.actions.Copy())
		if(hatch_act.channeling)
			hatch_act.fail_ritual(H)
	for(var/datum/action/cooldown/shadowling/ascend/asc_act in H.actions.Copy())
		if(asc_act.channeling)
			asc_act.fail_ritual(H, hive, asc_act.active_circle)
	if(!original_species && !isshadowling(H) && !isshadowling_ascended(H))
		original_species = H.dna?.species
	H.shadowling_strip_quirks()
	H.reset_robotic_limbs()
	H.update_eyes(TRUE)
	set_higher(TRUE)
	hive.is_ascending = FALSE
	hive.sync_after_event(H)
	to_chat(H, span_boldnotice("You shatter your mortal shell and ascend into the ultimate form of the Shadow!"))
	message_admins("[key_name_admin(admin)] forced [key_name_admin(H)] to ascend as a Shadowling.")
	log_admin("[key_name(admin)] forced [key_name(H)] to ascend as a Shadowling.")
	if(tgui_alert(admin, "Trigger the Ascension round-ender / shuttle call?", "Force Ascend", list("Yes", "No")) == "Yes")
		if(!QDELETED(src) && !QDELETED(H) && !QDELETED(admin) && admin.client?.holder)
			get_hive().begin_roundender(H)

/// Admin command to synchronize unlocked hive abilities for the member.
/datum/antagonist/shadowling/proc/admin_sync_hive(mob/admin)
	if(!admin?.client?.holder)
		return
	var/mob/living/carbon/human/H = owner?.current
	var/datum/team/shadow_hive/hive = get_hive()
	if(!istype(H) || !hive)
		return
	hive.sync_hive(H)
	message_admins("[key_name_admin(admin)] synced hive abilities for [key_name_admin(H)].")
	log_admin("[key_name(admin)] synced hive abilities for [key_name(H)].")

/// Admin command to convert a Shadowling or Shadow Thrall into a Lesser Shadowling.
/datum/antagonist/shadowling/proc/admin_convert_lesser(mob/admin)
	if(!admin?.client?.holder)
		return
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H))
		to_chat(admin, span_warning("Target must be a human mob."))
		return
	var/datum/team/shadow_hive/hive = get_hive()
	if(!hive?.convert_to_lesser(H))
		return
	message_admins("[key_name_admin(admin)] converted [key_name_admin(H)] into a Lesser Shadowling.")
	log_admin("[key_name(admin)] converted [key_name(H)] into a Lesser Shadowling.")

/// Admin command to enthrall the currently marked human into the Shadow Hive.
/datum/antagonist/shadowling/proc/admin_add_thrall(mob/admin)
	if(!admin?.client?.holder)
		return
	var/mob/living/carbon/human/target = admin.client.holder.marked_datum
	if(!istype(target) || !target.mind)
		to_chat(admin, span_warning("You need to mark a human with a mind to do this!"))
		return
	if(target.mind.has_antag_datum(/datum/antagonist/shadowling))
		to_chat(admin, span_warning("[target.real_name] is already part of the Shadow Hive."))
		return
	var/obj/item/organ/brain/shadow/tumor_thrall/tumor = new
	if(!tumor.Insert(target))
		qdel(tumor)
		to_chat(admin, span_warning("Failed to insert thrall tumor into [target.real_name]."))
		return
	message_admins("[key_name_admin(admin)] enthralled [key_name_admin(target)] via Shadow Hive admin command.")
	log_admin("[key_name(admin)] enthralled [key_name(target)] via Shadow Hive admin command.")

/// Admin command to free a chosen Shadow Thrall from the hive.
/datum/antagonist/shadowling/proc/admin_remove_thrall(mob/admin)
	if(!admin?.client?.holder)
		return
	var/datum/team/shadow_hive/hive = get_hive()
	if(!hive)
		return
	hive.sanitize()
	if(!length(hive.thralls))
		to_chat(admin, span_warning("There are no thralls in the Shadow Hive."))
		return
	var/list/choices = list()
	for(var/mob/living/carbon/human/T as anything in hive.thralls)
		choices["[T.real_name] ([REF(T)])"] = T
	var/picked = tgui_input_list(admin, "Choose a thrall to free:", "Remove Thrall", choices)
	if(QDELETED(src) || !admin.client?.holder || isnull(picked))
		return
	var/mob/living/carbon/human/chosen = choices[picked]
	if(QDELETED(chosen))
		return
	var/obj/item/organ/brain/shadow/tumor_thrall/tumor = chosen.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL)
	if(istype(tumor))
		tumor.mob_remove(chosen, special = FALSE)
		qdel(tumor)
	else
		chosen.mind?.remove_antag_datum(/datum/antagonist/shadow_thrall)
	message_admins("[key_name_admin(admin)] freed thrall [key_name_admin(chosen)].")
	log_admin("[key_name(admin)] freed thrall [key_name(chosen)].")

/// Leaves the hive, strips Shadowling abilities/stats/species, and calls parent removal.
/datum/antagonist/shadowling/on_removal()
	var/mob/living/carbon/human/H = owner?.current

	var/datum/team/shadow_hive/hive = get_hive()
	if(istype(H) && hive)
		hive.leave_member(H)

	if(hive && owner)
		hive.remove_member(owner)

	if(istype(H))
		clear_powers_and_stats(H)

	. = ..()

/datum/antagonist/shadowling/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner?.current || mob_override
	if(current)
		add_team_hud(current)

/datum/antagonist/shadowling/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner?.current
	if(QDELETED(current))
		return
	// Undo the team HUD added in apply_innate_effects(). This is safe to run on body
	// transfer too, since it only touches the mob we are leaving behind.
	current.remove_alt_appearance("antag_team_hud_[REF(src)]")
	QDEL_NULL(team_hud_ref)

/// Undoes everything the antagonist applied to [current], in reverse order of application:
/// abilities, then max health, then species. Called from on_removal(), so it must never run
/// during a body transfer.
/datum/antagonist/shadowling/proc/clear_powers_and_stats(mob/living/current)
	if(QDELETED(current))
		return

	// Abilities first: they can reference the species or the ascended max health.
	for(var/datum/action/cooldown/ability in current.actions.Copy())
		if(istype(ability, /datum/action/cooldown/shadowling))
			ability.Remove(current)
			qdel(ability)

	if(!ishuman(current))
		return

	revert_shadowling_form(current)

/// Restores the max health and species the mob had before it was transformed.
/datum/antagonist/shadowling/proc/revert_shadowling_form(mob/living/carbon/human/current)
	if(!istype(current))
		return
	restore_max_health(current)
	if(original_species && (isshadowling(current) || isshadowling_ascended(current)))
		current.set_species(original_species)
	original_species = null

/// Restores the max health the mob had before it ascended.
/datum/antagonist/shadowling/proc/restore_max_health(mob/living/carbon/human/H)
	if(!istype(H) || !original_max_health)
		return
	H.setMaxHealth(original_max_health)
	original_max_health = null

/// Moves hive membership, actions, leader status, and transformed Shadowling form onto [new_body].
/datum/antagonist/shadowling/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	if(old_body == new_body)
		return

	var/datum/team/shadow_hive/hive = get_hive()
	var/was_transformed = ishuman(old_body) && (isshadowling(old_body) || isshadowling_ascended(old_body))
	var/was_leader = hive && (old_body == hive.leader)
	var/had_sabotage = isliving(old_body) && !!(locate(/datum/action/cooldown/shadowling/engine_sabotage) in old_body.actions)

	if(isliving(old_body))
		for(var/datum/action/cooldown/ability in old_body.actions.Copy())
			if(istype(ability, /datum/action/cooldown/shadowling))
				ability.Remove(old_body)
				qdel(ability)

	if(ishuman(old_body))
		hive?.leave_member(old_body)
		revert_shadowling_form(old_body)

	if(!ishuman(new_body))
		if(was_leader && hive)
			hive.leader = null
		return

	// Only hatched or ascended Shadowlings transfer the Shadowling body across.
	if(!is_thrall && (was_transformed || is_ascended))
		transfer_shadowling_form(new_body)

	if(hive)
		hive.join_member(new_body, ling_role)
		if(was_leader)
			hive.leader = new_body
		if(!is_thrall && !was_transformed && !is_ascended)
			hive.shadowling_grant_hatch(new_body)
		if(had_sabotage && !is_thrall && !hive.is_shadowling_engine_sabotage_used)
			var/datum/action/cooldown/shadowling/engine_sabotage/sabotage = new
			sabotage.Grant(new_body)
		hive.sync_after_event(new_body)

/// Applies the Shadowling (or ascended) species to [new_body] when a mind changes bodies.
/datum/antagonist/shadowling/proc/transfer_shadowling_form(mob/living/carbon/human/new_body)
	if(isshadowling(new_body) || isshadowling_ascended(new_body))
		return
	if(!original_species)
		original_species = new_body.dna?.species
	if(is_ascended)
		if(!original_max_health)
			original_max_health = new_body.maxHealth
		new_body.set_species(/datum/species/shadow/shadowling/ascended)
	else
		new_body.set_species(/datum/species/shadow/shadowling)

/// Marks this Shadowling datum as a Lesser Shadowling.
/datum/antagonist/shadowling/proc/set_lesser()
	ling_role = SHADOWLING_ROLE_LESSER

/// Transitions the Shadowling between hatched and ascended states, preserving [original_max_health].
/datum/antagonist/shadowling/proc/set_higher(state)
	is_ascended = state
	var/mob/living/carbon/human/H = owner?.current
	var/datum/team/shadow_hive/hive = get_hive()
	if(!istype(H))
		return
	if(state)
		if(!original_max_health)
			original_max_health = H.maxHealth
	else
		restore_max_health(H)
	if(hive)
		hive.shadowling_set_ascended(H, state)

/// Renders the roundend report summary for this Shadowling and hive statistics.
/datum/antagonist/shadowling/roundend_report()
	var/list/report = list()
	if(!owner)
		return "[name] (no owner)"
	report += printplayer(owner)
	var/objectives_complete = TRUE
	if(objectives.len)
		report += printobjectives(objectives)
		for(var/datum/objective/O in objectives)
			if(!O.check_completion())
				objectives_complete = FALSE
				break
	var/datum/team/shadow_hive/hive = get_hive()
	if(hive)
		var/alive_thralls = hive.count_alive_thralls()
		var/total_lings = 0
		var/alive_lings = 0
		for(var/mob/living/carbon/human/L in hive.lings)
			if(QDELETED(L))
				continue
			total_lings++
			if(L.stat != DEAD)
				alive_lings++
		report += "<span class='notice'>Thralls (alive): [alive_thralls]. Shadowlings alive: [alive_lings]/[total_lings].</span>"
	if(objectives.len == 0 || objectives_complete)
		report += "<span class='greentext big'>[name] was successful!</span>"
	else
		report += "<span class='redtext big'>[name] failed!</span>"
	return report.Join("<br>")

/datum/antagonist/shadowling/get_team()
	return get_hive()

// MARK: Admin

ADMIN_VERB(toggle_shadowling_debug, R_DEBUG, "Toggle Shadowling Debug", "Toggles Shadowling test mode (mindless/carbon enthrall, fast cast, bypass lighting).", ADMIN_CATEGORY_DEBUG)
	if(QDELETED(GLOB.shadowling_hive))
		GLOB.shadowling_hive = new /datum/team/shadow_hive
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	hive.debug_mode = !hive.debug_mode
	to_chat(usr, span_boldnotice("Shadowling Debug Mode is now [hive.debug_mode ? "ENABLED" : "DISABLED"]."))
	message_admins("[ADMIN_LOOKUPFLW(usr)] toggled Shadowling Debug Mode to [hive.debug_mode ? "ENABLED" : "DISABLED"].")
