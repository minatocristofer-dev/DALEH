import { PrismaClient, ModalidadeKey } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Modalidades — mesmo conjunto usado no protótipo (MODALIDADES em protótipo em React)
  await prisma.modalidade.upsert({
    where: { key: ModalidadeKey.FUTSAL },
    update: {},
    create: {
      key: ModalidadeKey.FUTSAL,
      label: 'Futsal',
      positions: ['Goleiro', 'Fixo', 'Ala', 'Pivô'],
    },
  });

  await prisma.modalidade.upsert({
    where: { key: ModalidadeKey.SOCIETY },
    update: {},
    create: {
      key: ModalidadeKey.SOCIETY,
      label: 'Society/Campo 7',
      positions: ['Goleiro', 'Zagueiro', 'Lateral', 'Meia', 'Atacante'],
    },
  });

  await prisma.modalidade.upsert({
    where: { key: ModalidadeKey.CAMPO11 },
    update: {},
    create: {
      key: ModalidadeKey.CAMPO11,
      label: 'Campo 11',
      positions: ['Goleiro', 'Zagueiro', 'Lateral', 'Volante', 'Meia', 'Atacante'],
    },
  });

  // Papéis de RBAC — conforme seção 1.2 da arquitetura
  const roles = ['player', 'team_admin', 'venue_owner', 'organizer', 'referee', 'platform_admin'];
  for (const key of roles) {
    await prisma.role.upsert({ where: { key }, update: {}, create: { key } });
  }

  console.log('Seed concluído: modalidades e papéis criados.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
