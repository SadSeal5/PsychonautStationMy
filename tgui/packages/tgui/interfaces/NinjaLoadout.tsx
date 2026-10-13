import { Box, Button, DmIcon, Flex, Icon, NoticeBox, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  in_setup: boolean;
  slot_stealth: number;
  slot_star: number;
  slot_heal: number;
  slot_trap: number;
  confirmed: boolean;
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

export const NinjaLoadout = () => {
  const { act, data } = useBackend<Data>();
  const {
    in_setup,
    slot_stealth = 1,
    slot_star = 1,
    slot_heal = 1,
    slot_trap = 1,
    confirmed,
    mod_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi',
  } = data;

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
          statBadge: 'SILENT // 0-BUMP',
        },
        {
          value: 2,
          title: 'Pure Phasing Module',
          badge: 'ALTERNATIVE',
          typeTag: 'QUANTUM PHASE',
          iconState: 'phase_ninja',
          accentColor: '#22d3ee',
          accentBg: 'rgba(34, 211, 238, 0.12)',
          description:
            'Displaces suit matter to ghost through solid bulkheads and reinforced walls. Consumes suit power per step.',
          statBadge: 'NO-CLIP // DRAIN',
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
          statBadge: 'EMP BURST // RANGED',
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
            'Throws high-tensile tethered kunai. Stuns and drags targets close, or reels the user rapidly to walls.',
          statBadge: 'PULL // STUN // ZIP',
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
          statBadge: 'ANTI-STUN // SPEED',
        },
        {
          value: 2,
          title: 'Nanite Cellular Repair',
          badge: 'ALTERNATIVE',
          typeTag: 'BIOMEDICAL MATRIX',
          iconState: 'nanite_repair',
          accentColor: '#34d399',
          accentBg: 'rgba(52, 211, 153, 0.12)',
          description:
            'Medical nanite matrix rapidly seals lacerations and repairs heavy brute and thermal burn trauma over 5 seconds.',
          statBadge: '150 BRUTE+BURN // SUIT PWR',
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
          title: 'Energy Net Module',
          badge: 'DEFAULT',
          typeTag: 'HARDLIGHT RESTRAINT',
          iconState: 'energy_net',
          accentColor: '#38bdf8',
          accentBg: 'rgba(56, 189, 248, 0.12)',
          description:
            'Fires an active hardlight projector deploying a reinforced capture barrier to securely anchor targets.',
          statBadge: 'HARDLIGHT // TILE LOCK',
        },
        {
          value: 2,
          title: 'Shadow Bind Module',
          badge: 'ALTERNATIVE',
          typeTag: 'VOID RESTRICTION',
          iconState: 'shadow_bind',
          accentColor: '#a855f7',
          accentBg: 'rgba(168, 85, 247, 0.12)',
          description:
            'Launches dark void nanites that erupt into shadowy tendrils: roots victim on tile, forces disarm, shocks & silences.',
          statBadge: 'ROOT // DISARM // SILENCE',
        },
      ],
    },
  ];

  return (
    <Window title="Spider Clan Loadout Matrix" width={740} height={690}>
      <Window.Content scrollable>
        <Stack vertical fill g={2} p={1}>
          {/* Header Status Banner */}
          <Stack.Item>
            {in_setup ? (
              <NoticeBox success>
                <Flex align="center" justify="space-between">
                  <Flex.Item>
                    <Icon name="shield-alt" mr={1} />
                    <strong>STASIS CLOAK ENGAGED:</strong> Temporal cloaking and godmode active.
                    Moving, attacking, or the 3-minute timeout will decloak and lock in suit equipment.
                  </Flex.Item>
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
                      STEALTH ACTIVE
                    </Box>
                  </Flex.Item>
                </Flex>
              </NoticeBox>
            ) : confirmed ? (
              <NoticeBox info>
                <Icon name="check-double" mr={1} />
                <strong>LOADOUT SYNCHRONIZED:</strong> MODsuit synthesized and all tactical modules pinned.
              </NoticeBox>
            ) : (
              <NoticeBox danger>
                <Icon name="exclamation-triangle" mr={1} />
                <strong>CLOAKING DROPPED:</strong> Combat profile exposed. Reconfigure or confirm your setup below.
              </NoticeBox>
            )}
          </Stack.Item>

          {/* Module Slots */}
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
                            {/* Standalone Sprite Container */}
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

                            {/* Text Info */}
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
              fontSize="1.25em"
              lineHeight="2.4"
              textAlign="center"
              bold
              onClick={() => act('confirm')}
              style={{
                boxShadow: '0 0 16px rgba(16, 185, 129, 0.3)',
                letterSpacing: '1px',
              }}
            >
              CONFIRM LOADOUT & SYNCHRONIZE MODSUIT
            </Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
