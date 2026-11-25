// MARK: TGUI

/// Opens or updates the Shadowling Broodmind TGUI window for [user].
/datum/antagonist/shadowling/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, ui_name, "Shadowling Broodmind")
		ui.open()

/// Builds the TGUI state payload containing role, hive progress, objectives, roster, and abilities.
/datum/antagonist/shadowling/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/carbon/human/H = ishuman(user) ? user : (owner?.current && ishuman(owner.current) ? owner.current : null)
	var/datum/team/shadow_hive/hive = get_hive()
	if(hive)
		hive.sanitize()

	var/role_text = "Master Shadowling"
	var/role_code = "master"
	if(is_ascended || (H && isshadowling_ascended(H)))
		role_text = "Ascended Shadowling"
		role_code = "ascended"
	else if(is_thrall)
		role_text = "Shadow Thrall"
		role_code = "thrall"
	else if(ling_role == SHADOWLING_ROLE_LESSER)
		role_text = "Lesser Shadowling"
		role_code = "lesser"

	var/thrall_count = hive ? hive.count_alive_thralls() : 0
	var/thralls_needed = hive ? hive.get_ascension_thralls_needed() : 0

	data["name"] = H?.real_name || "Unknown"
	data["role"] = role_text
	data["role_type"] = role_code
	data["is_ascended"] = is_ascended || (H && isshadowling_ascended(H))
	data["is_thrall"] = is_thrall
	data["is_hatched"] = H && (isshadowling(H) || isshadowling_ascended(H))
	data["hive_name"] = hive?.name || "The Shadow Brood"
	data["thrall_count"] = thrall_count
	data["thralls_needed"] = thralls_needed
	data["ascension_progress"] = thralls_needed > 0 ? min(100, round((thrall_count / thralls_needed) * 100)) : 0
	data["is_hive_ascended"] = hive ? hive.is_ascended : FALSE
	data["leader_name"] = hive?.leader ? hive.leader.real_name : null

	if(hive)
		hive.update_objective_explanations()
	if(is_thrall)
		for(var/datum/objective/O in objectives)
			O.update_explanation_text()

	data["objectives"] = get_objectives()
	data["can_change_objective"] = can_assign_self_objectives

	var/list/roster = list()
	if(hive)
		for(var/mob/living/carbon/human/ling as anything in hive.lings)
			if(QDELETED(ling))
				continue
			var/m_role = "Master Shadowling"
			if(isshadowling_ascended(ling))
				m_role = "Ascended Shadowling"
			else if(hive.get_ling_role(ling) == SHADOWLING_ROLE_LESSER)
				m_role = "Lesser Shadowling"
			roster += list(build_roster_entry(ling, H, m_role))

		for(var/mob/living/carbon/human/thrall as anything in hive.thralls)
			if(QDELETED(thrall))
				continue
			roster += list(build_roster_entry(thrall, H, "Shadow Thrall"))

	data["roster"] = roster
	data["abilities"] = get_abilities_data(H, hive, thralls_needed)

	return data

/// Builds a single Broodmind roster entry for [member] relative to [viewer].
/datum/antagonist/shadowling/proc/build_roster_entry(mob/living/carbon/human/member, mob/living/carbon/human/viewer, role_label)
	var/member_stat = "Alive"
	if(istype(member.loc, /obj/effect/dummy/phased_mob/shadowling))
		member_stat = "Phased"
	else if(member.stat == DEAD)
		member_stat = "Dead"
	else if(IS_UNCONSCIOUS_OR_CRIT(member) || member.health <= 0)
		member_stat = "Critical"

	return list(
		"name" = member.real_name || member.name,
		"role" = role_label,
		"stat" = member_stat,
		"is_user" = (member == viewer),
	)

/// Collects metadata and unlock status for Shadowling abilities relevant to the viewer's role.
/datum/antagonist/shadowling/proc/get_abilities_data(mob/living/carbon/human/H, datum/team/shadow_hive/hive, thralls_needed)
	var/list/owned_action_types = list()
	if(H)
		for(var/datum/action/cooldown/shadowling/A in H.actions)
			owned_action_types[A.type] = TRUE

	var/list/innate_list = list()
	var/list/threshold_list = list()
	var/list/ascended_list = list()

	for(var/path in subtypesof(/datum/action/cooldown/shadowling))
		var/datum/action/cooldown/shadowling/sample = path
		var/flags = initial(sample.role_flags)
		if(is_thrall)
			if(!(flags & SL_THRALL))
				continue
		else if(ling_role == SHADOWLING_ROLE_LESSER)
			if(!(flags & SL_LESSER))
				continue
		else if(!(flags & (SL_INNATE | SL_THRESHOLD | SL_ASCENDED)))
			continue

		var/category = "Innate"
		var/pct = 0
		var/calc_thralls = 0
		var/ch = round(initial(sample.channel_time) / 10)
		var/req_dark = initial(sample.requires_dark_user) || initial(sample.requires_dark_target)

		if(ispath(path, /datum/action/cooldown/shadowling/enthrall))
			var/datum/action/cooldown/shadowling/enthrall/enthrall_sample = path
			ch = round((initial(enthrall_sample.enthrall_time) * 3) / 10)
		else if(ispath(path, /datum/action/cooldown/shadowling/hatch))
			var/datum/action/cooldown/shadowling/hatch/hatch_sample = path
			ch = round((initial(hatch_sample.steps) * initial(hatch_sample.step_time)) / 10)
		else if(ispath(path, /datum/action/cooldown/shadowling/ascend))
			var/datum/action/cooldown/shadowling/ascend/ascend_sample = path
			ch = round((initial(ascend_sample.steps) * initial(ascend_sample.step_time)) / 10)

		if(flags & SL_INNATE)
			category = "Innate"
		else if(flags & SL_THRESHOLD)
			category = "Threshold"
			pct = initial(sample.required_thralls)
			calc_thralls = hive ? hive.get_required_thralls_for(path) : 0
		else if(flags & SL_ASCENDED)
			category = "Ascended"
			pct = 100
			calc_thralls = thralls_needed
			if(ispath(path, /datum/action/cooldown/shadowling/root))
				req_dark = TRUE

		var/list/entry = list(
			"name" = initial(sample.name),
			"desc" = initial(sample.desc),
			"icon" = initial(sample.button_icon_state),
			"cooldown" = round(initial(sample.cooldown_time) / 10),
			"channel" = ch,
			"required_thralls" = calc_thralls,
			"required_percent" = pct,
			"unlocked" = !isnull(owned_action_types[path]),
			"category" = category,
			"requires_dark" = req_dark,
		)

		switch(category)
			if("Innate")
				innate_list += list(entry)
			if("Threshold")
				var/insert_idx = 1
				while(insert_idx <= length(threshold_list) && threshold_list[insert_idx]["required_percent"] <= pct)
					insert_idx++
				threshold_list.Insert(insert_idx, list(entry))
			else
				ascended_list += list(entry)

	return innate_list + threshold_list + ascended_list

/// Handles Broodmind TGUI actions (`sync` abilities and `commune` telepathy) for the owning mob.
/datum/antagonist/shadowling/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!owner || ui.user != owner.current)
		return TRUE

	. = ..()
	if(.)
		return TRUE

	var/mob/living/carbon/human/H = ui.user
	if(!istype(H))
		return TRUE

	var/datum/team/shadow_hive/hive = get_hive()

	switch(action)
		if("sync")
			if(IS_UNCONSCIOUS_OR_CRIT(H) || HAS_TRAIT(H, TRAIT_INCAPACITATED))
				H.balloon_alert(H, "cannot sync while incapacitated")
				return TRUE
			if(!COOLDOWN_FINISHED(src, sync_cooldown))
				H.balloon_alert(H, "sync on cooldown")
				return TRUE
			if(is_thrall || isshadowling(H) || isshadowling_ascended(H) || ling_role == SHADOWLING_ROLE_LESSER)
				COOLDOWN_START(src, sync_cooldown, 3 SECONDS)
				hive?.sync_hive(H)
			else
				H.balloon_alert(H, "must hatch first")
			return TRUE
		if("commune")
			for(var/datum/action/cooldown/shadowling/commune/C in H.actions)
				C.Trigger(target = H)
				break
			return TRUE
