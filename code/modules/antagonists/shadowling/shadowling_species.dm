// MARK: Species
/// Hatched Shadowling species with shadow bodyparts, nyxosynthesis healing, and light vulnerability.
/datum/species/shadow/shadowling
	name = "Shadowling"
	plural_form = "Shadowlings"
	id = SPECIES_SHADOWLING

	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/shadow/shadowling,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/shadow/shadowling,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/shadow/shadowling,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/shadow/shadowling,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/shadow/shadowling,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/shadow/shadowling,
	)

	inherent_traits = list(SHADOWLING_BASE_TRAITS)

	no_equip_flags = ITEM_SLOT_MASK | ITEM_SLOT_HEAD | ITEM_SLOT_EYES | ITEM_SLOT_OCLOTHING | ITEM_SLOT_GLOVES | ITEM_SLOT_FEET | ITEM_SLOT_ICLOTHING | ITEM_SLOT_SUITSTORE
	mutantbrain = /obj/item/organ/brain/shadow/shadowling
	mutanteyes = /obj/item/organ/eyes/shadow/shadowling

/// Ascended Shadowling species granting higher max health, umbral claws, and stamina immunity.
/datum/species/shadow/shadowling/ascended
	name = "Ascended Shadowling"
	id = SPECIES_SHADOWLING_ASCENDED
	changesource_flags = ~(MIRROR_MAGIC | MIRROR_PRIDE)
	no_equip_flags = ITEM_SLOT_MASK | ITEM_SLOT_HEAD | ITEM_SLOT_EYES | ITEM_SLOT_OCLOTHING | ITEM_SLOT_GLOVES | ITEM_SLOT_FEET | ITEM_SLOT_ICLOTHING | ITEM_SLOT_SUITSTORE | ITEM_SLOT_LPOCKET | ITEM_SLOT_RPOCKET | ITEM_SLOT_BELT | ITEM_SLOT_EARS | ITEM_SLOT_NECK | ITEM_SLOT_BACK | ITEM_SLOT_ID
	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/shadow/shadowling/ascended,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/shadow/shadowling/ascended,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/shadow/shadowling/ascended,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/shadow/shadowling/ascended,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/shadow/shadowling/ascended,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/shadow/shadowling/ascended,
	)

	inherent_traits = list(SHADOWLING_BASE_TRAITS SHADOWLING_ASCENDED_EXTRA_TRAITS)

/datum/species/shadow/shadowling/check_roundstart_eligible()
	return FALSE

/// Sets ascended max health, heals damage, registers stamina immunity, and equips umbral claws.
/datum/species/shadow/shadowling/ascended/on_species_gain(mob/living/carbon/human/H)
	. = ..()
	if(!istype(H))
		return
	H.setMaxHealth(SHADOWLING_ASCENDED_MAX_HEALTH)
	H.heal_overall_damage()
	RegisterSignal(H, COMSIG_LIVING_ADJUST_STAMINA_DAMAGE, PROC_REF(on_adjust_stamina_damage))
	shadowling_equip_ascended_claws(H)

/// Unregisters stamina immunity and destroys equipped umbral claws on species loss.
/datum/species/shadow/shadowling/ascended/on_species_loss(mob/living/carbon/human/H, datum/species/new_species)
	. = ..()
	if(!istype(H))
		return
	UnregisterSignal(H, COMSIG_LIVING_ADJUST_STAMINA_DAMAGE)
	shadowling_remove_ascended_claws(H)

/// Signal handler blocking positive stamina damage on Ascended Shadowlings.
/datum/species/shadow/shadowling/ascended/proc/on_adjust_stamina_damage(datum/source, type, amount, forced)
	SIGNAL_HANDLER
	if(amount > 0)
		return COMPONENT_IGNORE_CHANGE

/// Equips left and right nodrop umbral claws into [H]'s hands.
/datum/species/shadow/shadowling/ascended/proc/shadowling_equip_ascended_claws(mob/living/carbon/human/H)
	if(!istype(H))
		return

	var/obj/item/knife/combat/umbral_claw/left/claw_l = new(H)
	var/obj/item/knife/combat/umbral_claw/claw_r = new(H)

	H.drop_all_held_items()

	if(!H.put_in_l_hand(claw_l))
		H.dropItemToGround(claw_l, TRUE)
	if(!H.put_in_r_hand(claw_r))
		H.dropItemToGround(claw_r, TRUE)

/// Removes all umbral claws contained on [H].
/datum/species/shadow/shadowling/ascended/proc/shadowling_remove_ascended_claws(mob/living/carbon/human/H)
	if(!istype(H))
		return
	for(var/obj/item/knife/combat/umbral_claw/C in H.get_all_contents())
		qdel(C)

// MARK: Mob Helpers
/// Cleanses human quirk datums when transforming into a Shadowling.
/mob/living/carbon/human/proc/shadowling_strip_quirks()
	cleanse_quirk_datums()

/// Forces an update of eye overlays after species transformation.
/mob/living/carbon/human/proc/refresh_eye_overlays()
	update_eyes(TRUE)

/// Replaces robotic limbs and organs with organic/shadow equivalents before transformation.
/mob/living/carbon/human/proc/reset_robotic_limbs()
	for(var/zone in GLOB.all_body_zones)
		var/obj/item/bodypart/B = get_bodypart(zone)
		if(!B || !(B.bodytype & BODYTYPE_ROBOTIC))
			continue
		reset_to_original_bodypart(zone)
	var/list/robotic_organs = list()
	for(var/slot in organs_slot)
		var/obj/item/organ/O = organs_slot[slot]
		if(!O || !IS_ROBOTIC_ORGAN(O))
			continue
		robotic_organs += O
	for(var/obj/item/organ/O in robotic_organs)
		if(QDELETED(O))
			continue
		if(O.slot == ORGAN_SLOT_BRAIN)
			var/obj/item/organ/brain/shadow/shadowling/new_brain = new
			new_brain.replace_into(src)
			continue
		O.mob_remove(src, special = TRUE)
		QDEL_NULL(O)
	dna.species.regenerate_organs(src, dna.species, replace_missing = TRUE)

// MARK: Claws

/// Permanent nodrop right-hand slashing melee weapon equipped by Ascended Shadowlings.
/obj/item/knife/combat/umbral_claw
	name = "umbral claw (slash)"
	desc = "Jagged shadowy claws."
	icon = 'icons/mob/antagonists/shadowling/shadowling_objects.dmi'
	icon_state = "claw_right"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	inhand_icon_state = "nothing"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = INDESTRUCTIBLE
	force = 27
	wound_bonus = 20
	exposed_wound_bonus = 10
	armour_penetration = 25
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("tears into", "slashes", "rends")
	attack_verb_simple = list("tear into", "slash", "rend")
	hitsound = 'sound/items/weapons/slash.ogg'
	item_flags = DROPDEL

/obj/item/knife/combat/umbral_claw/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, INNATE_TRAIT)

/// Permanent nodrop left-hand piercing melee weapon equipped by Ascended Shadowlings.
/obj/item/knife/combat/umbral_claw/left
	name = "umbral claw (pierce)"
	desc = "Piercing shadowy claws."
	icon_state = "claw_left"
	sharpness = SHARP_POINTY
	attack_verb_continuous = list("pierces", "impales", "tears into")
	attack_verb_simple = list("pierce", "impale", "tear into")

// MARK: Bodyparts

#define SHADOWLING_BODYPART_COMMON \
	icon = 'icons/mob/antagonists/shadowling/shadowling.dmi'; \
	should_draw_greyscale = FALSE; \
	limb_id = SPECIES_SHADOWLING; \
	biological_state = BIO_INORGANIC; \
	bodytype = BODYTYPE_ORGANIC | BODYTYPE_SHADOW; \
	icon_static = 'icons/mob/antagonists/shadowling/shadowling.dmi'; \
	bodypart_effects = list(/datum/status_effect/grouped/bodypart_effect/nyxosynthesis/shadowling); \
	burn_modifier = 1.5; \
	brute_modifier = 0.7

#define SHADOWLING_ASCENDED_BODYPART_COMMON \
	icon = 'icons/mob/antagonists/shadowling/shadowling_ascended.dmi'; \
	should_draw_greyscale = FALSE; \
	limb_id = SPECIES_SHADOWLING_ASCENDED; \
	bodytype = BODYTYPE_ORGANIC | BODYTYPE_SHADOW; \
	icon_static = 'icons/mob/antagonists/shadowling/shadowling_ascended.dmi'; \
	burn_modifier = 0.5; \
	brute_modifier = 0.5

/// Shadowling head bodypart with nyxosynthesis effect and glowing eye sprite support.
/obj/item/bodypart/head/shadow/shadowling
	SHADOWLING_BODYPART_COMMON
	head_flags = HEAD_EYESPRITES

/// Shadowling chest bodypart disabling jumpsuits and taking increased burn/reduced brute.
/obj/item/bodypart/chest/shadow/shadowling
	SHADOWLING_BODYPART_COMMON
	bodypart_traits = list(TRAIT_NO_JUMPSUIT)

/// Shadowling left leg bodypart.
/obj/item/bodypart/leg/left/shadow/shadowling
	SHADOWLING_BODYPART_COMMON

/// Shadowling right leg bodypart.
/obj/item/bodypart/leg/right/shadow/shadowling
	SHADOWLING_BODYPART_COMMON

/// Shadowling left arm bodypart with slashing unarmed claw attacks.
/obj/item/bodypart/arm/left/shadow/shadowling
	SHADOWLING_BODYPART_COMMON
	unarmed_attack_verbs = list("slash", "claw", "scratch")
	unarmed_attack_verbs_continuous = list("slashes", "claws", "scratches")
	grappled_attack_verb = "lacerate"
	grappled_attack_verb_continuous = "lacerates"
	unarmed_attack_effect = ATTACK_EFFECT_CLAW
	unarmed_attack_sound = 'sound/items/weapons/slash.ogg'
	unarmed_miss_sound = 'sound/items/weapons/slashmiss.ogg'
	unarmed_damage_low = 5
	unarmed_damage_high = 14
	unarmed_effectiveness = 20
	unarmed_sharpness = SHARP_EDGED
	bodypart_traits = list(TRAIT_CHUNKYFINGERS)

/// Shadowling right arm bodypart with piercing unarmed claw attacks.
/obj/item/bodypart/arm/right/shadow/shadowling
	SHADOWLING_BODYPART_COMMON
	unarmed_attack_verbs = list("pierce", "impale", "stab")
	unarmed_attack_verbs_continuous = list("pierces", "impales", "stabs")
	grappled_attack_verb = "pierce"
	grappled_attack_verb_continuous = "pierces"
	unarmed_attack_effect = ATTACK_EFFECT_CLAW
	unarmed_attack_sound = 'sound/items/weapons/slash.ogg'
	unarmed_miss_sound = 'sound/items/weapons/slashmiss.ogg'
	unarmed_damage_low = 8
	unarmed_damage_high = 20
	unarmed_effectiveness = 35
	unarmed_sharpness = SHARP_POINTY
	bodypart_traits = list(TRAIT_CHUNKYFINGERS)

/// Ascended Shadowling head bodypart with halved brute and burn vulnerability.
/obj/item/bodypart/head/shadow/shadowling/ascended
	SHADOWLING_ASCENDED_BODYPART_COMMON
	head_flags = NONE

/// Ascended Shadowling chest bodypart.
/obj/item/bodypart/chest/shadow/shadowling/ascended
	SHADOWLING_ASCENDED_BODYPART_COMMON

/// Ascended Shadowling left leg bodypart.
/obj/item/bodypart/leg/left/shadow/shadowling/ascended
	SHADOWLING_ASCENDED_BODYPART_COMMON

/// Ascended Shadowling right leg bodypart.
/obj/item/bodypart/leg/right/shadow/shadowling/ascended
	SHADOWLING_ASCENDED_BODYPART_COMMON

/// Ascended Shadowling left arm bodypart.
/obj/item/bodypart/arm/left/shadow/shadowling/ascended
	SHADOWLING_ASCENDED_BODYPART_COMMON

/// Ascended Shadowling right arm bodypart.
/obj/item/bodypart/arm/right/shadow/shadowling/ascended
	SHADOWLING_ASCENDED_BODYPART_COMMON

#undef SHADOWLING_BODYPART_COMMON
#undef SHADOWLING_ASCENDED_BODYPART_COMMON

// MARK: Organs

/// Placeholder shadow brain organ variant assigned to hatched Shadowlings.
/obj/item/organ/brain/shadow/shadowling
	name = "shadowling swarm tumor"

/// Shadowling eyes granting thermal vision, living-invisibility detection, and flash sensitivity.
/obj/item/organ/eyes/shadow/shadowling
	name = "freezing blue eyes"
	desc = "Even without their shadowy owner, looking at these eyes gives you a sense of dread."
	icon = 'icons/obj/medical/organs/shadow_organs.dmi'
	iris_overlay = null
	eye_icon_state = "eyes_glow_gs"
	eye_icon = 'icons/mob/human/human_eyes.dmi'
	organ_traits = list(TRAIT_THERMAL_VISION)
	pepperspray_protect = TRUE
	color_cutoffs = null
	flash_protect = FLASH_PROTECTION_SENSITIVE
	see_invisible = SEE_INVISIBLE_LIVING
	eye_color_left = "#ff0000"
	eye_color_right = "#ff0000"

/// Generates glowing eye overlays for hatched Shadowlings while hiding them on Ascended heads.
/obj/item/organ/eyes/shadow/shadowling/generate_body_overlay(obj/item/bodypart/head/my_head)
	if(istype(my_head, /obj/item/bodypart/head/shadow/shadowling/ascended) || isshadowling_ascended(my_head?.owner))
		return list()
	. = ..()
	if(!islist(.))
		return .

	for(var/mutable_appearance/ov as anything in .)
		if(!istype(ov))
			continue
		if(ov.icon != eye_icon)
			continue

		if(ov.icon_state == "[eye_icon_state]_l")
			ov.color = eye_color_left
			continue

		if(ov.icon_state == "[eye_icon_state]_r")
			ov.color = eye_color_right
			continue

	return .
