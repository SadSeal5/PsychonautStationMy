import { Box, Button, Icon, NoticeBox, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  in_setup: boolean;
  slot_stealth: number;
  slot_star: number;
  slot_heal: number;
  slot_trap: number;
  confirmed: boolean;
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
  } = data;

  return (
    <Window title="Spider Clan Infiltration Loadout" width={650} height={520} theme="hackerman">
      <Window.Content scrollable>
        <Stack vertical fill g={2}>
          <Stack.Item>
            {in_setup ? (
              <NoticeBox success>
                <Icon name="shield-alt" mr={1} />
                <strong>Setup Phase Active:</strong> Temporal cloaking and stasis invulnerability engaged.
                Moving, attacking, or a 3-minute timeout will break cloaking and finalize your loadout.
              </NoticeBox>
            ) : confirmed ? (
              <NoticeBox info>
                <Icon name="check-circle" mr={1} />
                <strong>Loadout Confirmed:</strong> MODsuit synthesized and active.
              </NoticeBox>
            ) : (
              <NoticeBox danger>
                <Icon name="exclamation-triangle" mr={1} />
                <strong>Cloaking Dropped:</strong> Finalize or reconfigure your equipment.
              </NoticeBox>
            )}
          </Stack.Item>

          {/* Slot 1: Mobility & Concealment */}
          <Stack.Item>
            <Section title="Slot 1: Infiltration & Mobility" fill>
              <Stack fill g={2}>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_stealth === 1 ? 'good' : 'default'}
                    selected={slot_stealth === 1}
                    icon="user-ninja"
                    onClick={() => act('set_slot', { slot: 'stealth', value: 1 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Advanced Stealth</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Mimetic light-bending field. Zero bump disruption, silent footsteps.
                    </Box>
                  </Button>
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_stealth === 2 ? 'good' : 'default'}
                    selected={slot_stealth === 2}
                    icon="ghost"
                    onClick={() => act('set_slot', { slot: 'stealth', value: 2 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Pure Phasing Module</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Quantum phase-shift through dense walls & obstacles. Drains suit power per step.
                    </Box>
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {/* Slot 2: Ranged Ordnance */}
          <Stack.Item>
            <Section title="Slot 2: Ranged Ordnance" fill>
              <Stack fill g={2}>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_star === 1 ? 'good' : 'default'}
                    selected={slot_star === 1}
                    icon="bolt"
                    onClick={() => act('set_slot', { slot: 'star', value: 1 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">EMP Shuriken Dispenser</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Materializes monomolecular shuriken emitting high-grade EMP bursts.
                    </Box>
                  </Button>
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_star === 2 ? 'good' : 'default'}
                    selected={slot_star === 2}
                    icon="crosshairs"
                    onClick={() => act('set_slot', { slot: 'star', value: 2 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Grappling Kunai Dispenser</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Throws tethered kunai. Yanks targets in with stun, or zips user to walls.
                    </Box>
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {/* Slot 3: Sustain & Support */}
          <Stack.Item>
            <Section title="Slot 3: Biological Support" fill>
              <Stack fill g={2}>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_heal === 1 ? 'good' : 'default'}
                    selected={slot_heal === 1}
                    icon="syringe"
                    onClick={() => act('set_slot', { slot: 'heal', value: 1 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Adrenaline Boost</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Clears immobility and paralysis, restores stamina, injects combat stimulants.
                    </Box>
                  </Button>
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_heal === 2 ? 'good' : 'default'}
                    selected={slot_heal === 2}
                    icon="heartbeat"
                    onClick={() => act('set_slot', { slot: 'heal', value: 2 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Nanite Cellular Repair</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Consumes power to rapidly heal heavy brute & burn trauma over 5 seconds.
                    </Box>
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {/* Slot 4: Crowd Control */}
          <Stack.Item>
            <Section title="Slot 4: Subjugation & Control" fill>
              <Stack fill g={2}>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_trap === 1 ? 'good' : 'default'}
                    selected={slot_trap === 1}
                    icon="network-wired"
                    onClick={() => act('set_slot', { slot: 'trap', value: 1 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Energy Net Module</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Deploys high-durability hardlight capture field to trap targets.
                    </Box>
                  </Button>
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Button
                    fluid
                    color={slot_trap === 2 ? 'good' : 'default'}
                    selected={slot_trap === 2}
                    icon="spider"
                    onClick={() => act('set_slot', { slot: 'trap', value: 2 })}
                    style={{ height: '70px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
                  >
                    <Box bold fontSize="1.1em">Shadow Bind Module</Box>
                    <Box fontSize="0.85em" color="label" mt={0.5}>
                      Fires shadow tendrils: roots victim on tile, forces disarm, shocks & silences.
                    </Box>
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {/* Confirm Button */}
          <Stack.Item mt={1}>
            <Button
              fluid
              color="green"
              icon="check"
              fontSize="1.2em"
              lineHeight="2.2"
              textAlign="center"
              onClick={() => act('confirm')}
            >
              Confirm Loadout & Synthesize MODsuit
            </Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
