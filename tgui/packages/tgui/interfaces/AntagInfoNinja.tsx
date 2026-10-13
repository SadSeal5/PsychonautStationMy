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
  slot_stealth?: number;
  slot_star?: number;
  slot_heal?: number;
  slot_trap?: number;
  confirmed?: BooleanLike;
  mod_icon?: string;
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
  id: 'stealth' | 'star' | 'heal' | 'trap';
  title: string;
  slotNum: number;
  currentValue: number;
  options: [OptionDef, OptionDef];
};

type DossierItem = {
  title: string;
  badge: string;
  typeTag: string;
  iconState: string;
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
    slot_stealth = 1,
    slot_star = 1,
    slot_heal = 1,
    slot_trap = 1,
    confirmed,
    mod_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi',
  } = data;

  const [selectedTab, setSelectedTab] = useSharedState<'directives' | 'modsuit'>(
    'ninja_info_selected_tab',
    !confirmed ? 'modsuit' : 'directives'
  );

  const slots: SlotDef[] = [
    {
      id: 'stealth',
      title: 'INFILTRATION & MOBILITY',
      slotNum: 1,
      currentValue: slot_stealth,
      options: [
        {
          value: 1,
          title: 'Advanced Mimetic Stealth',
          badge: 'DEFAULT',
          typeTag: 'OPTICAL CLOAK',
          iconState: 'cloak_ninja',
          accentColor: '#c084fc',
          accentBg: 'rgba(192, 132, 252, 0.12)',
          description:
            'Mimetic light-bending field. Zero bump disruption, silent footsteps, minimal suit power draw.',
          statBadge: '50 EN. + 10/S // CLOAK',
        },
        {
          value: 2,
          title: 'Phase Module',
          badge: 'ALTERNATIVE',
          typeTag: 'QUANTUM PHASE',
          iconState: 'phase_ninja',
          accentColor: '#22d3ee',
          accentBg: 'rgba(34, 211, 238, 0.12)',
          description:
            'Displaces suit matter to ghost through solid bulkheads and reinforced walls. Requires a 3s startup channel; cannot attack while active. Heavy power drain.',
          statBadge: '150 EN. + 150/STEP // PHASE',
        },
      ],
    },
    {
      id: 'star',
      title: 'RANGED ORDNANCE',
      slotNum: 2,
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
          statBadge: '20 ENERGY // 0.5S CD // EMP',
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
          statBadge: '20 ENERGY // 7S CD // TETHER',
        },
      ],
    },
    {
      id: 'heal',
      title: 'BIOLOGICAL SUPPORT',
      slotNum: 3,
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
            'Medical nanite matrix injects 2u Sanguirite coagulant and heals 75 Brute + 75 Burn over 15 seconds (5/sec). Consumes 0 suit power; holds 3 charges, refilled with 15u Radium.',
          statBadge: '0 ENERGY // 3 CHARGES // 15U RADIUM',
        },
      ],
    },
    {
      id: 'trap',
      title: 'SUBJUGATION & CONTROL',
      slotNum: 4,
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
          statBadge: '100 ENERGY // 15S CD // HARDLIGHT',
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
            'Projects a lifelike holographic decoy charging targets and absorbing attacks. Grants 2.5s cloaking & speed. Decoy overloads with an EMP flash pulse.',
          statBadge: '60 ENERGY // 12S CD // DECOY',
        },
      ],
    },
  ];

  // Active loadout dossier specifications based on chosen slots
  const chosenDossier: DossierItem[] = [
    slot_stealth === 2
      ? {
          title: 'Phase Module',
          badge: 'SLOT 1',
          typeTag: 'QUANTUM PHASE // MOBILITY',
          iconState: 'phase_ninja',
          accentColor: '#22d3ee',
          controls: 'Pinned Suit Action or Suit Menu (Toggle)',
          power: '150 energy units on activation + 150 units per phase step // 10s cooldown',
          description:
            'Displaces the MODsuit into quantum subspace, granting the ability to ghost directly through reinforced bulkheads, airlocks, and solid terrain without restriction. Requires a 3-second calibration channel to activate (interrupted if damaged, triggering a 10s cooldown). While out of phase or calibrating, dimensional interference prevents attacking any targets. Incurs a 10-second cooldown upon deactivating.',
          tacticalTip:
            'If suit power is depleted or the module is turned off while inside a dense wall, you will be automatically shunted to the nearest open tile. Keep a close watch on your power reserves and remember you cannot attack while phased.',
        }
      : {
          title: 'Advanced Mimetic Stealth',
          badge: 'SLOT 1',
          typeTag: 'OPTICAL CLOAK // INFILTRATION',
          iconState: 'cloak_ninja',
          accentColor: '#c084fc',
          controls: 'Pinned Suit Action or Suit Menu (Toggle)',
          power: '50 energy units on activation + 10 units/sec while active',
          description:
            'Projects a refractive light-bending shield with dynamic chameleonic skin adaptation. Renders the wearer virtually invisible (alpha 20) and completely silences footsteps. Equipped with stabilization dampeners that do NOT break cloak on bumping into objects or crew.',
          tacticalTip:
            'Cloak only disengages when sustaining hostile damage or initiating attacks. Perfect for slipping past sentry turrets and lurking undetected in illuminated hallways.',
        },
    slot_star === 2
      ? {
          title: 'Grappling Kunai Dispenser',
          badge: 'SLOT 2',
          typeTag: 'TETHER HOOK // REEL & DRAG',
          iconState: 'dispenser_kunai',
          accentColor: '#c4b5fd',
          controls: 'Click pinned action to synthesize // Throw at target or structure',
          power: '20 energy units per synthesis // 7.0s cooldown',
          description:
            'Fabricates lightweight titanium kunai linked by high-tensile nanite tow cables (8 force, 12 throwforce, 75 AP, 10 stamina damage). Striking living targets knocks them prone for 2.5 seconds and reels them across the room directly to your feet along a visible tether beam. Striking dense walls or machinery hauls you forward with a smooth, upright landing.',
          tacticalTip:
            'Snatch isolated personnel into dark corridors for silent assassinations while they remain prone, or slingshot across wide corridors and hull breaches to bypass barriers.',
        }
      : {
          title: 'EMP Shuriken Dispenser',
          badge: 'SLOT 2',
          typeTag: 'ION DISRUPTOR // ORDNANCE',
          iconState: 'dispenser_ninja',
          accentColor: '#fbbf24',
          controls: 'Click pinned action to synthesize // Throw at target',
          power: '20 energy units per synthesis // 0.5s cooldown',
          description:
            'Synthesizes monomolecular energy shurikens with embedded electromagnetic discharge emitters. On impact, releases a heavy EMP burst. If embedded in carbon prey, continues pulsing periodically with secondary EMP shocks.',
          tacticalTip:
            'Thrown shurikens are uncatchable. Use them to shut down cyborgs, disable security laser carbines, drain electronics, and extinguish room lighting.',
        },
    slot_heal === 2
      ? {
          title: 'Nanite Cellular Repair Matrix',
          badge: 'SLOT 3',
          typeTag: 'BIOMEDICAL MATRIX // RESTORATION',
          iconState: 'nanite_repair',
          accentColor: '#34d399',
          controls: 'Click pinned action to engage (Usable while incapacitated)',
          power: '0 Energy (Does not consume suit power // 3 charges, refillable with 15u Radium // 15s cooldown)',
          description:
            'Floods your bloodstream with emergency medical nanites and 2u Sanguirite coagulant over a 15-second cycle. Rapidly stops internal bleeding and restores 5 brute and 5 burn damage every second (total 75 brute / 75 burn) along with lost blood volume. Consumes 0 suit power, utilizing internal chemical nanite charges (3 charges capacity, refilled with 15u Radium).',
          tacticalTip:
            'Replaces conventional medical items and operates without touching suit power reserves. After taking damage or bleeding heavily, activate the matrix to clot wounds and regenerate. When empty, reload the suit with 15u Radium.',
        }
      : {
          title: 'Combat Adrenaline Boost',
          badge: 'SLOT 3',
          typeTag: 'STIMULANT SHOCK // NEURAL OVERRIDE',
          iconState: 'adrenaline_boost',
          accentColor: '#fb7185',
          controls: 'Click pinned action to inject (Usable while incapacitated / cuffed)',
          power: '0 Energy (Does not consume suit power // Refillable with 20u Radium // 12s cooldown)',
          description:
            'Triggers an emergency autonomic neuro-chemical override. Instantly purges all stuns, knockdowns, paralysis, and up to 200 stamina damage while flooding the bloodstream with combat stimulants.',
          tacticalTip:
            'The ultimate escape countermeasure. If ambushed by flashbangs, tasers, or stun batons, pop adrenaline immediately to regain control and retaliate before restraints can be placed.',
        },
    slot_trap === 2
      ? {
          title: 'Holographic Decoy Module',
          badge: 'SLOT 4',
          typeTag: 'CYBER DECOY // MISDIRECTION',
          iconState: 'decoy_ninja',
          accentColor: '#00e5ff',
          controls: 'Pinned Suit Action or Suit Menu (Instant Use)',
          power: '60 energy units per deployment // 12s cooldown',
          description:
            'A state-of-the-art Spider Clan misdirection system. When activated, projects a lifelike holographic decoy of the user that charges towards targets, drawing enemy fire and attacks. The ninja enters brief optical camouflage (alpha = 25, silent footsteps, and movement speed bonus) for 2.5 seconds to reposition. Upon taking damage or after 5 seconds, the holographic decoy overloads with an electromagnetic flash pulse, detonating an EMP and blinding/disorienting pursuers in a 2-tile radius.',
          tacticalTip:
            'Trigger the decoy when ambushed or breaching high-threat areas. The decoy will absorb attacks while you sprint invisibly to the enemy rear or slip past security defenses. The overload flash will disorient nearby enemies, opening them up for lethal katana strikes.',
        }
      : {
          title: 'Energy Net Projector',
          badge: 'SLOT 4',
          typeTag: 'HARDLIGHT RESTRAINT // CAPTURE',
          iconState: 'energy_net',
          accentColor: '#38bdf8',
          controls: 'Select action and target mob with ranged projector',
          power: '100 energy units per shot // 15s cooldown',
          description:
            'Fires an expanding hardlight projector that establishes a reinforced capture cage around the target, locking them in place on the tile and preventing all movement until dismantled or destroyed.',
          tacticalTip:
            'Ideal for taking key station personnel alive or neutralizing aggressive pursuers without wasting lethal blade energy.',
        },
  ];

  const coreSystems: DossierItem[] = [
    {
      title: 'Energy Katana & Weapon Recall',
      badge: 'CORE WEAPON',
      typeTag: 'PLASMA BLADE // DNA-BONDED',
      iconState: 'recall',
      accentColor: '#e11d48',
      controls: 'RMB Recall action to summon blade // LMB strike & reflect // Combat Dash',
      power: 'Low recall cost (0.5s cooldown)',
      description:
        'Monomolecular plasma blade genetically bonded to your DNA. Slices through heavy armor and deflects incoming energy projectiles. Can be recalled directly to your hands or sheath across any distance. Forbids firearm usage.',
      tacticalTip:
        'Throw your katana through windows or at fleeing targets, then recall it instantaneously to your hands. You can never be disarmed.',
    },
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
        'Whenever battery levels dwindle after phasing or cloaking, slip into maintenance and drain the nearest APC.',
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
                        <strong>Spider Clan Temporal Infiltration Protocol:</strong> Phase-cloaking nanites and localized vacuum shielding are fully active. Your position is concealed from station sensors. Moving, engaging targets, or manual confirmation will calibrate suit systems.
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

                {/* 4 Slot Selection Cards */}
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
                            SELECT 1 OF 2
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
                                              : opt.accentColor + '55'
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
                                    icon={mod_icon}
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
                                    icon={mod_icon}
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
