// MARK: Ability

/// Innate Shadowling ability initiating or participating in the hive leader election.
/datum/action/cooldown/shadowling/election
	name = "Elect Hive Leader"
	desc = "Initiate an election for the Shadowling hive leader. The winner will be granted Engine Sabotage."
	button_icon_state = "shadow_vote"
	cooldown_time = 0 SECONDS
	role_flags = SL_INNATE

/datum/action/cooldown/shadowling/election/IsAvailable(feedback = FALSE)
	if(!..())
		return FALSE
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	if(!hive)
		return FALSE
	if(hive.is_shadowling_vote_finished)
		if(feedback && owner)
			to_chat(owner, span_warning("A hive leader has already been chosen."))
		return FALSE
	return TRUE

/datum/action/cooldown/shadowling/election/do_effect(mob/living/carbon/human/H, atom/_)
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	if(!hive)
		return FALSE
	if(hive.is_shadowling_vote_finished)
		return FALSE

	if(hive.shadowling_vote)
		var/datum/shadow_vote/current = hive.shadowling_vote
		current.prompt_one(H)
		return TRUE

	var/datum/shadow_vote/vote = new(hive)
	vote.start()
	return TRUE

// MARK: Election Datum

/// Timed ballot manager selecting the Shadowling hive leader and granting Engine Sabotage.
/datum/shadow_vote
	/// Hive team hosting this election.
	var/datum/team/shadow_hive/hive
	/// Voting window duration before automatic finalization.
	var/duration = 30 SECONDS
	/// Whether ballot collection is currently open.
	var/active = FALSE
	/// Eligible living Shadowlings on the ballot.
	var/list/candidates = list()
	/// Map of voter mob -> chosen candidate mob.
	var/list/votes = list()

/datum/shadow_vote/New(datum/team/shadow_hive/_hive, dur = 30 SECONDS)
	. = ..()
	hive = _hive
	duration = dur
	if(hive)
		hive.shadowling_vote = src

/// Gathers living Shadowling candidates, prompts voters, and schedules finalization.
/datum/shadow_vote/proc/start()
	if(active)
		return
	if(!hive)
		qdel(src)
		return
	active = TRUE

	candidates.Cut()
	for(var/mob/living/carbon/human/L in hive.lings)
		if(QDELETED(L) || L.stat == DEAD)
			continue
		candidates += L

	for(var/mob/living/carbon/human/L in hive.lings)
		if(QDELETED(L) || L.stat == DEAD)
			continue
		to_chat(L, span_boldnotice("A vote for the Hive Leader has begun! You have 30 seconds to choose."))

	if(length(candidates) <= 1)
		finalize()
		return

	for(var/mob/living/carbon/human/L in hive.lings)
		if(QDELETED(L) || !L.client || L.stat == DEAD)
			continue
		addtimer(CALLBACK(src, PROC_REF(prompt_one), L), 0)

	addtimer(CALLBACK(src, PROC_REF(finalize)), duration, TIMER_STOPPABLE)

/// Prompts [voter] with a TGUI list of living candidates and records their vote.
/datum/shadow_vote/proc/prompt_one(mob/living/carbon/human/voter)
	if(!active)
		return
	if(QDELETED(voter))
		return
	if(!(voter in hive.lings))
		return

	var/list/choices = list()
	for(var/mob/living/carbon/human/C in candidates)
		choices["[C.real_name] ([REF(C)])"] = C

	var/ans = tgui_input_list(voter, "Choose the hive leader:", "Hive Vote", choices)
	if(!active)
		return

	if(ans && (voter in hive.lings) && !(voter in votes))
		votes[voter] = choices[ans]
		to_chat(voter, span_notice("Your vote has been recorded."))
		for(var/datum/action/cooldown/shadowling/election/A in voter.actions)
			A.Remove(voter)
			qdel(A)

/// Tallies votes, assigns `hive.leader`, grants Engine Sabotage, and cleans up election actions.
/datum/shadow_vote/proc/finalize()
	if(!active)
		return
	active = FALSE

	var/list/living_candidates = list()
	for(var/mob/living/carbon/human/C in candidates)
		if(!QDELETED(C) && C.stat != DEAD && (C in hive.lings))
			living_candidates += C

	var/list/tally = list()
	for(var/mob/living/carbon/human/C in living_candidates)
		tally[C] = 0
	for(var/mob/living/carbon/human/Voter in votes)
		var/mob/living/carbon/human/Choice = votes[Voter]
		if(Choice && (Choice in tally))
			tally[Choice]++

	var/list/winners = list()
	var/best = -1
	for(var/mob/living/carbon/human/C in tally)
		var/cnt = tally[C]
		if(cnt > best)
			winners = list(C); best = cnt
		else if(cnt == best)
			winners += C
	if(!length(winners))
		winners = living_candidates.Copy()

	var/mob/living/carbon/human/leader = length(winners) ? pick(winners) : null

	if(leader && !QDELETED(leader))
		hive.leader = leader
		if(!hive.is_shadowling_engine_sabotage_used)
			var/datum/action/cooldown/shadowling/engine_sabotage/S = new
			S.Grant(leader)

		for(var/mob/living/carbon/human/L in hive.lings)
			if(QDELETED(L))
				continue
			to_chat(L, span_boldnotice("The hive leader has been chosen: [leader.real_name].[!hive.is_shadowling_engine_sabotage_used ? " They have been granted Engine Sabotage." : ""]"))

	remove_vote_action_from_all()

	hive.is_shadowling_vote_finished = TRUE

	if(hive.shadowling_vote == src)
		hive.shadowling_vote = null

	qdel(src)

/// Removes remaining election actions from every Shadowling and thrall in the hive.
/datum/shadow_vote/proc/remove_vote_action_from_all()
	if(!hive)
		return
	for(var/mob/living/carbon/human/M as anything in hive.get_all_members())
		if(QDELETED(M))
			continue
		for(var/datum/action/cooldown/shadowling/election/A in M.actions.Copy())
			A.Remove(M)
			qdel(A)
