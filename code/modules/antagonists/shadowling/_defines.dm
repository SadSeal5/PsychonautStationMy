// MARK: Defines & Globals

/// Species id for hatched Shadowlings.
#define SPECIES_SHADOWLING "shadowling"
/// Species id for Ascended Shadowlings.
#define SPECIES_SHADOWLING_ASCENDED "shadowlingascended"
/// Organ slot holding the parasitic Shadow Thrall tumor.
#define ORGAN_SLOT_BRAIN_THRALL "brain_thrall_tumor"

/// Minimum turf lumcount considered bright light that burns Shadowlings.
#define SHADOWLING_LIGHT_THRESHOLD 0.4
/// Maximum turf lumcount considered dim/darkness for Shadowling healing and abilities.
#define SHADOWLING_DIM_THRESHOLD   0.2

/// Global singleton hive team coordinating all Shadowlings and Thralls.
GLOBAL_DATUM_INIT(shadowling_hive, /datum/team/shadow_hive, new)

/// Role identifier for full Shadowlings.
#define SHADOWLING_ROLE_MAIN "shadowling_main"
/// Role identifier for enthralled crewmembers.
#define SHADOWLING_ROLE_THRALL "shadowling_thrall"
/// Role identifier for elevated Lesser Shadowlings.
#define SHADOWLING_ROLE_LESSER "shadowling_lesser"

// Light DAMAGE modifiers
#define SHADOWLING_BRIGHT_BURN_PER_LIMB 3.5
#define SHADOWLING_BRIGHT_BRUTE_PER_LIMB 3.5
// Dark HEALING modifiers
#define SHADOWLING_DARK_HEAL_PER_LIMB_DEEP 4
#define SHADOWLING_DARK_HEAL_PER_LIMB_DIM  0.75
// Stamina regen modifiers
#define SHADOWLING_DARK_STAMINA_PER_LIMB_DIM   1
#define SHADOWLING_DARK_STAMINA_PER_LIMB_DEEP  2
// Regeneration after death
#define SHADOWLING_DEAD_HEAL_MULTIPLIER 0.5
#define SHADOWLING_DEATHCOMA_TRAIT "shadowling_deathcoma"

/// Audio stinger played to players when a Shadowling ascends.
#define SHADOWLING_RISEN_MUSIC 'sound/antagonists/shadowlings/shadowling_ascend.ogg'

/// Cooldown multiplier applied to Shadowling actions after Ascension.
#define SHADOWLING_ASCENDED_CD_MULT 0.5

/// True if [A] is currently of the hatched Shadowling species.
#define isshadowling(A) (is_species(A, /datum/species/shadow/shadowling))
/// True if [A] is currently of the Ascended Shadowling species.
#define isshadowling_ascended(A) (is_species(A, /datum/species/shadow/shadowling/ascended))
/// Percent of thralls from crew needed to ascend
#define SHADOWLING_ASCEND_DEFAULT_PERCENT 25
/// Base health for ascended Shadowling
#define SHADOWLING_ASCENDED_MAX_HEALTH 220

/// Trait *contents* shared by every Shadowling form. Use inside list(...), e.g.
/// `inherent_traits = list(SHADOWLING_BASE_TRAITS)`. Keeping the entries in one place
/// stops the ascended form from silently drifting out of sync with the base form.
#define SHADOWLING_BASE_TRAITS \
	TRAIT_GENELESS,\
	TRAIT_LAVA_IMMUNE,\
	TRAIT_NEVER_WOUNDED,\
	TRAIT_NOBLOOD,\
	TRAIT_NOBREATH,\
	TRAIT_NODISMEMBER,\
	TRAIT_NOFIRE,\
	TRAIT_RESISTCOLD,\
	TRAIT_VIRUSIMMUNE,\
	TRAIT_NO_AUGMENTS,\
	TRAIT_NO_DNA_COPY,\
	TRAIT_NO_PLASMA_TRANSFORM,\
	TRAIT_NO_UNDERWEAR,\
	TRAIT_PIERCEIMMUNE,\
	TRAIT_RADIMMUNE,\
	TRAIT_SNOWSTORM_IMMUNE,\
	TRAIT_UNHUSKABLE,\
	TRAIT_SILENT_FOOTSTEPS,\
	TRAIT_NOHUNGER,\
	TRAIT_NO_SLIP_ALL,\
	TRAIT_RESISTLOWPRESSURE,\
	TRAIT_BRAWLING_KNOCKDOWN_BLOCKED,\

/// Extra trait *contents* the ascended form adds on top of SHADOWLING_BASE_TRAITS.
#define SHADOWLING_ASCENDED_EXTRA_TRAITS \
	TRAIT_RESISTHIGHPRESSURE,\
	TRAIT_RESISTHEAT,\
	TRAIT_FREE_FLOAT_MOVEMENT,\
	TRAIT_MOVE_FLYING,\

/// Shadowling ability role/category bitflags
#define SL_INNATE    (1<<0)
#define SL_THRESHOLD (1<<1)
#define SL_ASCENDED  (1<<2)
#define SL_THRALL    (1<<3)
#define SL_LESSER    (1<<4)
