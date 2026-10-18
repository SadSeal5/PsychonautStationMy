/datum/mood_event/shadowling
	description = "The cold darkness within whispers of power."
	mood_change = 12
	hidden = TRUE

// MARK: Antagonist
/datum/antagonist/shadowling
	name = "Shadowling"
	roundend_category = "Shadowlings"
	antagpanel_category = "Shadowling"
	pref_flag = ROLE_SHADOWLING
	stinger_sound = 'sound/antagonists/shadowlings/shadowling_gain.ogg'
	antag_moodlet = /datum/mood_event/shadowling
	hud_icon = 'icons/mob/huds/antag_hud.dmi'
	antag_hud_name = "shadowling"

	var/ling_role = SHADOWLING_ROLE_MAIN
	var/is_thrall = FALSE
	var/is_ascended = FALSE

	var/datum/team/shadow_hive/shadow_team

/datum/antagonist/shadowling/can_be_owned(datum/mind/new_owner)
	if(new_owner?.has_antag_datum(type))
		return FALSE
	return ..()

/datum/antagonist/shadowling/get_preview_icon()
	var/mob/living/carbon/human/dummy/consistent/dummy = new()
	dummy.set_species(/datum/species/shadow/shadowling, icon_update = TRUE)
	return finish_preview_icon(render_preview_outfit(preview_outfit, dummy))

/datum/antagonist/shadowling/on_gain()
	if(!owner)
		return

	var/datum/team/shadow_hive/hive = get_shadow_hive()
	shadow_team = hive
	shadow_team.setup_objectives()

	shadow_team.add_member(owner)

	var/mob/living/carbon/human/H = owner.current
	if(istype(H))
		shadow_team.join_member(H, ling_role)
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
		objectives |= shadow_team.get_objectives()

	. = ..()

	if(istype(H))
		add_team_hud(H)
		shadow_team.sync_after_event(H)

	owner.announce_objectives()

/datum/antagonist/shadowling/on_removal()
	var/mob/living/carbon/human/H = owner?.current

	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(istype(H) && hive)
		hive.leave_member(H)

	if(shadow_team && owner)
		shadow_team.remove_member(owner)

	if(istype(H))
		for(var/datum/action/cooldown/ability in H.actions)
			if(ability.type in typesof(/datum/action/cooldown/shadowling))
				ability.Remove(H)

	. = ..()

/datum/antagonist/shadowling/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner?.current || mob_override
	if(current)
		add_team_hud(current)

/datum/antagonist/shadowling/proc/set_lesser()
	ling_role = SHADOWLING_ROLE_LESSER

/datum/antagonist/shadowling/proc/set_higher(state)
	is_ascended = state
	var/mob/living/carbon/human/H = owner?.current
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(istype(H) && hive)
		hive.shadowling_set_ascended(H, state)

/datum/antagonist/shadow_thrall
	parent_type = /datum/antagonist/shadowling
	name = "Shadow Thrall"
	antagpanel_category = "Shadowlings"
	antag_hud_name = "shadowling_thrall"

	is_thrall = TRUE
	ling_role = SHADOWLING_ROLE_THRALL

/datum/antagonist/shadow_thrall/on_gain()
	. = ..()

	var/mob/living/carbon/human/H = owner?.current
	if(istype(H) && !H.get_organ_slot(ORGAN_SLOT_BRAIN_THRALL))
		var/obj/item/organ/brain/shadow/tumor_thrall/tumor = new
		tumor.Insert(H)

// MARK: Objectives
/datum/objective/shadowling/enslave_fraction
	name = "Subjugate the crew"
	admin_grantable = TRUE
	var/percent = 50
	var/baseline_population = 0

/datum/objective/shadowling/enslave_fraction/New(pct = null)
	if(isnum(pct))
		percent = clamp(round(pct), 1, 100)
	capture_baseline_population()
	update_explanation_text()
	return ..()

/datum/objective/shadowling/enslave_fraction/proc/capture_baseline_population()
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.ready == PLAYER_READY_TO_PLAY)
			baseline_population++
	if(!baseline_population)
		baseline_population = length(get_crewmember_minds())
	if(baseline_population <= 0)
		baseline_population = 1

/datum/objective/shadowling/enslave_fraction/proc/required_thralls()
	return max(1, CEILING((baseline_population * percent) / 100, 1))

/datum/objective/shadowling/enslave_fraction/proc/current_thralls()
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(!hive)
		return 0
	return hive.count_alive_thralls()

/datum/objective/shadowling/enslave_fraction/update_explanation_text()
	var/need = required_thralls()
	var/have = current_thralls()
	explanation_text = "Enslave at least [need] crew members. Currently: [have]/[need]."

/datum/objective/shadowling/enslave_fraction/check_completion()
	return current_thralls() >= required_thralls()

/datum/objective/shadowling/enslave_fraction/admin_edit(mob/admin)
	var/new_pct = input(admin, "What percentage of starting crew must be enslaved?", "Shadowling objective", percent) as num|null
	if(isnum(new_pct))
		percent = clamp(round(new_pct), 1, 100)
		update_explanation_text()

		var/datum/team/shadow_hive/hive = get_shadow_hive()
		hive?.refresh_ascension_thralls_needed()

/datum/objective/shadowling/ascend
	name = "Achieve Ascension"
	admin_grantable = TRUE

/datum/objective/shadowling/ascend/update_explanation_text()
	explanation_text = "Ascend, taking on the ultimate form of the Shadowling."

/datum/objective/shadowling/ascend/check_completion()
	if(!owner || !owner.current)
		return FALSE
	var/mob/living/carbon/human/H = owner.current
	return istype(H.dna?.species, /datum/species/shadow/shadowling/ascended)

/datum/antagonist/shadowling/roundend_report()
	var/list/report = list()
	if(!owner)
		CRASH("Antagonist datum without owner")
	report += printplayer(owner)
	var/objectives_complete = TRUE
	if(objectives.len)
		report += printobjectives(objectives)
		for(var/datum/objective/O in objectives)
			if(!O.check_completion())
				objectives_complete = FALSE
				break
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(hive)
		var/alive_thralls = hive.count_alive_thralls()
		var/total_lings = 0
		var/alive_lings = 0
		for(var/mob/living/carbon/human/L in hive.lings)
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
	return shadow_team

/datum/objective/shadow_thrall
	name = "Thrall Objective"
	admin_grantable = TRUE

/datum/objective/shadow_thrall/survive
	name = "Survive"
	explanation_text = "Survive until the end of the round while remaining a thrall of the Shadow."

/datum/objective/shadow_thrall/survive/check_completion()
	if(!owner || !owner.current)
		return FALSE
	if(owner.current.stat == DEAD)
		return FALSE
	return !!owner.has_antag_datum(/datum/antagonist/shadow_thrall, TRUE)

/datum/objective/shadow_thrall/assist_ascension
	name = "Assist Ascension"
	explanation_text = "Help the shadowlings ascend: at least one Ascended Shadowling must exist by the end of the round."

/datum/objective/shadow_thrall/assist_ascension/check_completion()
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(!hive)
		return FALSE
	for(var/mob/living/carbon/human/L in hive.lings)
		if(isshadowling_ascended(L))
			return TRUE
	return FALSE

/datum/objective/shadow_thrall/save_shadowlings
	name = "Save your Masters"
	explanation_text = "If the shadowlings are dead or missing: rally the thralls, gather your strength, and find and save your Masters."

/datum/objective/shadow_thrall/save_shadowlings/check_completion()
	var/datum/team/shadow_hive/hive = get_shadow_hive()
	if(!hive)
		return FALSE
	for(var/mob/living/carbon/human/L in hive.lings)
		if(isshadowling_ascended(L))
			return TRUE
	return FALSE

// MARK: Global shadowling roundender
/proc/shadowling_begin_roundender(mob/living/carbon/human/ascended=null)
	if(GLOB.is_shadowling_roundender_started)
		return
	GLOB.is_shadowling_roundender_started = TRUE

	send_to_playing_players("<span class='shadowradio_win'><b>THE UNIFIED SHADOW CONSUMES THE STATION!</b></span>")
	for(var/mob/player as anything in GLOB.player_list)
		if(player && !isnewplayer(player))
			SEND_SOUND(player, sound(SHADOWLING_RISEN_MUSIC, volume = 70))

	priority_announce(
		text = "Caution! Our long-range sensors have detected an unprecedented surge of paranormal activity. Due to imminent station consumption, immediately mobilize all assets and initiate emergency evacuation procedures. Emergency shuttle launch is authorized and irreversible.",
		title = "[command_name()]: Paranormal Phenomenon Division",
		sound = SSstation.announcer.get_rand_report_sound(),
		has_important_message = TRUE,
	)

	var/atom/hostile_ref = ascended ? ascended : world
	SSshuttle.registerHostileEnvironment(hostile_ref)
	SSshuttle.lockdown = TRUE
	SSshuttle.requestEvac(ascended, "Emergency evacuation authorized due to paranormal threat.")
