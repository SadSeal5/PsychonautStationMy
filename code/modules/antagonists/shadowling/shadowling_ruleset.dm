// MARK: Ruleset Helpers

/// Appends Head of Staff jobs to a ruleset's always-blacklisted roles.
/datum/dynamic_ruleset/proc/shadowling_blacklisted_roles(list/base_roles)
	PROTECTED_PROC(TRUE)
	var/list/blacklisted = base_roles || list()
	for(var/datum/job/J as anything in SSjob.all_occupations)
		if(J.job_flags & JOB_HEAD_OF_STAFF)
			blacklisted |= J.title
	return blacklisted

/// Rejects Head of Staff candidates from Shadowling rulesets.
/datum/dynamic_ruleset/proc/is_valid_shadowling_candidate(mob/candidate)
	PROTECTED_PROC(TRUE)
	if(candidate.mind?.assigned_role?.job_flags & JOB_HEAD_OF_STAFF)
		return FALSE
	return TRUE

// MARK: Roundstart Ruleset

/// Dynamic roundstart ruleset assigning initial Shadowlings.
/datum/dynamic_ruleset/roundstart/shadowling
	name = "Shadowlings"
	config_tag = "Roundstart Shadowlings"
	preview_antag_datum = /datum/antagonist/shadowling

	repeatable = FALSE
	weight = 3
	min_pop = 20

	pref_flag = ROLE_SHADOWLING
	jobban_flag = ROLE_SHADOWLING

	min_antag_cap = 3
	max_antag_cap = list("denominator" = 15, "offset" = 1)
	track = EVENT_TRACK_MAJOR
	tags = list(TAG_COMBAT, TAG_CREW_ANTAG, TAG_TEAM_ANTAG, TAG_ALIEN, TAG_SPOOKY)

/datum/dynamic_ruleset/roundstart/shadowling/get_always_blacklisted_roles()
	return shadowling_blacklisted_roles(..())

/datum/dynamic_ruleset/roundstart/shadowling/is_valid_candidate(mob/candidate, client/candidate_client)
	. = ..()
	if(!.)
		return FALSE
	return is_valid_shadowling_candidate(candidate)

/datum/dynamic_ruleset/roundstart/shadowling/assign_role(datum/mind/candidate)
	candidate.add_antag_datum(/datum/antagonist/shadowling)

// MARK: Midround Ruleset

/// Dynamic midround ruleset converting living crewmembers into Shadowlings before Ascension.
/datum/dynamic_ruleset/midround/from_living/shadowling
	name = "Shadowling Awakening"
	config_tag = "Midround Shadowlings"
	preview_antag_datum = /datum/antagonist/shadowling
	midround_type = HEAVY_MIDROUND

	pref_flag = ROLE_SHADOWLING
	jobban_flag = ROLE_SHADOWLING
	ruleset_flags = RULESET_VARIATION

	weight = alist(
		DYNAMIC_TIER_LOW = 0,
		DYNAMIC_TIER_LOWMEDIUM = 1,
		DYNAMIC_TIER_MEDIUMHIGH = 3,
		DYNAMIC_TIER_HIGH = 3,
	)
	min_pop = 20
	min_antag_cap = 1
	max_antag_cap = 2
	repeatable = FALSE
	track = EVENT_TRACK_MAJOR
	tags = list(TAG_COMBAT, TAG_CREW_ANTAG, TAG_TEAM_ANTAG, TAG_ALIEN, TAG_SPOOKY)

/datum/dynamic_ruleset/midround/from_living/shadowling/can_be_selected()
	return ..() && !GLOB.shadowling_hive?.is_ascended

/datum/dynamic_ruleset/midround/from_living/shadowling/get_always_blacklisted_roles()
	return shadowling_blacklisted_roles(..())

/datum/dynamic_ruleset/midround/from_living/shadowling/is_valid_candidate(mob/candidate, client/candidate_client)
	. = ..()
	if(!.)
		return FALSE
	return is_valid_shadowling_candidate(candidate)

/datum/dynamic_ruleset/midround/from_living/shadowling/assign_role(datum/mind/candidate)
	candidate.add_antag_datum(/datum/antagonist/shadowling)

// MARK: Latejoin Ruleset

/// Dynamic latejoin ruleset assigning arriving crew as Shadowlings before Ascension.
/datum/dynamic_ruleset/latejoin/shadowling
	name = "Stowaway Shadowling"
	config_tag = "Latejoin Shadowlings"
	preview_antag_datum = /datum/antagonist/shadowling

	pref_flag = ROLE_SHADOWLING
	jobban_flag = ROLE_SHADOWLING
	ruleset_flags = RULESET_VARIATION

	weight = 2
	min_pop = 20
	repeatable = FALSE
	track = EVENT_TRACK_MAJOR
	tags = list(TAG_COMBAT, TAG_CREW_ANTAG, TAG_TEAM_ANTAG, TAG_ALIEN, TAG_SPOOKY)

/datum/dynamic_ruleset/latejoin/shadowling/can_be_selected()
	return ..() && !GLOB.shadowling_hive?.is_ascended

/datum/dynamic_ruleset/latejoin/shadowling/get_always_blacklisted_roles()
	return shadowling_blacklisted_roles(..())

/datum/dynamic_ruleset/latejoin/shadowling/is_valid_candidate(mob/candidate, client/candidate_client)
	. = ..()
	if(!.)
		return FALSE
	return is_valid_shadowling_candidate(candidate)

/datum/dynamic_ruleset/latejoin/shadowling/assign_role(datum/mind/candidate)
	candidate.add_antag_datum(/datum/antagonist/shadowling)
