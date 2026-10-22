GLOBAL_LIST_INIT(dreamweaver_names, list(
	"Morpheus",
	"Oneiros",
	"Phantasos",
	"Hypnos",
	"Somnus",
	"Phobetor",
	"Ikelos",
	"Rüyagezen",
	"Düşören",
	"Zihinbüken",
))

/datum/species/shadow/dreamweaver
	name = "Dreamweaver"
	id = SPECIES_DREAMWEAVER
	examine_limb_id = SPECIES_SHADOW
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE
	no_equip_flags = ITEM_SLOT_MASK | ITEM_SLOT_OCLOTHING | ITEM_SLOT_GLOVES | ITEM_SLOT_FEET | ITEM_SLOT_ICLOTHING | ITEM_SLOT_SUITSTORE
	inherent_traits = list(
		TRAIT_NO_UNDERWEAR,
		TRAIT_RESISTCOLD,
		TRAIT_NOBREATH,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_NO_DNA_COPY,
		TRAIT_NOBLOOD,
		TRAIT_VIRUSIMMUNE,
	)

	mutantbrain = /obj/item/organ/brain/shadow/dreamweaver
	mutantheart = /obj/item/organ/heart
	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/shadow,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/shadow,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/shadow,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/shadow,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/shadow,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/shadow,
	)

/datum/species/shadow/dreamweaver/on_species_gain(mob/living/carbon/human/C, datum/species/old_species, pref_load, regenerate_icons = TRUE, replace_missing = TRUE)
	. = ..()
	C.fully_replace_character_name(null, pick(GLOB.dreamweaver_names))

/datum/species/shadow/dreamweaver/check_roundstart_eligible()
	return FALSE
