import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('THCP API (e2e)', () => {
  let app: INestApplication;
  let ownerToken: string;
  let renterToken: string;
  let workerToken: string;
  let employerToken: string;
  let propertyId: string;
  let workerProfileId: string;
  let jobId: string;
  let viewingId: string;

  const api = () => request(app.getHttpServer());
  const prefix = '/api/v1';

  async function login(phone: string, role?: string) {
    const otpRes = await api()
      .post(`${prefix}/auth/otp/request`)
      .send({ phone, role })
      .expect(201);
    const code = otpRes.body.devCode;
    expect(code).toBeDefined();
    const verifyRes = await api()
      .post(`${prefix}/auth/otp/verify`)
      .send({ phone, code, role })
      .expect(201);
    return verifyRes.body.accessToken as string;
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health', () => {
    return api().get(`${prefix}/health`).expect(200).expect((res) => {
      expect(res.body.status).toBe('ok');
    });
  });

  it('auth + users flow', async () => {
    ownerToken = await login('0911000001', 'owner');
    renterToken = await login('0911000002', 'renter');
    workerToken = await login('0911000003', 'worker');
    employerToken = await login('0911000004', 'employer');

    const me = await api()
      .get(`${prefix}/users/me`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);
    expect(me.body.phone).toBeDefined();
    expect(me.body.nationalIdUrl).toBeUndefined();
    expect(me.body.trustScore).toBeDefined();
  });

  it('properties CRUD', async () => {
    const created = await api()
      .post(`${prefix}/properties`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        title: 'Test Flat Kazanchis',
        description: 'Spacious flat near stadium with parking.',
        priceEtb: 12000,
        bedrooms: 3,
      })
      .expect(201);
    propertyId = created.body.id;

    await api()
      .post(`${prefix}/properties/${propertyId}/verify`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(403);

    const search = await api().get(`${prefix}/properties`).expect(200);
    expect(search.body.items).toBeDefined();

    const detail = await api().get(`${prefix}/properties/${propertyId}`).expect(404);
    expect(detail.body.statusCode).toBe(404);
  });

  it('admin verify property', async () => {
    const adminToken = await login('0911000005', 'admin');
    await api()
      .post(`${prefix}/properties/${propertyId}/verify`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(201);

    await api().get(`${prefix}/properties/${propertyId}`).expect(200);
  });

  it('viewings flow', async () => {
    const viewing = await api()
      .post(`${prefix}/viewings`)
      .set('Authorization', `Bearer ${renterToken}`)
      .send({ propertyId, notes: 'Weekend viewing' })
      .expect(201);
    viewingId = viewing.body.id;

    const scheduled = new Date(Date.now() + 86400000).toISOString();
    await api()
      .patch(`${prefix}/viewings/${viewingId}/schedule`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ scheduledAt: scheduled })
      .expect(200);

    const list = await api()
      .get(`${prefix}/viewings`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);
    expect(Array.isArray(list.body)).toBe(true);
  });

  it('workers + jobs flow', async () => {
    const profile = await api()
      .put(`${prefix}/workers/me`)
      .set('Authorization', `Bearer ${workerToken}`)
      .send({
        skills: ['cleaning', 'cooking'],
        availability: 'full-time',
        salaryExpectation: 4000,
        bio: 'Reliable worker with references.',
      })
      .expect(200);
    workerProfileId = profile.body.id;

    const job = await api()
      .post(`${prefix}/jobs`)
      .set('Authorization', `Bearer ${employerToken}`)
      .send({
        jobType: 'maid',
        location: 'Bole',
        salaryOffer: 5000,
        requirements: 'Live-in preferred',
      })
      .expect(201);
    jobId = job.body.id;

    await api()
      .post(`${prefix}/jobs/${jobId}/apply/${workerProfileId}`)
      .set('Authorization', `Bearer ${workerToken}`)
      .expect(201);

    const workers = await api().get(`${prefix}/workers`).expect(200);
    expect(Array.isArray(workers.body)).toBe(true);
  });

  it('reviews + trust + notifications', async () => {
    const ownerMe = await api()
      .get(`${prefix}/users/me`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    await api()
      .post(`${prefix}/reviews`)
      .set('Authorization', `Bearer ${renterToken}`)
      .send({
        revieweeId: ownerMe.body.id,
        entityType: 'property',
        entityId: propertyId,
        rating: 5,
        comment: 'Great listing',
      })
      .expect(201);

    await api()
      .get(`${prefix}/users/${ownerMe.body.id}/trust-score`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    const notifications = await api()
      .get(`${prefix}/notifications`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);
    expect(Array.isArray(notifications.body)).toBe(true);
  });
});
