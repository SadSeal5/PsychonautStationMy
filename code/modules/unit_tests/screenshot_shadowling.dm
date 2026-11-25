/// Renders directional screenshots for hatched and Ascended Shadowling species.
/datum/unit_test/screenshot_shadowling

/datum/unit_test/screenshot_shadowling/Run()
	var/mob/living/carbon/human/dummy/consistent/shadowling = allocate(/mob/living/carbon/human/dummy/consistent)
	shadowling.set_species(/datum/species/shadow/shadowling)
	test_screenshot("[/datum/species/shadow/shadowling]", get_flat_icon_for_all_directions(shadowling))

	var/mob/living/carbon/human/dummy/consistent/ascended = allocate(/mob/living/carbon/human/dummy/consistent)
	ascended.set_species(/datum/species/shadow/shadowling/ascended)
	test_screenshot("[/datum/species/shadow/shadowling/ascended]", get_flat_icon_for_all_directions(ascended))
