/// Tests Space Ninja setup blocking, loadout swapping, stealth cooldowns, dispenser caps, and MOD module paths.
/datum/unit_test/space_ninja_loadout

/datum/unit_test/space_ninja_loadout/Run()
	var/mob/living/carbon/human/consistent/ninja = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	ninja.mind_initialize()

	var/datum/antagonist/ninja/ninja_datum = ninja.mind.add_antag_datum(/datum/antagonist/ninja)
	TEST_ASSERT_NOTNULL(ninja_datum, "Failed to grant ninja antagonist datum.")
	TEST_ASSERT(ninja_datum.in_setup_phase, "Ninja did not enter setup phase on gain.")
	TEST_ASSERT(HAS_TRAIT(ninja, TRAIT_MUTE), "Ninja was not muted during setup phase.")

	var/obj/item/mod/control/mod = ninja.back
	TEST_ASSERT(istype(mod), "Ninja did not equip a MODsuit.")
	var/initial_active = mod.active
	TEST_ASSERT(!mod.toggle_activate(ninja), "MODsuit toggle_activate succeeded during setup phase.")
	TEST_ASSERT_EQUAL(mod.active, initial_active, "MODsuit active state changed during setup phase.")
	TEST_ASSERT(SEND_SIGNAL(mod, COMSIG_MOD_ACTIVATE, ninja) & MOD_CANCEL_ACTIVATE, "MODsuit activation signal was not cancelled during setup phase.")

	var/obj/item/mod/module/stealth/ninja/stealth_mod = locate() in mod.modules
	TEST_ASSERT_NOTNULL(stealth_mod, "Ninja MODsuit lacked stealth module.")
	TEST_ASSERT(SEND_SIGNAL(stealth_mod, COMSIG_MODULE_TRIGGERED, ninja) & MOD_ABORT_USE, "Module trigger was not blocked during setup phase.")
	stealth_mod.on_select(ninja)
	TEST_ASSERT(!stealth_mod.active, "Stealth module activated during setup phase.")

	ninja_datum.end_setup_phase()
	TEST_ASSERT(!ninja_datum.in_setup_phase, "Ninja remained in setup phase after end_setup_phase().")
	TEST_ASSERT(!HAS_TRAIT(ninja, TRAIT_MUTE), "Ninja remained muted after setup phase ended.")
	TEST_ASSERT(!(SEND_SIGNAL(mod, COMSIG_MOD_ACTIVATE, ninja) & MOD_CANCEL_ACTIVATE), "MODsuit remained setup-blocked after end_setup_phase().")

	var/list/expected_weapons = list(
		/obj/item/energy_katana,
		/obj/item/plasma_kusarigama,
		/obj/item/nanite_daggers,
	)
	var/list/expected_stars = list(
		/obj/item/mod/module/dispenser/ninja,
		/obj/item/mod/module/dispenser/ninja/kunai,
		/obj/item/mod/module/dispenser/ninja/venom,
	)
	var/list/expected_heals = list(
		/obj/item/mod/module/adrenaline_boost,
		/obj/item/mod/module/nanite_repair/ninja,
		/obj/item/mod/module/reflex_overdrive,
	)
	var/list/expected_traps = list(
		/obj/item/mod/module/energy_net,
		/obj/item/mod/module/hologram_decoy/ninja,
		/obj/item/mod/module/nanite_smoke,
	)

	var/obj/item/mod/module/weapon_recall/recall = locate() in mod.modules
	TEST_ASSERT_NOTNULL(recall, "Ninja MODsuit lacked weapon_recall module.")

	for(var/choice in 1 to 3)
		ninja_datum.start_setup_phase()
		ninja_datum.loadout_weapon = choice
		ninja_datum.loadout_star = choice
		ninja_datum.loadout_heal = choice
		ninja_datum.loadout_trap = choice
		ninja_datum.end_setup_phase()

		var/expected_weapon_type = expected_weapons[choice]
		var/obj/item/equipped_weapon = locate(expected_weapon_type) in ninja.get_all_contents()
		TEST_ASSERT_NOTNULL(equipped_weapon, "Loadout weapon [expected_weapon_type] was not equipped.")
		TEST_ASSERT_EQUAL(recall.linked_weapon, equipped_weapon, "weapon_recall did not link to [expected_weapon_type].")
		if(choice != 1)
			TEST_ASSERT_NULL(locate(/obj/item/energy_katana) in ninja.get_all_contents(), "Old energy katana remained after weapon swap.")
			TEST_ASSERT_NULL(locate(/obj/item/storage/belt/sheath/ninja) in ninja.get_all_contents(), "Old katana sheath remained after weapon swap.")

		TEST_ASSERT(mod.complexity <= mod.complexity_max, "MODsuit complexity [mod.complexity] exceeded max [mod.complexity_max] for choice [choice].")

		var/expected_star_type = expected_stars[choice]
		var/obj/item/mod/module/star_mod = locate(expected_star_type) in mod.modules
		TEST_ASSERT_NOTNULL(star_mod, "Star slot module [expected_star_type] missing.")
		TEST_ASSERT_NOTNULL(star_mod.pinned_to[REF(ninja)], "Star slot module [expected_star_type] was not pinned.")

		var/expected_heal_type = expected_heals[choice]
		var/obj/item/mod/module/heal_mod = locate(expected_heal_type) in mod.modules
		TEST_ASSERT_NOTNULL(heal_mod, "Heal slot module [expected_heal_type] missing.")
		TEST_ASSERT_NOTNULL(heal_mod.pinned_to[REF(ninja)], "Heal slot module [expected_heal_type] was not pinned.")

		var/expected_trap_type = expected_traps[choice]
		var/obj/item/mod/module/trap_mod = locate(expected_trap_type) in mod.modules
		TEST_ASSERT_NOTNULL(trap_mod, "Trap slot module [expected_trap_type] missing.")
		TEST_ASSERT_NOTNULL(trap_mod.pinned_to[REF(ninja)], "Trap slot module [expected_trap_type] was not pinned.")

	stealth_mod.on_deactivation(ninja, display_message = FALSE, deleting = FALSE)
	TEST_ASSERT(!COOLDOWN_FINISHED(stealth_mod, cooldown_timer), "stealth/ninja did not start cooldown on deactivation.")

	var/obj/item/mod/module/nanite_smoke/smoke_mod = locate() in mod.modules
	TEST_ASSERT_NOTNULL(smoke_mod, "Expected nanite_smoke module installed after choice 3.")
	smoke_mod.on_use(ninja)
	TEST_ASSERT(COOLDOWN_FINISHED(stealth_mod, cooldown_timer), "nanite_smoke did not reset stealth/ninja cooldown.")

	ninja_datum.loadout_star = 1
	ninja_datum.apply_loadout(ninja)
	var/obj/item/mod/module/dispenser/ninja/star_dispenser = locate() in mod.modules
	TEST_ASSERT_NOTNULL(star_dispenser, "Expected star dispenser installed.")
	TEST_ASSERT(star_dispenser.used(ninja), "First star dispense failed.")
	var/obj/item/first_star = ninja.get_active_held_item()
	TEST_ASSERT(istype(first_star, /obj/item/throwing_star/ninja/stamina), "First dispensed item was not energy throwing star.")
	first_star.item_flags &= ~DROPDEL
	first_star.forceMove(run_loc_floor_bottom_left)
	star_dispenser.start_cooldown(0)
	TEST_ASSERT(star_dispenser.used(ninja), "Second star dispense failed.")
	var/obj/item/second_star = ninja.get_active_held_item()
	TEST_ASSERT(istype(second_star, /obj/item/throwing_star/ninja/stamina), "Second dispensed item was not energy throwing star.")
	second_star.item_flags &= ~DROPDEL
	second_star.forceMove(run_loc_floor_bottom_left)
	star_dispenser.start_cooldown(0)
	TEST_ASSERT(!star_dispenser.used(ninja), "Dispenser exceeded max_active_projectiles cap of 2.")
	qdel(first_star)
	star_dispenser.start_cooldown(0)
	TEST_ASSERT(star_dispenser.used(ninja), "Dispenser did not free cap slot after projectile deletion.")
	qdel(second_star)
	var/obj/item/third_star = ninja.get_active_held_item()
	if(third_star)
		qdel(third_star)

	ninja_datum.loadout_star = 2
	ninja_datum.apply_loadout(ninja)
	var/obj/item/mod/module/dispenser/ninja/kunai/kunai_dispenser = locate() in mod.modules
	TEST_ASSERT_NOTNULL(kunai_dispenser, "Expected kunai dispenser installed.")
	TEST_ASSERT(kunai_dispenser.used(ninja), "First kunai dispense failed.")
	var/obj/item/first_kunai = ninja.get_active_held_item()
	TEST_ASSERT(istype(first_kunai, /obj/item/throwing_star/ninja/kunai), "Dispensed item was not grappling kunai.")
	first_kunai.item_flags &= ~DROPDEL
	first_kunai.forceMove(run_loc_floor_bottom_left)
	kunai_dispenser.start_cooldown(0)
	TEST_ASSERT(!kunai_dispenser.used(ninja), "Kunai dispenser exceeded max_active_projectiles cap of 1.")
	qdel(first_kunai)

	var/obj/item/mod/module/nanite_repair/abstract_repair = /obj/item/mod/module/nanite_repair
	TEST_ASSERT_EQUAL(initial(abstract_repair.abstract_type), /obj/item/mod/module/nanite_repair, "/obj/item/mod/module/nanite_repair must be abstract.")
	for(var/obj/item/mod/module/mod_path as anything in expected_stars + expected_heals + expected_traps)
		TEST_ASSERT_NOTEQUAL(initial(mod_path.abstract_type), mod_path, "Ninja loadout module [mod_path] must be concrete.")
