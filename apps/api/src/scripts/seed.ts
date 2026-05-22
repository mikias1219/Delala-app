import { DataSource, In } from 'typeorm';
import { PropertyStatus } from '../common/enums/property-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { entities } from '../database/database.module';
import { JobPost } from '../modules/jobs/entities/job-post.entity';
import { Property } from '../modules/properties/entities/property.entity';
import { User } from '../modules/users/entities/user.entity';
import { WorkerProfile } from '../modules/workers/entities/worker-profile.entity';
import { JobStatus } from '../common/enums/job-status.enum';

const SEED_PHONES = {
  owner: '+251911000001',
  renter: '+251911000002',
  worker: '+251911000003',
  employer: '+251911000004',
  admin: '+251911000005',
};

async function seed() {
  const ds = new DataSource({
    type: 'postgres',
    host: process.env.DATABASE_HOST ?? 'localhost',
    port: parseInt(process.env.DATABASE_PORT ?? '5435', 10),
    username: process.env.DATABASE_USER ?? 'delala',
    password: process.env.DATABASE_PASSWORD ?? 'delala_dev_password',
    database: process.env.DATABASE_NAME ?? 'delala',
    entities,
    synchronize: true,
  });

  await ds.initialize();

  const usersRepo = ds.getRepository(User);
  const propertiesRepo = ds.getRepository(Property);
  const workersRepo = ds.getRepository(WorkerProfile);
  const jobsRepo = ds.getRepository(JobPost);

  const existing = await usersRepo.count();
  if (existing > 0) {
    console.log(`Database already has ${existing} user(s). Skipping seed (run with FORCE_SEED=1 to re-seed).`);
    if (process.env.FORCE_SEED !== '1') {
      await ds.destroy();
      return;
    }
    console.log('FORCE_SEED=1 — clearing seed users and related demo data…');
    await jobsRepo.delete({});
    await workersRepo.delete({});
    await propertiesRepo.delete({});
    await usersRepo.delete({ phone: In(Object.values(SEED_PHONES)) });
  }

  const owner = await usersRepo.save(
    usersRepo.create({
      phone: SEED_PHONES.owner,
      role: UserRole.OWNER,
      fullName: 'Test Owner',
      status: UserStatus.ACTIVE,
      verifiedAt: new Date(),
    }),
  );

  const renter = await usersRepo.save(
    usersRepo.create({
      phone: SEED_PHONES.renter,
      role: UserRole.RENTER,
      fullName: 'Test Renter',
      status: UserStatus.ACTIVE,
      verifiedAt: new Date(),
    }),
  );

  const workerUser = await usersRepo.save(
    usersRepo.create({
      phone: SEED_PHONES.worker,
      role: UserRole.WORKER,
      fullName: 'Test Worker',
      status: UserStatus.ACTIVE,
      verifiedAt: new Date(),
    }),
  );

  const employer = await usersRepo.save(
    usersRepo.create({
      phone: SEED_PHONES.employer,
      role: UserRole.EMPLOYER,
      fullName: 'Test Employer',
      status: UserStatus.ACTIVE,
      verifiedAt: new Date(),
    }),
  );

  await usersRepo.save(
    usersRepo.create({
      phone: SEED_PHONES.admin,
      role: UserRole.ADMIN,
      fullName: 'Test Admin',
      status: UserStatus.ACTIVE,
      verifiedAt: new Date(),
    }),
  );

  const property = await propertiesRepo.save(
    propertiesRepo.create({
      ownerId: owner.id,
      title: '2BR Apartment in Bole',
      description: 'Bright apartment near Edna Mall, furnished, secure compound.',
      priceEtb: '15000',
      bedrooms: 2,
      lat: '8.9975',
      lng: '38.7895',
      status: PropertyStatus.VERIFIED,
      verifiedAt: new Date(),
    }),
  );

  const workerProfile = await workersRepo.save(
    workersRepo.create({
      userId: workerUser.id,
      skills: ['cleaning', 'cooking', 'childcare'],
      availability: 'full-time',
      salaryExpectation: '4500',
      bio: '5 years experience with families in Bole and CMC.',
      ratingAvg: '4.5',
    }),
  );

  await jobsRepo.save(
    jobsRepo.create({
      employerId: employer.id,
      jobType: 'live-in maid',
      location: 'Bole, Addis Ababa',
      salaryOffer: '5000',
      requirements: 'Experience with toddlers preferred',
      status: JobStatus.OPEN,
    }),
  );

  console.log('Seed complete. Test phones (login with any role chip + OTP from API):');
  console.log({
    owner: '0911000001',
    renter: '0911000002',
    worker: '0911000003',
    employer: '0911000004',
    admin: '0911000005',
    verifiedPropertyId: property.id,
    workerProfileId: workerProfile.id,
  });

  await ds.destroy();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
