import { type Antagonist, Category } from '../base';

export const SHADOWLING_MECHANICAL_DESCRIPTION = `
Stalk from the darkness and spread your collective consciousness.
Enthrall crewmembers into loyal thralls, unlock devastating hive abilities,
and ascend into an all-powerful being of pure shadow.
`;

const Shadowling: Antagonist = {
  key: 'shadowling',
  name: 'Shadowling',
  description: [
    `
      Ancient alien entities lurking in the shadows, seeking to dominate
      the station by converting crew into their hive mind.
    `,
    SHADOWLING_MECHANICAL_DESCRIPTION,
  ],
  category: Category.Roundstart,
};

export default Shadowling;
