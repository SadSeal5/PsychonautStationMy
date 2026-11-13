import {
  Box,
  Button,
  DmIcon,
  Flex,
  Icon,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend, useSharedState } from '../backend';
import { Window } from '../layouts';
import {
  type Objective,
  ObjectivePrintout,
  ReplaceObjectivesButton,
} from './common/Objectives';

type NinjaInfo = {
  objectives: Objective[];
  can_change_objective: BooleanLike;
  in_setup?: BooleanLike;
  loadout_weapon?: number;
  slot_star?: number;
  slot_heal?: number;
  slot_trap?: number;
  confirmed?: BooleanLike;
  mod_icon?: string;
  weapon_icon?: string;
};

type WeaponDef = {
  value: number;
  title: string;
  tag: string;
  iconState: string;
  accentColor: string;
  accentBg: string;
  description: string;
  statBadge: string;
};

type OptionDef = {
  value: number;
  title: string;
  badge: 'DEFAULT' | 'ALTERNATIVE';
  typeTag: string;
  iconState: string;
  accentColor: string;
  accentBg: string;
  description: string;
  statBadge: string;
};

type SlotDef = {
  id: 'star' | 'heal' | 'trap';
  title: string;
  slotNum: number;
  currentValue: number;
  options: OptionDef[];
};

type DossierItem = {
  title: string;
  badge: string;
  typeTag: string;
  iconState: string;
  iconFile?: string;
  accentColor: string;
  controls: string;
  power: string;
  description: string;
  tacticalTip: string;
};

export const AntagInfoNinja = () => {
  const { act, data } = useBackend<NinjaInfo>();
  const {
    objectives = [],
    can_change_objective,
    in_setup,
    loadout_weapon = 1,
    slot_star = 1,
    slot_heal = 1,
    slot_trap = 1,
    confirmed,
    mod_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi',
    weapon_icon = 'icons/obj/weapons/sword.dmi',
  } = data;

  const [selectedTab, setSelectedTab] = useSharedState<'directives' | 'modsuit'>(
    'ninja_info_selected_tab',
    !confirmed ? 'modsuit' : 'directives'
  );

  const weapons: WeaponDef[] = [
    {
      value: 1,
      title: 'Energy Katana',
      tag: 'ALL-ROUNDER // DASH',
      iconState: 'energy_katana',
      accentColor: '#22c55e',
      accentBg: 'rgba(34, 197, 94, 0.12)',
      description:
        'Spider Clan monomolecular plasma blade with a 50% block chance. RMB combat dash (3 charges) instantly phases and strikes targets; downing a conscious foe refunds 1 charge.',
      statBadge: '30 FORCE // 50% BLOCK // EXECUTE REFUND',
    },
    {
      value: 2,
      title: 'Plasma Kusarigama',
      tag: 'REACH 2 // TRIP & REEL',
      iconState: 'plasma_kusarigama',
      accentColor: '#10b981',
      accentBg: 'rgba(16, 185, 129, 0.12)',
      description:
        'Spider Clan chained scythe with 2-tile reach. RMB lashes up to 4 tiles to trip and smart-disarm (active or off-hand); already-prone targets are dragged 2 tiles into melee reach.',
      statBadge: '24 FORCE // REACH 2 // 6S TRIP CD',
    },
    {
      value: 3,
      title: 'Dual Nanite Daggers',
      tag: 'DUAL STAB // SHADOW STEP',
      iconState: 'nanite_daggers',
      accentColor: '#84cc16',
      accentBg: 'rgba(132, 204, 22, 0.12)',
      description:
        'Twin high-frequency daggers delivering rapid double strikes and +16 silent backstabs. RMB shadow step (1 charge) recharges in 4s from cloak and resets instantly on execute.',
      statBadge: '16x2 FORCE // 60 AP // CLOAK RESET',
    },
  ];

  const slots: SlotDef[] = [
    {
      id: 'star',

      title: 'RANGED ORDNANCE',
      slotNum: 1,
      currentValue: slot_star,
      options: [
        {
          value: 1,
          title: 'EMP Shuriken Dispenser',
          badge: 'DEFAULT',
          typeTag: 'ION DISRUPTOR',
          iconState: 'dispenser_ninja',
          accentColor: '#fbbf24',
          accentBg: 'rgba(251, 191, 36, 0.12)',
          description:
            'Synthesizes monomolecular energy shurikens that discharge high-grade EMP bursts upon impact.',
          statBadge: '10 ENERGY // 0.5S CD // EMP',
        },
        {
          value: 2,
          title: 'Grappling Kunai Dispenser',
          badge: 'ALTERNATIVE',
          typeTag: 'TETHER HOOK',
          iconState: 'dispenser_kunai',
          accentColor: '#c4b5fd',
          accentBg: 'rgba(196, 181, 253, 0.12)',
          description:
            'Throws tethered kunai. Knocks victims down and reels them in prone, or pulls the user to walls with a smooth landing.',
          statBadge: '10 ENERGY // 7S CD // TETHER',
        },
        {
          value: 3,
          title: 'Paralytic Venom Dart Dispenser',
          badge: 'ALTERNATIVE',
          typeTag: 'NEUROTOXIN DART',
          iconState: 'dispenser_venom',
          accentColor: '#a855f7',
          accentBg: 'rgba(168, 85, 247, 0.12)',
          description:
            'Fabricates silent venom darts that inflict 22 stamina trauma, 2s confusion, 2.5s vocal silence, and lingering toxic embed drain.',
          statBadge: '10 ENERGY // 3.5S CD // SILENCE',
        },
      ],
    },
    {
      id: 'heal',
      title: 'BIOLOGICAL SUPPORT',
      slotNum: 2,
      currentValue: slot_heal,
      options: [
        {
          value: 1,
          title: 'Combat Adrenaline Boost',
          badge: 'DEFAULT',
          typeTag: 'STIMULANT SHOCK',
          iconState: 'adrenaline_boost',
          accentColor: '#fb7185',
          accentBg: 'rgba(251, 113, 133, 0.12)',
          description:
            'Emergency chemical surge. Instantly clears stuns, total paralysis, and stamina drain while injecting stimulants.',
          statBadge: '0 ENERGY // 20U RADIUM // ANTI-STUN',
        },
        {
          value: 2,
          title: 'Nanite Cellular Repair Matrix',
          badge: 'ALTERNATIVE',
          typeTag: 'BIOMEDICAL MATRIX',
          iconState: 'nanite_repair',
          accentColor: '#34d399',
          accentBg: 'rgba(52, 211, 153, 0.12)',
          description:
            'Specialized Spider Clan biomedical matrix that deploys surgical nanomachines into the bloodstream to rapidly clot hemorrhaging wounds, knit damaged tissue, and regenerate burns. Consumes 0 suit power, utilizing self-contained nanite charges refilled with Radium.',
          statBadge: '0 ENERGY // 3 CHARGES // 5U RADIUM/CHARGE',
        },
        {
          value: 3,
          title: 'Neural Reflex Overdrive',
          badge: 'ALTERNATIVE',
          typeTag: 'KINETIC STIM CORE',
          iconState: 'reflex_overdrive',
          accentColor: '#f59e0b',
          accentBg: 'rgba(245, 158, 11, 0.12)',
          description:
            'Floods the nervous system for 8s, restoring 35 stamina immediately plus 4/s, boosting move and attack speed, and ignoring injury slowdown.',
          statBadge: '80 ENERGY // 25S CD // 8S HASTE',
        },
      ],
    },
    {
      id: 'trap',
      title: 'SUBJUGATION & CONTROL',
      slotNum: 3,
      currentValue: slot_trap,
      options: [
        {
          value: 1,
          title: 'Energy Net Projector',
          badge: 'DEFAULT',
          typeTag: 'HARDLIGHT RESTRAINT',
          iconState: 'energy_net',
          accentColor: '#38bdf8',
          accentBg: 'rgba(56, 189, 248, 0.12)',
          description:
            'Fires an active hardlight projector deploying a reinforced capture barrier to securely anchor targets.',
          statBadge: '30 ENERGY // 5S CD // HARDLIGHT',
        },
        {
          value: 2,
          title: 'Holographic Decoy Module',
          badge: 'ALTERNATIVE',
          typeTag: 'CYBER DECOY',
          iconState: 'decoy_ninja',
          accentColor: '#00e5ff',
          accentBg: 'rgba(0, 229, 255, 0.12)',
          description:
            'Projects a lifelike holographic decoy charging targets and absorbing attacks. Grants 2.5s cloaking. Decoy overloads with an EMP flash pulse.',
          statBadge: '120 ENERGY // 24S CD // DECOY',
        },
        {
          value: 3,
          title: 'Shadow Smoke Shroud',
          badge: 'ALTERNATIVE',
          typeTag: 'SMOKE & RECLOAK',
          iconState: 'smoke_ninja',
          accentColor: '#06b6d4',
          accentBg: 'rgba(6, 182, 212, 0.12)',
          description:
            'Deploys a dense disorienting smoke cloud, extinguishes flames on you, blinds nearby unmasked foes, and resets optical cloak cooldown.',
          statBadge: '60 ENERGY // 20S CD // CLOAK RESET',
        },
      ],
    },
  ];

  const getStarDossier = (): DossierItem => {
    switch (slot_star) {
      case 2:
        return {
          title: 'Grappling Kunai Dispenser',
          badge: 'SLOT 1',
          typeTag: 'TETHER HOOK // REEL & DRAG',
          iconState: 'dispenser_kunai',
          accentColor: '#c4b5fd',
          controls: 'Click pinned action to synthesize // Throw at target or structure',
          power: '10 energy units per synthesis // 7.0s cooldown',
          description:
            'Fabricates lightweight titanium kunai linked by high-tensile nanite tow cables. Striking living targets knocks them down and reels them across the room directly to your feet along a visible tether beam. Striking dense walls or machinery hauls you forward with a smooth, upright landing.',
          tacticalTip:
            'Snatch isolated personnel into dark corridors for silent assassinations while they remain prone, or slingshot across wide corridors and hull breaches to bypass barriers.',
        };
      case 3:
        return {
          title: 'Paralytic Venom Dart Dispenser',
          badge: 'SLOT 1',
          typeTag: 'NEUROTOXIN DART // SILENCE',
          iconState: 'dispenser_venom',
          accentColor: '#a855f7',
          controls: 'Click pinned action to synthesize // Throw at target',
          power: '10 energy units per synthesis // 3.5s cooldown',
          description:
            'Synthesizes sleek purple-emerald Spider Clan darts tipped with a fast-acting paralytic neurotoxin. Impact deals 22 stamina damage, inflicts 2s confusion, and silences the victim for 2.5s with zero EMP signature. Embedded darts periodically seep additional stamina drain.',
          tacticalTip:
            'Use venom darts to mute witnesses before they can call security over radio, then follow up with Kusarigama reel-in or Nanite Dagger backstabs.',
        };
      default:
        return {
          title: 'EMP Shuriken Dispenser',
          badge: 'SLOT 1',
          typeTag: 'ION DISRUPTOR // ORDNANCE',
          iconState: 'dispenser_ninja',
          accentColor: '#fbbf24',
          controls: 'Click pinned action to synthesize // Throw at target',
          power: '10 energy units per synthesis // 0.5s cooldown',
          description:
            'Synthesizes monomolecular energy shurikens with embedded electromagnetic discharge emitters. On impact, releases a heavy EMP burst. If embedded in carbon prey, continues pulsing periodically with secondary EMP shocks.',
          tacticalTip:
            'Thrown shurikens are uncatchable. Use them to shut down cyborgs, disable security laser carbines, drain electronics, and extinguish room lighting.',
        };
    }
  };

  const getHealDossier = (): DossierItem => {
    switch (slot_heal) {
      case 2:
        return {
          title: 'Nanite Cellular Repair Matrix',
          badge: 'SLOT 2',
          typeTag: 'BIOMEDICAL MATRIX // RESTORATION',
          iconState: 'nanite_repair',
          accentColor: '#34d399',
          controls: 'Click pinned action to engage (Usable while incapacitated)',
          power: '0 Energy (Does not consume suit power // 3 charges, 5u Radium per charge // 15s cooldown)',
          description:
            "Floods the operative's circulation with autonomous medical nanomachines and synthetic coagulants. The microscopic swarm seals internal hemorrhaging, reconstructs torn muscle and bone, and restores lost blood volume. Draws no power from the suit, relying on internal nanite reserves refueled with Radium.",
          tacticalTip:
            'Acts as an independent trauma response unit that keeps you fighting without eating into your cloak or mobility power. If charges are spent, top up directly from beakers or bottles containing Radium (5u per charge).',
        };
      case 3:
        return {
          title: 'Neural Reflex Overdrive',
          badge: 'SLOT 2',
          typeTag: 'KINETIC STIM CORE // OVERDRIVE',
          iconState: 'reflex_overdrive',
          accentColor: '#f59e0b',
          controls: 'Pinned Suit Action or Suit Menu (Instant Use)',
          power: '80 energy units per surge // 25s cooldown',
          description:
            'Discharges a crimson-gold synaptic surge that restores 35 stamina immediately and 4 stamina per second for 8 seconds. Grants a dramatic boost to movement and attack speed while granting full immunity to injury-based movement slowdown.',
          tacticalTip:
            'Pop overdrive right before diving a fortified room or chasing down fleeing targets; injury slowdown immunity keeps you at peak velocity even under heavy fire.',
        };
      default:
        return {
          title: 'Combat Adrenaline Boost',
          badge: 'SLOT 2',
          typeTag: 'STIMULANT SHOCK // NEURAL OVERRIDE',
          iconState: 'adrenaline_boost',
          accentColor: '#fb7185',
          controls: 'Click pinned action to inject (Usable while incapacitated / cuffed)',
          power: '0 Energy (Does not consume suit power // Refillable with 20u Radium // 12s cooldown)',
          description:
            'Triggers an emergency autonomic neuro-chemical override. Instantly purges all stuns, knockdowns, paralysis, and up to 200 stamina damage while flooding the bloodstream with combat stimulants.',
          tacticalTip:
            'The ultimate escape countermeasure. If ambushed by flashbangs, tasers, or stun batons, pop adrenaline immediately to regain control and retaliate before restraints can be placed.',
        };
    }
  };

  const getTrapDossier = (): DossierItem => {
    switch (slot_trap) {
      case 2:
        return {
          title: 'Holographic Decoy Module',
          badge: 'SLOT 3',
          typeTag: 'CYBER DECOY // MISDIRECTION',
          iconState: 'decoy_ninja',
          accentColor: '#00e5ff',
          controls: 'Pinned Suit Action or Suit Menu (Instant Use)',
          power: '120 energy units per deployment // 24s cooldown',
          description:
            'A state-of-the-art Spider Clan misdirection system. When activated, projects a lifelike holographic decoy of the user that charges towards targets, drawing enemy fire and attacks. The ninja enters brief optical camouflage (alpha = 25 and silent footsteps) for 2.5 seconds to reposition. Upon taking damage or after 5 seconds, the holographic decoy overloads with an electromagnetic flash pulse, detonating an EMP and blinding/disorienting pursuers in a 3-tile radius with an intense flashbang overload.',
          tacticalTip:
            'Trigger the decoy when ambushed or breaching high-threat areas. The decoy will absorb attacks while you slip away invisibly. The enhanced flash overload disorients and knocks down nearby enemies, opening them up for lethal katana strikes.',
        };
      case 3:
        return {
          title: 'Shadow Smoke Shroud',
          badge: 'SLOT 3',
          typeTag: 'SMOKE & RECLOAK // EVASION',
          iconState: 'smoke_ninja',
          accentColor: '#06b6d4',
          controls: 'Pinned Suit Action or Suit Menu (Instant Use)',
          power: '60 energy units per deployment // 20s cooldown',
          description:
            'Erupts a 3-tile dense smoke cloud that extinguishes active fires on your suit, disorients and blurs vision of nearby unmasked adversaries without internals, and instantaneously resets the cooldown on your Advanced Mimetic Stealth module.',
          tacticalTip:
            'Use immediately after breaking cloak in an ambush or when set ablaze: extinguish flames, blind pursuers, and re-engage stealth without waiting on cloak recharge.',
        };
      default:
        return {
          title: 'Energy Net Projector',
          badge: 'SLOT 3',
          typeTag: 'HARDLIGHT RESTRAINT // CAPTURE',
          iconState: 'energy_net',
          accentColor: '#38bdf8',
          controls: 'Select action and target mob with ranged projector',
          power: '30 energy units per shot // 5s cooldown',
          description:
            'Fires an expanding hardlight projector that establishes a reinforced capture cage around the target, locking them in place on the tile and preventing all movement until dismantled or destroyed.',
          tacticalTip:
            'Ideal for taking key station personnel alive or neutralizing aggressive pursuers without wasting lethal blade energy.',
        };
    }
  };

  // Active loadout dossier specifications based on chosen slots
  const chosenDossier: DossierItem[] = [getStarDossier(), getHealDossier(), getTrapDossier()];

  const getCoreWeaponDossier = (): DossierItem => {
    switch (loadout_weapon) {
      case 2:
        return {
          title: 'Plasma Kusarigama & Weapon Recall',
          badge: 'CORE WEAPON',
          typeTag: 'CHAINED SCYTHE // REACH 2',
          iconState: 'plasma_kusarigama',
          iconFile: weapon_icon,
          accentColor: '#10b981',
          controls: 'LMB reach-2 strike // RMB chain trip, smart disarm & prone reel-in',
          power: 'None (6s trip cooldown)',
          description:
            'A Spider Clan chained scythe and heavy plasma ballast with extended 2-tile reach. Right-clicking lashes up to 4 tiles to knock targets down and smart-disarm either their active or off-hand item. Targets already lying down are dragged 2 tiles directly into reach-2 melee range.',
          tacticalTip:
            'Open with a Grappling Kunai or Shuriken to drop targets, then RMB with the Kusarigama to strip off-hand weapons and drag prone foes straight into 2-tile cleave range.',
        };
      case 3:
        return {
          title: 'Dual Nanite Daggers & Weapon Recall',
          badge: 'CORE WEAPON',
          typeTag: 'TWIN DAGGERS // DUAL STAB',
          iconState: 'nanite_daggers',
          iconFile: weapon_icon,
          accentColor: '#84cc16',
          controls: 'LMB rapid dual stab // RMB shadow step blink',
          power: '1 charge (8s recharge, 4s from cloak, instant reset on execute)',
          description:
            'Twin high-frequency nanite daggers designed for silent infiltration. Every attack delivers an immediate second strike for 16 brute damage, while backstabs inflict +16 critical damage and 3s silence. Shadow stepping from optical cloak halves recharge to 4s, and downing or killing a conscious target refunds the charge instantly.',
          tacticalTip:
            'Engage stealth or Shadow Smoke before shadow stepping to halve blink recharge to 4s—or finish weakened targets in one ambush to chain consecutive shadow steps with zero cooldown.',
        };
      default:
        return {
          title: 'Energy Katana & Weapon Recall',
          badge: 'CORE WEAPON',
          typeTag: 'PLASMA BLADE // QUANTUM RECALL',
          iconState: 'energy_katana',
          iconFile: weapon_icon,
          accentColor: '#22c55e',
          controls: 'LMB strike // RMB combat dash (3 charges)',
          power: '3 charges (20s recharge; refunds 1 charge on execute)',
          description:
            'Monomolecular plasma blade forged by the Spider Clan with 50% block chance and 50 armor penetration. Right-clicking a tile or target consumes 1 of 3 combat dash charges to blink and strike immediately; downing or killing a conscious target with dash-strike refunds the dash charge.',
          tacticalTip:
            'Inspect your katana to track remaining dash charges. Chain dash-strike executes on softened or poisoned targets to refund charges and blitz through multi-target encounters.',
        };
    }
  };

  const coreSystems: DossierItem[] = [
    {
      title: 'Advanced Mimetic Stealth',
      badge: 'CORE INFILTRATION',
      typeTag: 'OPTICAL CLOAK // CHAMELEONIC',
      iconState: 'cloak_ninja',
      accentColor: '#c084fc',
      controls: 'Pinned Suit Action or Suit Menu (Toggle)',
      power: '50 energy units on activation + 10 units/sec while active',
      description:
        'Projects a refractive light-bending field with dynamic chameleonic skin adaptation. Renders the wearer virtually invisible and completely silences footsteps. Equipped with stabilization dampeners that do NOT break cloak on bumping into objects or crew.',
      tacticalTip:
        'Cloak only disengages when sustaining hostile damage or initiating attacks. Perfect for slipping past sentry turrets and lurking undetected in illuminated hallways.',
    },
    getCoreWeaponDossier(),
    {
      title: 'Cybernetic Hacker Interface',

      badge: 'CORE GLOVES',
      typeTag: 'ELECTRONIC WARFARE // SIFTER',
      iconState: 'hacker',
      accentColor: '#06b6d4',
      controls: 'Right-click with empty hands on APCs, SMES, airlocks, or consoles',
      power: 'RECHARGES MODSUIT BATTERY',
      description:
        'Sub-dermal induction emitters crack machine circuitry. Right-clicking an APC or power cell drains its energy to rapidly refill your MODsuit battery. Right-clicking airlocks doorjacks them open immediately. Hacking consoles executes sabotage objectives.',
      tacticalTip:
        'Whenever battery levels dwindle after cloaking or combat, slip into maintenance and drain the nearest APC.',
    },
    {
      title: 'Multi-Spectrum Optical Visor',
      badge: 'CORE SENSOR',
      typeTag: 'RECON // ANTI-SURVEILLANCE',
      iconState: 'welding_camera',
      accentColor: '#10b981',
      controls: 'Passive Integrated Sensor Suite',
      power: '0 W (Passive)',
      description:
        'Provides continuous thermal night vision and absolute flash protection against welding arcs and flashbangs. Emits counter-frequency jamming that prevents security camera tracking and AI facial recognition.',
      tacticalTip:
        'Operate in total darkness. Station AI and camera tracking will never reveal your coordinates.',
    },
  ];

  return (
    <Window title="Spider Clan Mercenary Terminal" width={740} height={640} theme="hackerman">
      <Window.Content scrollable>
        {/* Subtle decorative background watermark */}
        <Icon
          size={36}
          name="spider"
          color="#002200"
          position="absolute"
          top="8%"
          right="4%"
          style={{ pointerEvents: 'none', opacity: 0.12 }}
        />

        {/* Navigation Tabs */}
        <Tabs fluid mb={1.5}>
          <Tabs.Tab
            icon="scroll"
            selected={selectedTab === 'directives'}
            onClick={() => setSelectedTab('directives')}
          >
            Mission Directives
          </Tabs.Tab>
          <Tabs.Tab
            icon="robot"
            selected={selectedTab === 'modsuit'}
            onClick={() => setSelectedTab('modsuit')}
          >
            MODsuit Systems
          </Tabs.Tab>
        </Tabs>

        {/* Tab 1: Mission Directives */}
        {selectedTab === 'directives' && (
          <Stack vertical g={1.5} fill>
            <Stack.Item textAlign="center">
              <Box fontSize="20px" bold color="green">
                I am an elite mercenary of the Spider Clan.
                <br />A <span style={{ color: '#ef4444' }}>SPACE NINJA</span>!
              </Box>
              <Box italic color="label" mt={0.5}>
                Surprise is my weapon. Shadows are my armor. Without them, I am nothing.
              </Box>
            </Stack.Item>

            <Stack.Item>
              <Section title="Spider Clan Infiltration Directives">
                <Stack vertical g={1}>
                  <Box>
                    <Icon name="bolt" color="#fbbf24" mr={1} />
                    <strong>Power Harvesting:</strong> Right-click on station APCs, SMES units, or power cells with empty hands to drain electrical grids directly into your MODsuit capacitor.
                  </Box>
                  <Box>
                    <Icon name="door-open" color="#38bdf8" mr={1} />
                    <strong>Electronic Doorjacking:</strong> Right-click airlocks with cybernetic hacker gloves to force open bulkheads without keys.
                  </Box>
                  <Box>
                    <Icon name="terminal" color="#34d399" mr={1} />
                    <strong>Subversive Sabotage:</strong> Right-click security consoles to scramble crew arrest records or communications consoles to dispatch phantom distress signals.
                  </Box>
                </Stack>
              </Section>
            </Stack.Item>

            <Stack.Item grow>
              <ObjectivePrintout
                objectives={objectives}
                objectiveFollowup={
                  <ReplaceObjectivesButton
                    can_change_objective={can_change_objective}
                    button_title="Adapt Mission Parameters"
                    button_colour="green"
                  />
                }
              />
            </Stack.Item>
          </Stack>
        )}

        {/* Tab 2: MODsuit Systems */}
        {selectedTab === 'modsuit' && (
          <Stack vertical g={1.5} fill>
            {!confirmed ? (
              // Unconfirmed Selection Mode
              <>
                <Stack.Item>
                  <NoticeBox info>
                    <Flex align="center" justify="space-between">
                      <Flex.Item>
                        <Icon name="shield-alt" mr={1} />
                        <strong>Spider Clan Temporal Infiltration Protocol:</strong> Mimetic-cloaking nanites and invulnerability shielding are fully active. Your position is completely concealed. The veil remains active until your loadout is confirmed (or this window is closed), or until the calibration timer expires.
                      </Flex.Item>
                      {!!in_setup && (
                        <Flex.Item>
                          <Box
                            bold
                            fontSize="0.8em"
                            style={{
                              padding: '2px 8px',
                              backgroundColor: 'rgba(16, 185, 129, 0.25)',
                              border: '1px solid #10b981',
                              borderRadius: '3px',
                              letterSpacing: '1px',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            VEIL ACTIVE
                          </Box>
                        </Flex.Item>
                      )}
                    </Flex>
                  </NoticeBox>
                </Stack.Item>

                {/* Primary Weapon Slot */}
                <Stack.Item>
                  <Box
                    style={{
                      backgroundColor: 'rgba(15, 18, 26, 0.75)',
                      border: '1px solid rgba(255, 255, 255, 0.08)',
                      borderRadius: '6px',
                      padding: '10px',
                    }}
                  >
                    {/* Header */}
                    <Flex align="center" justify="space-between" mb={1}>
                      <Flex.Item>
                        <Flex align="center">
                          <Box
                            bold
                            fontSize="0.75em"
                            color="label"
                            mr={1}
                            style={{
                              backgroundColor: 'rgba(255, 255, 255, 0.06)',
                              padding: '2px 6px',
                              borderRadius: '3px',
                              letterSpacing: '1px',
                            }}
                          >
                            PRIMARY WEAPON
                          </Box>
                          <Box bold fontSize="0.95em" style={{ letterSpacing: '0.8px' }}>
                            PRIMARY ARSENAL
                          </Box>
                        </Flex>
                      </Flex.Item>
                      <Flex.Item>
                        <Box fontSize="0.75em" color="label">
                          SELECT 1 OF 3
                        </Box>
                      </Flex.Item>
                    </Flex>

                    {/* 3 Weapon Option Cards */}
                    <Stack fill g={2}>
                      {weapons.map((wep) => {
                        const isSelected = loadout_weapon === wep.value;
                        return (
                          <Stack.Item key={wep.value} grow basis={0}>
                            <Box
                              onClick={() => act('select_weapon', { choice: wep.value })}
                              style={{
                                cursor: 'pointer',
                                backgroundColor: isSelected
                                  ? 'rgba(18, 24, 36, 0.95)'
                                  : 'rgba(13, 16, 24, 0.6)',
                                border: isSelected
                                  ? `2px solid ${wep.accentColor}`
                                  : '1px solid rgba(255, 255, 255, 0.1)',
                                borderRadius: '5px',
                                boxShadow: isSelected
                                  ? `0 0 14px ${wep.accentColor}33, inset 0 0 10px ${wep.accentColor}11`
                                  : 'none',
                                padding: '10px',
                                transition: 'all 0.15s ease',
                                opacity: isSelected ? 1 : 0.72,
                                display: 'flex',
                                flexDirection: 'column',
                                minHeight: '120px',
                              }}
                            >
                              <Flex align="center" justify="space-between" mb={1}>
                                <Flex.Item>
                                  <Flex align="center" g={1}>
                                    <Box
                                      bold
                                      fontSize="0.7em"
                                      style={{
                                        backgroundColor: wep.accentBg,
                                        color: wep.accentColor,
                                        border: `1px solid ${wep.accentColor}55`,
                                        padding: '1px 6px',
                                        borderRadius: '3px',
                                        letterSpacing: '0.5px',
                                      }}
                                    >
                                      {wep.value === 1 ? 'DEFAULT' : 'ALTERNATIVE'}
                                    </Box>
                                    <Box fontSize="0.7em" color="label">
                                      {wep.tag}
                                    </Box>
                                  </Flex>
                                </Flex.Item>
                                <Flex.Item>
                                  {isSelected ? (
                                    <Box
                                      bold
                                      fontSize="0.75em"
                                      style={{
                                        backgroundColor: wep.accentColor,
                                        color: '#0a0d14',
                                        padding: '2px 8px',
                                        borderRadius: '3px',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '4px',
                                      }}
                                    >
                                      <Icon name="check" />
                                      ACTIVE
                                    </Box>
                                  ) : (
                                    <Box
                                      fontSize="0.7em"
                                      color="label"
                                      style={{
                                        padding: '2px 6px',
                                        borderRadius: '3px',
                                        border: '1px solid rgba(255, 255, 255, 0.08)',
                                      }}
                                    >
                                      CLICK TO EQUIP
                                    </Box>
                                  )}
                                </Flex.Item>
                              </Flex>

                              <Flex align="flex-start" g={1.5} style={{ flexGrow: 1 }}>
                                <Flex.Item>
                                  <Box
                                    style={{
                                      width: '42px',
                                      height: '42px',
                                      backgroundColor: '#0a0c12',
                                      border: isSelected
                                        ? `1px solid ${wep.accentColor}88`
                                        : '1px solid rgba(255, 255, 255, 0.08)',
                                      borderRadius: '5px',
                                      display: 'flex',
                                      alignItems: 'center',
                                      justifyContent: 'center',
                                      boxShadow: isSelected
                                        ? `0 0 8px ${wep.accentColor}22`
                                        : 'none',
                                    }}
                                  >
                                    <DmIcon
                                      icon={weapon_icon}
                                      icon_state={wep.iconState}
                                      width="32px"
                                      height="32px"
                                    />
                                  </Box>
                                </Flex.Item>

                                <Flex.Item grow style={{ minWidth: 0 }}>
                                  <Box
                                    bold
                                    fontSize="1.05em"
                                    style={{
                                      color: isSelected ? '#ffffff' : '#cbd5e1',
                                      letterSpacing: '0.3px',
                                    }}
                                  >
                                    {wep.title}
                                  </Box>
                                  <Box
                                    fontSize="0.82em"
                                    color="label"
                                    mt={0.5}
                                    style={{ lineHeight: '1.35' }}
                                  >
                                    {wep.description}
                                  </Box>
                                </Flex.Item>
                              </Flex>

                              <Box
                                mt={1}
                                pt={0.8}
                                fontSize="0.75em"
                                bold
                                style={{
                                  borderTop: '1px solid rgba(255, 255, 255, 0.06)',
                                  color: isSelected ? wep.accentColor : '#64748b',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'space-between',
                                }}
                              >
                                <span>SPEC: {wep.statBadge}</span>
                                {isSelected && (
                                  <span style={{ fontSize: '0.9em' }}>● SYNCHRONIZED</span>
                                )}
                              </Box>
                            </Box>
                          </Stack.Item>
                        );
                      })}
                    </Stack>
                  </Box>
                </Stack.Item>

                {/* 3 Slot Selection Cards */}
                {slots.map((slot) => (

                  <Stack.Item key={slot.id}>
                    <Box
                      style={{
                        backgroundColor: 'rgba(15, 18, 26, 0.75)',
                        border: '1px solid rgba(255, 255, 255, 0.08)',
                        borderRadius: '6px',
                        padding: '10px',
                      }}
                    >
                      {/* Slot Header */}
                      <Flex align="center" justify="space-between" mb={1}>
                        <Flex.Item>
                          <Flex align="center">
                            <Box
                              bold
                              fontSize="0.75em"
                              color="label"
                              mr={1}
                              style={{
                                backgroundColor: 'rgba(255, 255, 255, 0.06)',
                                padding: '2px 6px',
                                borderRadius: '3px',
                                letterSpacing: '1px',
                              }}
                            >
                              SLOT {slot.slotNum}
                            </Box>
                            <Box bold fontSize="0.95em" style={{ letterSpacing: '0.8px' }}>
                              {slot.title}
                            </Box>
                          </Flex>
                        </Flex.Item>
                        <Flex.Item>
                          <Box fontSize="0.75em" color="label">
                            SELECT 1 OF {slot.options.length}
                          </Box>
                        </Flex.Item>
                      </Flex>

                      {/* Slot Option Cards */}
                      <Stack fill g={2}>
                        {slot.options.map((opt) => {
                          const isSelected = slot.currentValue === opt.value;
                          return (
                            <Stack.Item key={opt.value} grow basis={0}>
                              <Box
                                onClick={() => act('set_slot', { slot: slot.id, value: opt.value })}
                                style={{
                                  cursor: 'pointer',
                                  backgroundColor: isSelected
                                    ? 'rgba(18, 24, 36, 0.95)'
                                    : 'rgba(13, 16, 24, 0.6)',
                                  border: isSelected
                                    ? `2px solid ${opt.accentColor}`
                                    : '1px solid rgba(255, 255, 255, 0.1)',
                                  borderRadius: '5px',
                                  boxShadow: isSelected
                                    ? `0 0 14px ${opt.accentColor}33, inset 0 0 10px ${opt.accentColor}11`
                                    : 'none',
                                  padding: '10px',
                                  transition: 'all 0.15s ease',
                                  opacity: isSelected ? 1 : 0.72,
                                  display: 'flex',
                                  flexDirection: 'column',
                                  minHeight: '120px',
                                }}
                              >
                                {/* Top Badges Row */}
                                <Flex align="center" justify="space-between" mb={1}>
                                  <Flex.Item>
                                    <Flex align="center" g={1}>
                                      <Box
                                        bold
                                        fontSize="0.7em"
                                        style={{
                                          backgroundColor:
                                            opt.badge === 'DEFAULT'
                                              ? 'rgba(255, 255, 255, 0.08)'
                                              : opt.accentBg,
                                          color:
                                            opt.badge === 'DEFAULT' ? '#94a3b8' : opt.accentColor,
                                          border: `1px solid ${
                                            opt.badge === 'DEFAULT'
                                              ? 'rgba(255, 255, 255, 0.15)'
                                              : `${opt.accentColor}55`
                                          }`,
                                          padding: '1px 6px',
                                          borderRadius: '3px',
                                          letterSpacing: '0.5px',
                                        }}
                                      >
                                        {opt.badge}
                                      </Box>
                                      <Box fontSize="0.7em" color="label">
                                        {opt.typeTag}
                                      </Box>
                                    </Flex>
                                  </Flex.Item>
                                  <Flex.Item>
                                    {isSelected ? (
                                      <Box
                                        bold
                                        fontSize="0.75em"
                                        style={{
                                          backgroundColor: opt.accentColor,
                                          color: '#0a0d14',
                                          padding: '2px 8px',
                                          borderRadius: '3px',
                                          display: 'flex',
                                          alignItems: 'center',
                                          gap: '4px',
                                        }}
                                      >
                                        <Icon name="check" />
                                        ACTIVE
                                      </Box>
                                    ) : (
                                      <Box
                                        fontSize="0.7em"
                                        color="label"
                                        style={{
                                          padding: '2px 6px',
                                          borderRadius: '3px',
                                          border: '1px solid rgba(255, 255, 255, 0.08)',
                                        }}
                                      >
                                        CLICK TO EQUIP
                                      </Box>
                                    )}
                                  </Flex.Item>
                                </Flex>

                                {/* Middle Sprite & Info */}
                                <Flex align="flex-start" g={1.5} style={{ flexGrow: 1 }}>
                                  <Flex.Item>
                                    <Box
                                      style={{
                                        width: '42px',
                                        height: '42px',
                                        backgroundColor: '#0a0c12',
                                        border: isSelected
                                          ? `1px solid ${opt.accentColor}88`
                                          : '1px solid rgba(255, 255, 255, 0.08)',
                                        borderRadius: '5px',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        boxShadow: isSelected
                                          ? `0 0 8px ${opt.accentColor}22`
                                          : 'none',
                                      }}
                                    >
                                      <DmIcon
                                        icon={mod_icon}
                                        icon_state={opt.iconState}
                                        width="32px"
                                        height="32px"
                                      />
                                    </Box>
                                  </Flex.Item>

                                  <Flex.Item grow style={{ minWidth: 0 }}>
                                    <Box
                                      bold
                                      fontSize="1.05em"
                                      style={{
                                        color: isSelected ? '#ffffff' : '#cbd5e1',
                                        letterSpacing: '0.3px',
                                      }}
                                    >
                                      {opt.title}
                                    </Box>
                                    <Box
                                      fontSize="0.82em"
                                      color="label"
                                      mt={0.5}
                                      style={{ lineHeight: '1.35' }}
                                    >
                                      {opt.description}
                                    </Box>
                                  </Flex.Item>
                                </Flex>

                                {/* Bottom Stats Footer */}
                                <Box
                                  mt={1}
                                  pt={0.8}
                                  fontSize="0.75em"
                                  bold
                                  style={{
                                    borderTop: '1px solid rgba(255, 255, 255, 0.06)',
                                    color: isSelected ? opt.accentColor : '#64748b',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'space-between',
                                  }}
                                >
                                  <span>SPEC: {opt.statBadge}</span>
                                  {isSelected && (
                                    <span style={{ fontSize: '0.9em' }}>● SYNCHRONIZED</span>
                                  )}
                                </Box>
                              </Box>
                            </Stack.Item>
                          );
                        })}
                      </Stack>
                    </Box>
                  </Stack.Item>
                ))}

                {/* Confirm Button */}
                <Stack.Item mt={1} mb={1}>
                  <Button
                    fluid
                    color="good"
                    icon="check-double"
                    fontSize="1.2em"
                    lineHeight="2.4"
                    textAlign="center"
                    bold
                    onClick={() => act('confirm')}
                    style={{
                      boxShadow: '0 0 16px rgba(16, 185, 129, 0.3)',
                      letterSpacing: '1px',
                    }}
                  >
                    CONFIRM LOADOUT & SYNTHESIZE MODSUIT
                  </Button>
                </Stack.Item>
              </>
            ) : (
              // Confirmed Dossier View (Non-editable detailed specifications)
              <>
                <Stack.Item>
                  <NoticeBox success>
                    <Flex align="center" justify="space-between">
                      <Flex.Item>
                        <Icon name="check-double" mr={1} />
                        <strong>MODsuit Fully Calibrated — Cybernetic Dossier</strong>
                      </Flex.Item>
                      <Flex.Item>
                        <Box
                          bold
                          fontSize="0.8em"
                          style={{
                            padding: '2px 8px',
                            backgroundColor: 'rgba(52, 211, 153, 0.25)',
                            border: '1px solid #34d399',
                            borderRadius: '3px',
                            letterSpacing: '1px',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          ONLINE & READY
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </NoticeBox>
                </Stack.Item>

                {/* Chosen Modules Section */}
                <Stack.Item>
                  <Section title="Chosen Tactical Modules">
                    <Stack vertical g={1.5}>
                      {chosenDossier.map((item, idx) => (
                        <Stack.Item key={idx}>
                          <Box
                            style={{
                              backgroundColor: 'rgba(15, 18, 26, 0.85)',
                              border: `1px solid ${item.accentColor}66`,
                              borderRadius: '6px',
                              padding: '12px',
                              boxShadow: `0 0 10px ${item.accentColor}15`,
                            }}
                          >
                            <Flex align="flex-start" g={1.5}>
                              {/* Sprite */}
                              <Flex.Item>
                                <Box
                                  style={{
                                    width: '46px',
                                    height: '46px',
                                    backgroundColor: '#0a0c12',
                                    border: `1px solid ${item.accentColor}88`,
                                    borderRadius: '5px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    boxShadow: `0 0 8px ${item.accentColor}33`,
                                  }}
                                >
                                  <DmIcon
                                    icon={item.iconFile || mod_icon}
                                    icon_state={item.iconState}
                                    width="34px"
                                    height="34px"
                                  />
                                </Box>
                              </Flex.Item>

                              {/* Content */}
                              <Flex.Item grow style={{ minWidth: 0 }}>
                                <Flex align="center" justify="space-between" mb={0.5}>
                                  <Flex.Item>
                                    <Flex align="center" g={1}>
                                      <Box
                                        bold
                                        fontSize="0.75em"
                                        style={{
                                          backgroundColor: `${item.accentColor}22`,
                                          color: item.accentColor,
                                          border: `1px solid ${item.accentColor}55`,
                                          padding: '2px 6px',
                                          borderRadius: '3px',
                                          letterSpacing: '0.8px',
                                        }}
                                      >
                                        {item.badge}
                                      </Box>
                                      <Box bold fontSize="1.1em" style={{ color: '#ffffff' }}>
                                        {item.title}
                                      </Box>
                                    </Flex>
                                  </Flex.Item>
                                  <Flex.Item>
                                    <Box fontSize="0.75em" color="label">
                                      {item.typeTag}
                                    </Box>
                                  </Flex.Item>
                                </Flex>

                                <Box
                                  fontSize="0.82em"
                                  color="label"
                                  mb={0.8}
                                  style={{
                                    display: 'flex',
                                    flexWrap: 'wrap',
                                    gap: '12px',
                                    backgroundColor: 'rgba(255, 255, 255, 0.03)',
                                    padding: '5px 8px',
                                    borderRadius: '4px',
                                  }}
                                >
                                  <span>
                                    <Icon name="hand-pointer" mr={0.5} color={item.accentColor} />
                                    <strong>Controls:</strong> {item.controls}
                                  </span>
                                  <span>
                                    <Icon name="bolt" mr={0.5} color="#fbbf24" />
                                    <strong>Drain:</strong> {item.power}
                                  </span>
                                </Box>

                                <Box fontSize="0.85em" style={{ lineHeight: '1.4' }} mb={0.8}>
                                  {item.description}
                                </Box>

                                <Box
                                  fontSize="0.8em"
                                  style={{
                                    backgroundColor: 'rgba(0, 0, 0, 0.35)',
                                    borderLeft: `3px solid ${item.accentColor}`,
                                    padding: '4px 8px',
                                    borderRadius: '0 3px 3px 0',
                                    color: '#94a3b8',
                                  }}
                                >
                                  <Icon name="lightbulb" mr={0.5} color={item.accentColor} />
                                  <strong>Tactical Tip:</strong> {item.tacticalTip}
                                </Box>
                              </Flex.Item>
                            </Flex>
                          </Box>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                </Stack.Item>

                {/* Core Systems Section */}
                <Stack.Item>
                  <Section title="Integrated Core Capabilities">
                    <Stack vertical g={1.5}>
                      {coreSystems.map((item, idx) => (
                        <Stack.Item key={idx}>
                          <Box
                            style={{
                              backgroundColor: 'rgba(15, 18, 26, 0.7)',
                              border: `1px solid rgba(255, 255, 255, 0.08)`,
                              borderRadius: '6px',
                              padding: '12px',
                            }}
                          >
                            <Flex align="flex-start" g={1.5}>
                              {/* Sprite */}
                              <Flex.Item>
                                <Box
                                  style={{
                                    width: '46px',
                                    height: '46px',
                                    backgroundColor: '#0a0c12',
                                    border: `1px solid ${item.accentColor}66`,
                                    borderRadius: '5px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                  }}
                                >
                                  <DmIcon
                                    icon={item.iconFile || mod_icon}
                                    icon_state={item.iconState}
                                    width="34px"
                                    height="34px"
                                  />
                                </Box>
                              </Flex.Item>

                              {/* Content */}
                              <Flex.Item grow style={{ minWidth: 0 }}>
                                <Flex align="center" justify="space-between" mb={0.5}>
                                  <Flex.Item>
                                    <Flex align="center" g={1}>
                                      <Box
                                        bold
                                        fontSize="0.75em"
                                        style={{
                                          backgroundColor: `${item.accentColor}22`,
                                          color: item.accentColor,
                                          border: `1px solid ${item.accentColor}44`,
                                          padding: '2px 6px',
                                          borderRadius: '3px',
                                          letterSpacing: '0.8px',
                                        }}
                                      >
                                        {item.badge}
                                      </Box>
                                      <Box bold fontSize="1.05em" style={{ color: '#ffffff' }}>
                                        {item.title}
                                      </Box>
                                    </Flex>
                                  </Flex.Item>
                                  <Flex.Item>
                                    <Box fontSize="0.75em" color="label">
                                      {item.typeTag}
                                    </Box>
                                  </Flex.Item>
                                </Flex>

                                <Box
                                  fontSize="0.82em"
                                  color="label"
                                  mb={0.8}
                                  style={{
                                    display: 'flex',
                                    flexWrap: 'wrap',
                                    gap: '12px',
                                    backgroundColor: 'rgba(255, 255, 255, 0.03)',
                                    padding: '5px 8px',
                                    borderRadius: '4px',
                                  }}
                                >
                                  <span>
                                    <Icon name="hand-pointer" mr={0.5} color={item.accentColor} />
                                    <strong>Controls:</strong> {item.controls}
                                  </span>
                                  <span>
                                    <Icon name="bolt" mr={0.5} color="#fbbf24" />
                                    <strong>Power:</strong> {item.power}
                                  </span>
                                </Box>

                                <Box fontSize="0.85em" style={{ lineHeight: '1.4' }} mb={0.8}>
                                  {item.description}
                                </Box>

                                <Box
                                  fontSize="0.8em"
                                  style={{
                                    backgroundColor: 'rgba(0, 0, 0, 0.35)',
                                    borderLeft: `3px solid ${item.accentColor}`,
                                    padding: '4px 8px',
                                    borderRadius: '0 3px 3px 0',
                                    color: '#94a3b8',
                                  }}
                                >
                                  <Icon name="lightbulb" mr={0.5} color={item.accentColor} />
                                  <strong>Tactical Tip:</strong> {item.tacticalTip}
                                </Box>
                              </Flex.Item>
                            </Flex>
                          </Box>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                </Stack.Item>
              </>
            )}
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};
