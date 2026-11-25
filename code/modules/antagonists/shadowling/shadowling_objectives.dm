// MARK: Objectives

/// Team objective tracking the fraction of starting crew that must be enthralled.
/datum/objective/shadowling/enslave_fraction
	name = "Subjugate the crew"
	admin_grantable = TRUE
	/// Percentage of [baseline_population] required as living thralls.
	var/percent = 50
	/// Captured crew population used to compute [required_thralls()].
	var/baseline_population = 0

/datum/objective/shadowling/enslave_fraction/New(pct = null)
	if(isnum(pct))
		percent = clamp(round(pct), 1, 100)
	capture_baseline_population()
	update_explanation_text()
	return ..()

/// Snapshots ready players or current crewmember minds as the scaling baseline.
/datum/objective/shadowling/enslave_fraction/proc/capture_baseline_population()
	var/datum/team/shadow_hive/hive = team || GLOB.shadowling_hive
	if(hive && !QDELETED(hive))
		baseline_population = hive.compute_crew_baseline()
		return
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.ready == PLAYER_READY_TO_PLAY)
			baseline_population++
	if(!baseline_population)
		baseline_population = length(get_crewmember_minds())
	baseline_population = max(1, baseline_population)

/// Returns the minimum number of living thralls required by this objective.
/datum/objective/shadowling/enslave_fraction/proc/required_thralls()
	return max(1, CEILING((baseline_population * percent) / 100, 1))

/// Returns the current count of living thralls in the associated hive.
/datum/objective/shadowling/enslave_fraction/proc/current_thralls()
	var/datum/team/shadow_hive/hive = team || GLOB.shadowling_hive
	if(!hive || QDELETED(hive))
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

		var/datum/team/shadow_hive/hive = team || GLOB.shadowling_hive
		if(hive && !QDELETED(hive))
			hive.refresh_ascension_thralls_needed()

/// Team objective completed when the hive ascends or its owner is an Ascended Shadowling.
/datum/objective/shadowling/ascend
	name = "Achieve Ascension"
	admin_grantable = TRUE

/datum/objective/shadowling/ascend/update_explanation_text()
	explanation_text = "Ascend, taking on the ultimate form of the Shadowling."

/datum/objective/shadowling/ascend/check_completion()
	// Team objectives never get an owner, so the hive is the source of truth.
	var/datum/team/shadow_hive/hive = team || GLOB.shadowling_hive
	if(hive && !QDELETED(hive) && hive.is_ascended)
		return TRUE
	if(!owner?.current)
		return FALSE
	var/mob/living/carbon/human/H = owner.current
	return istype(H.dna?.species, /datum/species/shadow/shadowling/ascended)
