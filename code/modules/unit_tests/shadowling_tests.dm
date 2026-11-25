// MARK: Base

/// Base unit test datum for Shadowling tests; saves and restores global Shadowling state between runs.
/datum/unit_test/shadowling_base
	abstract_type = /datum/unit_test/shadowling_base
	var/saved_debug_mode
	var/saved_roundender_started

/datum/unit_test/shadowling_base/New()
	. = ..()
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	saved_debug_mode = hive ? hive.debug_mode : FALSE
	saved_roundender_started = hive ? hive.roundender_started : FALSE

/datum/unit_test/shadowling_base/Destroy()
	. = ..()
	cleanup_shadowling_state()

/// Restores Shadowling hive flags and resets `GLOB.shadowling_hive` via `reset_hive()`.
/datum/unit_test/shadowling_base/proc/cleanup_shadowling_state()
	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	if(!hive || QDELETED(hive))
		hive = new /datum/team/shadow_hive
		GLOB.shadowling_hive = hive
	else
		hive.reset_hive(clear_objectives = TRUE)
	hive.debug_mode = saved_debug_mode
	hive.roundender_started = saved_roundender_started

// MARK: Core Lifecycle Tests

/// Tests basic Shadowling antagonist assignment, hive registration, and ability grants
/datum/unit_test/shadowling_initialization
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_initialization/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT_NOTNULL(ling_antag, "Shadowling antagonist datum could not be added to mind.")

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	TEST_ASSERT_NOTNULL(hive, "Shadowling hive team was not created.")
	TEST_ASSERT(ling_mob in hive.lings, "Shadowling mob was not registered in hive.lings.")

	// Verify hatch action
	var/datum/action/cooldown/shadowling/hatch/hatch_action = locate(/datum/action/cooldown/shadowling/hatch) in ling_mob.actions
	TEST_ASSERT_NOTNULL(hatch_action, "Shadowling was not granted hatch action upon initialization.")

	// Verify hive communication
	var/datum/action/cooldown/shadowling/commune/comm_action = locate(/datum/action/cooldown/shadowling/commune) in ling_mob.actions
	TEST_ASSERT_NOTNULL(comm_action, "Shadowling was not granted commune action upon initialization.")

	// Unhatched shadowling should not have abilities prior to hatching
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/glare) in ling_mob.actions, "Unhatched shadowling was granted glare action.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/veil) in ling_mob.actions, "Unhatched shadowling was granted veil action.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/enthrall) in ling_mob.actions, "Unhatched shadowling was granted enthrall action.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/toggle_night_vision) in ling_mob.actions, "Unhatched shadowling was granted toggle_night_vision action.")

/// Tests Shadowling ability unlocking and execution upon hatching
/datum/unit_test/shadowling_abilities_execution
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_abilities_execution/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT_NOTNULL(ling_antag, "Shadowling antagonist datum could not be added.")

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	TEST_ASSERT_NOTNULL(hive, "Shadowling hive team was not created.")

	var/datum/action/cooldown/shadowling/glare/glare_action = locate(/datum/action/cooldown/shadowling/glare) in ling_mob.actions
	TEST_ASSERT_NULL(glare_action, "Glare action was present before hatching.")

	ling_mob.set_species(/datum/species/shadow/shadowling)
	hive.sync_after_event(ling_mob)

	glare_action = locate(/datum/action/cooldown/shadowling/glare) in ling_mob.actions
	TEST_ASSERT_NOTNULL(glare_action, "Shadowling was not granted glare action after hatching.")

	var/triggered = glare_action.Trigger(ling_mob)
	TEST_ASSERT(triggered, "Glare action failed to trigger.")
	TEST_ASSERT(glare_action.next_use_time > world.time, "Glare action did not enter cooldown.")

/// Tests Thrall tumor insertion, antagonist assignment, hive tracking, and extraction
/datum/unit_test/shadow_thrall_lifecycle
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadow_thrall_lifecycle/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	victim.mind_initialize()
	victim.mock_client = new()

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	var/initial_thrall_count = hive.count_alive_thralls()

	// Insert thrall tumor
	var/obj/item/organ/brain/shadow/tumor_thrall/tumor = new
	var/inserted = tumor.Insert(victim)
	TEST_ASSERT(inserted, "Failed to insert thrall tumor into victim.")

	var/datum/antagonist/shadow_thrall/thrall_antag = victim.mind.has_antag_datum(/datum/antagonist/shadow_thrall)
	TEST_ASSERT_NOTNULL(thrall_antag, "Victim did not gain Shadow Thrall antagonist datum after tumor insertion.")
	TEST_ASSERT(victim in hive.thralls, "Victim was not registered in hive.thralls.")
	TEST_ASSERT_EQUAL(hive.count_alive_thralls(), initial_thrall_count + 1, "Hive alive thrall count did not increment.")

	// Remove tumor (simulate neurosurgery extraction)
	tumor.mob_remove(victim, special = FALSE)
	TEST_ASSERT(tumor.inert, "Extracted thrall tumor was not marked inert.")

	var/mob/living/carbon/human/second_victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	second_victim.mind_initialize()
	tumor.Insert(second_victim)
	TEST_ASSERT_NULL(second_victim.mind.has_antag_datum(/datum/antagonist/shadow_thrall), "Inert thrall tumor incorrectly granted Shadow Thrall antag datum.")
	qdel(tumor)

	TEST_ASSERT_NULL(victim.mind.has_antag_datum(/datum/antagonist/shadow_thrall), "Victim still retained Shadow Thrall antag datum after tumor removal.")
	TEST_ASSERT(!(victim in hive.thralls), "Victim was not removed from hive.thralls after tumor removal.")

/// Regression test for the Ascension objective, which used to read a null owner and never complete.
/datum/unit_test/shadowling_ascend_objective
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_ascend_objective/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT_NOTNULL(ling_antag, "Shadowling antagonist datum could not be added.")

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	TEST_ASSERT_NOTNULL(hive, "Shadowling hive team was not created.")

	var/datum/objective/shadowling/ascend/ascend_objective
	for(var/datum/objective/objective as anything in hive.objectives)
		if(istype(objective, /datum/objective/shadowling/ascend))
			ascend_objective = objective
			break
	TEST_ASSERT_NOTNULL(ascend_objective, "Hive did not create an Ascension objective.")
	TEST_ASSERT_NULL(ascend_objective.owner, "Team objective unexpectedly had an owner; the test no longer covers the bug.")

	TEST_ASSERT(!ascend_objective.check_completion(), "Ascension objective completed before the hive ascended.")
	hive.is_ascended = TRUE
	TEST_ASSERT(ascend_objective.check_completion(), "Ascension objective did not complete after the hive ascended.")
	hive.is_ascended = FALSE

/// Regression test for on_removal reverting the species the mob had before hatching.
/datum/unit_test/shadowling_removal_reverts_species
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_removal_reverts_species/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT_NOTNULL(ling_antag, "Shadowling antagonist datum could not be added.")

	var/datum/species/original_species = ling_mob.dna?.species
	TEST_ASSERT_NOTNULL(original_species, "Test mob had no species to restore.")

	// Simulate hatching without running the full ritual.
	ling_antag.original_species = original_species
	ling_mob.set_species(/datum/species/shadow/shadowling)
	TEST_ASSERT(isshadowling(ling_mob), "Mob did not become a Shadowling before removal.")

	ling_mob.mind.remove_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT(!isshadowling(ling_mob), "Mob kept the Shadowling species after the antagonist was removed.")
	TEST_ASSERT_EQUAL(ling_mob.dna?.species, original_species, "Mob did not return to its original species after removal.")

/// Regression test for on_body_transfer, which used to leave the new body human and the
/// old body a Shadowling when a mind changed bodies.
/datum/unit_test/shadowling_body_transfer_keeps_form
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_body_transfer_keeps_form/Run()
	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	old_body.mind_initialize()
	old_body.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = old_body.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT_NOTNULL(ling_antag, "Shadowling antagonist datum could not be added.")

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	TEST_ASSERT_NOTNULL(hive, "Shadowling hive team was not created.")

	var/datum/species/original_species = old_body.dna?.species
	TEST_ASSERT_NOTNULL(original_species, "Test mob had no species to capture.")

	// Simulate hatching without running the full ritual.
	ling_antag.original_species = original_species
	old_body.set_species(/datum/species/shadow/shadowling)
	TEST_ASSERT(isshadowling(old_body), "Old body did not become a Shadowling before the transfer.")
	TEST_ASSERT(old_body in hive.lings, "Old body was not registered in hive.lings.")

	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	TEST_ASSERT(!isshadowling(new_body), "New body was already a Shadowling before the transfer.")

	old_body.mind.transfer_to(new_body)

	TEST_ASSERT_EQUAL(new_body.mind, ling_antag.owner, "Mind did not end up in the new body.")
	TEST_ASSERT_EQUAL(new_body.mind.has_antag_datum(/datum/antagonist/shadowling), ling_antag, "Antagonist datum was not carried over to the new body.")
	TEST_ASSERT(isshadowling(new_body), "New body did not inherit the Shadowling species.")
	TEST_ASSERT(!isshadowling(old_body), "Old body kept the Shadowling species after the transfer.")
	TEST_ASSERT_EQUAL(old_body.dna?.species, original_species, "Old body did not revert to its original species.")
	TEST_ASSERT(new_body in hive.lings, "New body was not registered in hive.lings.")
	TEST_ASSERT(!(old_body in hive.lings), "Old body was not removed from hive.lings.")

/// Stateful regression test covering unhatched -> hatched -> threshold unlocks -> ascension -> removal cleanup.
/datum/unit_test/shadowling_progression_lifecycle
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_progression_lifecycle/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/species/initial_species = ling_mob.dna?.species
	var/initial_max_health = ling_mob.maxHealth
	TEST_ASSERT_NOTNULL(initial_species, "Test mob had no initial species.")

	// 1) Unhatched shadowling only receives hatch & commune, not innate/threshold/ascended abilities.
	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT_NOTNULL(ling_antag, "Shadowling antagonist datum could not be added.")

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive
	TEST_ASSERT_NOTNULL(hive, "Shadowling hive was not created.")

	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/hatch) in ling_mob.actions, "Unhatched shadowling did not receive hatch.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/commune) in ling_mob.actions, "Unhatched shadowling did not receive commune.")
	for(var/forbidden_path in list(
		/datum/action/cooldown/shadowling/glare,
		/datum/action/cooldown/shadowling/veil,
		/datum/action/cooldown/shadowling/enthrall,
		/datum/action/cooldown/shadowling/recuperation,
		/datum/action/cooldown/shadowling/election,
		/datum/action/cooldown/shadowling/toggle_night_vision,
		/datum/action/cooldown/shadowling/shadow_phase,
		/datum/action/cooldown/shadowling/cold_wave,
		/datum/action/cooldown/shadowling/shadow_barrier,
		/datum/action/cooldown/shadowling/shreek,
		/datum/action/cooldown/shadowling/labyrinth,
		/datum/action/cooldown/shadowling/ascend,
		/datum/action/cooldown/shadowling/shadow_strike,
		/datum/action/cooldown/shadowling/root,
	))
		TEST_ASSERT_NULL(locate(forbidden_path) in ling_mob.actions, "Unhatched shadowling unexpectedly received [forbidden_path].")

	// Set a 20-crew baseline (50% = 10 thralls needed) so threshold percentages map cleanly to thrall counts.
	var/datum/objective/shadowling/enslave_fraction/enslave_obj = locate(/datum/objective/shadowling/enslave_fraction) in hive.objectives
	TEST_ASSERT_NOTNULL(enslave_obj, "Hive did not create an enslave_fraction objective.")
	enslave_obj.baseline_population = 20
	enslave_obj.percent = 50
	hive.refresh_ascension_thralls_needed()
	TEST_ASSERT_EQUAL(hive.get_ascension_thralls_needed(), 10, "Expected 10 thralls needed for ascension.")

	// 2) Hatching swaps to /datum/species/shadow/shadowling and sync_hive() grants SL_INNATE spells.
	ling_antag.original_species = initial_species
	ling_mob.set_species(/datum/species/shadow/shadowling)
	hive.sync_hive(ling_mob)
	TEST_ASSERT(isshadowling(ling_mob), "Mob did not become Shadowling species after hatching.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/hatch) in ling_mob.actions, "Hatch action remained after hatching sync.")

	for(var/innate_path in list(
		/datum/action/cooldown/shadowling/commune,
		/datum/action/cooldown/shadowling/glare,
		/datum/action/cooldown/shadowling/veil,
		/datum/action/cooldown/shadowling/enthrall,
		/datum/action/cooldown/shadowling/recuperation,
		/datum/action/cooldown/shadowling/election,
		/datum/action/cooldown/shadowling/toggle_night_vision,
	))
		TEST_ASSERT_NOTNULL(locate(innate_path) in ling_mob.actions, "Hatched shadowling was not granted innate ability [innate_path].")

	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/shadow_phase) in ling_mob.actions, "Shadow Phase unlocked at 0 thralls.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/ascend) in ling_mob.actions, "Ascension unlocked at 0 thralls.")

	// 3) Adding living thralls advances max_thralls_reached and unlocks threshold spells progressively.
	var/list/mob/living/carbon/human/thralls = list()
	for(var/i in 1 to 10)
		var/mob/living/carbon/human/thrall = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
		thrall.mind_initialize()
		thrall.mock_client = new()
		var/obj/item/organ/brain/shadow/tumor_thrall/tumor = new
		TEST_ASSERT(tumor.Insert(thrall), "Failed to insert thrall tumor #[i].")
		thralls += thrall

		hive.sync_hive(ling_mob)
		TEST_ASSERT_EQUAL(hive.max_thralls_reached, i, "max_thralls_reached did not advance to [i].")

		if(i == 2)
			TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/shadow_phase) in ling_mob.actions, "Shadow Phase did not unlock at 2 thralls (15% of 10).")
			TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/cold_wave) in ling_mob.actions, "Glacial Wave unlocked too early at 2 thralls.")
		if(i == 3)
			TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/cold_wave) in ling_mob.actions, "Glacial Wave did not unlock at 3 thralls (30% of 10).")
			TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/shadow_barrier) in ling_mob.actions, "Shadow Barrier did not unlock at 3 thralls (30% of 10).")
		if(i == 4)
			TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/shreek) in ling_mob.actions, "Sonic Shriek did not unlock at 4 thralls (40% of 10).")
		if(i == 6)
			TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/labyrinth) in ling_mob.actions, "Labyrinth did not unlock at 6 thralls (60% of 10).")
			TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/ascend) in ling_mob.actions, "Ascension unlocked too early at 6 thralls.")

	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/ascend) in ling_mob.actions, "Ascension did not unlock at 10 thralls (100% of 10).")

	// High-water mark persists even if a thrall dies.
	thralls[1].death()
	hive.sync_hive(ling_mob)
	TEST_ASSERT_EQUAL(hive.count_alive_thralls(), 9, "Living thrall count did not decrease after death.")
	TEST_ASSERT_EQUAL(hive.max_thralls_reached, 10, "max_thralls_reached dropped when a thrall died.")

	// 4) Ascending swaps to /datum/species/shadow/shadowling/ascended, grants SL_ASCENDED,
	// removes hatch/ascend/election, and grants stamina immunity.
	ling_antag.set_higher(TRUE)
	hive.sync_hive(ling_mob)

	TEST_ASSERT(isshadowling_ascended(ling_mob), "Shadowling did not swap to ascended species.")
	TEST_ASSERT(ling_antag.is_ascended, "Shadowling datum did not mark is_ascended.")
	TEST_ASSERT(hive.is_ascended, "Hive did not mark is_ascended.")
	TEST_ASSERT_EQUAL(ling_mob.maxHealth, SHADOWLING_ASCENDED_MAX_HEALTH, "Ascended Shadowling did not gain ascended maxHealth.")

	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/shadow_strike) in ling_mob.actions, "Ascended Shadowling did not receive shadow_strike.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/root) in ling_mob.actions, "Ascended Shadowling did not receive root.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/hatch) in ling_mob.actions, "Ascended Shadowling retained hatch.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/ascend) in ling_mob.actions, "Ascended Shadowling retained ascend.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/election) in ling_mob.actions, "Ascended Shadowling retained election.")

	ling_mob.adjust_stamina_loss(50)
	TEST_ASSERT_EQUAL(ling_mob.get_stamina_loss(), 0, "Ascended Shadowling took stamina damage despite COMSIG_LIVING_ADJUST_STAMINA_DAMAGE immunity.")

	// 5) Removal cleans up species, maxHealth, abilities, stamina immunity, and hive membership.
	ling_mob.mind.remove_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT(!isshadowling(ling_mob) && !isshadowling_ascended(ling_mob), "Shadowling species was not reverted on removal.")
	TEST_ASSERT_EQUAL(ling_mob.dna?.species, initial_species, "Original species was not restored on removal.")
	TEST_ASSERT_EQUAL(ling_mob.maxHealth, initial_max_health, "Original maxHealth was not restored on removal.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling) in ling_mob.actions, "Shadowling abilities remained after removal.")
	TEST_ASSERT(!(ling_mob in hive.lings), "Mob remained in hive.lings after removal.")
	TEST_ASSERT(!(ling_mob.mind in hive.members), "Mind remained in hive.members after removal.")

	ling_mob.adjust_stamina_loss(25)
	TEST_ASSERT(ling_mob.get_stamina_loss() > 0, "Mob retained stamina immunity after Shadowling removal.")

/// Regression test for enthrall fail_ritual() rolling back drained oxygen and target lock trait.
/datum/unit_test/shadowling_enthrall_rollback
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_enthrall_rollback/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	victim.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/action/cooldown/shadowling/enthrall/enthrall_action = new
	enthrall_action.Grant(ling_mob)

	ADD_TRAIT(victim, TRAIT_BEING_ENTHRALLED, REF(enthrall_action))
	victim.adjust_oxy_loss(35)
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_BEING_ENTHRALLED), "Target did not receive TRAIT_BEING_ENTHRALLED.")
	TEST_ASSERT(victim.get_oxy_loss() > 0, "Target did not take initial oxygen drain.")

	var/result = enthrall_action.fail_ritual(ling_mob, victim, "Interrupted", 35)
	TEST_ASSERT(!result, "fail_ritual() should return FALSE.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_BEING_ENTHRALLED), "fail_ritual() did not clear TRAIT_BEING_ENTHRALLED.")
	TEST_ASSERT_EQUAL(victim.get_oxy_loss(), 0, "fail_ritual() did not restore drained oxygen.")

	qdel(enthrall_action)

// MARK: Audit Regression Tests

/// Verifies Shadow Phase Activate() returns TRUE, blocks double-cast spam, enters phased dummy, and exits into cooldown.
/datum/unit_test/shadowling_shadow_phase_lifecycle
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_shadow_phase_lifecycle/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	ling_antag.original_species = ling_mob.dna?.species
	ling_mob.set_species(/datum/species/shadow/shadowling)

	var/datum/action/cooldown/shadowling/shadow_phase/phase_action = new
	phase_action.Grant(ling_mob)

	var/activated = phase_action.Activate(ling_mob)
	TEST_ASSERT(activated, "Shadow Phase Activate() did not return TRUE.")
	TEST_ASSERT(phase_action.entering, "Shadow Phase did not set entering lock during fade-out.")
	TEST_ASSERT(!phase_action.enter_phase(ling_mob), "Shadow Phase allowed double-cast while entering.")

	phase_action.finish_enter_phase(WEAKREF(ling_mob), WEAKREF(get_turf(ling_mob)))
	TEST_ASSERT(!phase_action.entering, "Shadow Phase did not clear entering lock after finish_enter_phase.")
	TEST_ASSERT(istype(ling_mob.loc, /obj/effect/dummy/phased_mob/shadowling), "Shadowling did not enter phased dummy.")

	var/exited = phase_action.Activate(ling_mob)
	TEST_ASSERT(exited, "Shadow Phase exit Activate() did not return TRUE.")
	TEST_ASSERT(!istype(ling_mob.loc, /obj/effect/dummy/phased_mob/shadowling), "Shadowling stayed inside phased dummy after exit.")
	TEST_ASSERT(phase_action.next_use_time > world.time, "Shadow Phase did not enter cooldown after exit.")

/// Verifies Labyrinth leaves click_intercept cleared when no valid target is found.
/datum/unit_test/shadowling_labyrinth_no_target_cleanup
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_labyrinth_no_target_cleanup/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	ling_mob.set_species(/datum/species/shadow/shadowling)

	var/datum/action/cooldown/shadowling/labyrinth/lab_action = new
	lab_action.Grant(ling_mob)

	var/triggered = lab_action.Trigger(ling_mob)
	TEST_ASSERT(!triggered, "Labyrinth Trigger() should return FALSE when no targets are present.")
	TEST_ASSERT_NULL(ling_mob.click_intercept, "Labyrinth left click_intercept armed with no target.")
	TEST_ASSERT_NULL(lab_action.stored_target, "Labyrinth stored_target was unexpectedly populated.")

/// Verifies mid-channel ritual qdel/Remove cleans up alpha, walls, cover, enthrall traits, and hive.is_ascending.
/datum/unit_test/shadowling_ritual_midchannel_cleanup
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_ritual_midchannel_cleanup/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	victim.mind_initialize()
	ling_mob.mock_client = new()
	ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)

	var/datum/team/shadow_hive/hive = GLOB.shadowling_hive

	// 1) Hatch mid-channel Remove() cleanup
	var/datum/action/cooldown/shadowling/hatch/hatch_action = locate(/datum/action/cooldown/shadowling/hatch) in ling_mob.actions
	TEST_ASSERT_NOTNULL(hatch_action, "Hatch action missing.")
	hatch_action.channeling = TRUE
	hatch_action.channel_caster = ling_mob
	hatch_action.prev_alpha = 255
	ling_mob.alpha = 0
	hatch_action.attach_cover()
	hatch_action.walls = hatch_action.build_ring_walls(get_turf(ling_mob))
	hatch_action.Remove(ling_mob)
	TEST_ASSERT(!hatch_action.channeling, "Hatch did not clear channeling on Remove().")
	TEST_ASSERT_NULL(hatch_action.cover, "Hatch did not detach cover on Remove().")
	TEST_ASSERT_NULL(hatch_action.walls, "Hatch did not clean up walls on Remove().")
	TEST_ASSERT_EQUAL(ling_mob.alpha, 255, "Hatch did not restore alpha on Remove().")
	qdel(hatch_action)

	// 2) Ascend mid-channel qdel() cleanup
	var/datum/action/cooldown/shadowling/ascend/asc_action = new
	asc_action.Grant(ling_mob)
	asc_action.channeling = TRUE
	asc_action.channel_caster = ling_mob
	asc_action.channel_hive = hive
	hive.is_ascending = TRUE
	qdel(asc_action)
	TEST_ASSERT(!hive.is_ascending, "Ascend did not clear hive.is_ascending on qdel().")

	// 3) Enthrall mid-channel qdel() cleanup
	var/datum/action/cooldown/shadowling/enthrall/ent_action = new
	ent_action.Grant(ling_mob)
	ent_action.channeling = TRUE
	ent_action.channel_caster = ling_mob
	ent_action.channel_target = victim
	ent_action.channel_drained_oxy = 35
	ADD_TRAIT(victim, TRAIT_BEING_ENTHRALLED, REF(ent_action))
	victim.adjust_oxy_loss(35)
	qdel(ent_action)
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_BEING_ENTHRALLED), "Enthrall did not clear TRAIT_BEING_ENTHRALLED on qdel().")
	TEST_ASSERT_EQUAL(victim.get_oxy_loss(), 0, "Enthrall did not restore drained oxygen on qdel().")

/// Verifies get_hive() clears deleted shadow_team references and recreates GLOB.shadowling_hive cleanly.
/datum/unit_test/shadowling_deleted_hive_resilience
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_deleted_hive_resilience/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	var/datum/team/shadow_hive/old_hive = ling_antag.get_hive()
	TEST_ASSERT_NOTNULL(old_hive, "get_hive() returned null.")

	qdel(old_hive)
	TEST_ASSERT(QDELETED(old_hive), "Old hive was not qdeleted.")

	var/datum/team/shadow_hive/new_hive = ling_antag.get_hive()
	TEST_ASSERT_NOTNULL(new_hive, "get_hive() failed to recreate deleted hive.")
	TEST_ASSERT(!QDELETED(new_hive), "get_hive() returned a deleted hive.")
	TEST_ASSERT_NOTEQUAL(new_hive, old_hive, "get_hive() returned stale deleted hive pointer.")
	TEST_ASSERT_EQUAL(new_hive, GLOB.shadowling_hive, "GLOB.shadowling_hive was not updated to recreated hive.")

/// Verifies admin_convert_lesser properly demotes an Ascended Shadowling without leaking SL_ASCENDED abilities.
/datum/unit_test/shadowling_admin_convert_lesser_ascended
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_admin_convert_lesser_ascended/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	var/datum/team/shadow_hive/hive = ling_antag.get_hive()
	ling_antag.set_higher(TRUE)
	hive.sync_hive(ling_mob)
	TEST_ASSERT(isshadowling_ascended(ling_mob), "Shadowling did not ascend before demotion test.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/shadow_strike) in ling_mob.actions, "Ascended Shadowling did not gain shadow_strike.")

	hive.convert_to_lesser(ling_mob)
	TEST_ASSERT(!ling_antag.is_ascended, "Demoted Shadowling retained is_ascended.")
	TEST_ASSERT(isshadowling(ling_mob) && !isshadowling_ascended(ling_mob), "Demoted Shadowling did not revert to hatched Shadowling species.")
	TEST_ASSERT_EQUAL(ling_antag.ling_role, SHADOWLING_ROLE_LESSER, "Demoted Shadowling did not gain SHADOWLING_ROLE_LESSER.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/shadow_strike) in ling_mob.actions, "Demoted Lesser Shadowling retained ascended shadow_strike.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/glare) in ling_mob.actions, "Demoted Lesser Shadowling did not receive SL_LESSER glare.")

/// Verifies on_body_transfer on an unhatched Shadowling keeps them unhatched and strips old_body actions.
/datum/unit_test/shadowling_unhatched_body_transfer
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_unhatched_body_transfer/Run()
	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	old_body.mind_initialize()
	old_body.mock_client = new()

	old_body.mind.add_antag_datum(/datum/antagonist/shadowling)
	TEST_ASSERT(!isshadowling(old_body), "Old body hatched prematurely.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/hatch) in old_body.actions, "Old body missing hatch action.")

	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	old_body.mind.transfer_to(new_body)

	TEST_ASSERT(!isshadowling(new_body) && !isshadowling_ascended(new_body), "Unhatched Shadowling auto-hatched on body transfer.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling) in old_body.actions, "Old body retained Shadowling actions after body transfer.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/hatch) in new_body.actions, "New body did not receive hatch action after body transfer.")

/// Verifies ui_act("sync") requires conscious state and enforces its 3-second cooldown.
/datum/unit_test/shadowling_ui_sync_guard_and_cooldown
	parent_type = /datum/unit_test/shadowling_base

/datum/unit_test/shadowling_ui_sync_guard_and_cooldown/Run()
	var/mob/living/carbon/human/ling_mob = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	ling_mob.mind_initialize()
	ling_mob.mock_client = new()

	var/datum/antagonist/shadowling/ling_antag = ling_mob.mind.add_antag_datum(/datum/antagonist/shadowling)
	ling_mob.set_species(/datum/species/shadow/shadowling)
	var/datum/tgui/fake_ui = new(ling_mob, ling_antag, ling_antag.ui_name)

	ling_mob.death()
	ling_antag.ui_act("sync", list(), fake_ui, null)
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/shadowling/glare) in ling_mob.actions, "Dead Shadowling was allowed to sync via ui_act.")

	ling_mob.revive(HEAL_DAMAGE|HEAL_BODY|HEAL_STATUS|HEAL_CC_STATUS)
	ling_antag.ui_act("sync", list(), fake_ui, null)
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/shadowling/glare) in ling_mob.actions, "Conscious Shadowling failed to sync via ui_act.")
	TEST_ASSERT(!COOLDOWN_FINISHED(ling_antag, sync_cooldown), "ui_act('sync') did not start sync_cooldown.")

	qdel(fake_ui)
