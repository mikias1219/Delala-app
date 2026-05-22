import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Delala API (e2e)', () => {
  let app: INestApplication;
  let ownerToken: string;
  let renterToken: string;
  let workerToken: string;
  let employerToken: string;
  let adminToken: string;
  let propertyId: string;
  let workerProfileId: string;
  let jobId: string;
  let viewingId: string;
  let ownerId: string;

  const api = () => request(app.getHttpServer());
  const prefix = '/api/v1';

  async function login(phone: string) {
    const otpRes = await api()
      .post(`${prefix}/auth/otp/request`)
      .send({ phone, isRegistration: false })
      .expect(201);
    const code = otpRes.body.devCode;
    expect(code).toBeDefined();
    const verifyRes = await api()
      .post(`${prefix}/auth/otp/verify`)
      .send({ phone, code })
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
    ownerToken = await login('0911000001');
    renterToken = await login('0911000002');
    workerToken = await login('0911000003');
    employerToken = await login('0911000004');
    adminToken = await login('0911000005');

    const me = await api()
      .get(`${prefix}/users/me`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);
    expect(me.body.phone).toBeDefined();
    expect(me.body.nationalIdUrl).toBeUndefined();
    expect(me.body.trustScore).toBeDefined();
    expect(me.body.trustScore.breakdownJson ?? me.body.trustScore.breakdown_json).toBeDefined();
  });

  it('permissions: renter cannot search workers', async () => {
    await api()
      .get(`${prefix}/workers`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(403);
  });

  it('permissions: admin cannot post reviews', async () => {
    const ownerMe = await api()
      .get(`${prefix}/users/me`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    await api()
      .post(`${prefix}/reviews`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        revieweeId: ownerMe.body.id,
        entityType: 'property',
        entityId: '00000000-0000-0000-0000-000000000001',
        rating: 5,
      })
      .expect(403);
  });

  it('properties CRUD + owner edit', async () => {
    const created = await api()
      .post(`${prefix}/properties`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        title: 'Test Flat Kazanchis',
        description: 'Spacious flat near stadium with parking.',
        priceEtb: 12000,
        bedrooms: 3,
        lat: 9.03,
        lng: 38.75,
      })
      .expect(201);
    propertyId = created.body.id;

    await api()
      .post(`${prefix}/properties/${propertyId}/verify`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(403);

    await api()
      .patch(`${prefix}/properties/${propertyId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ title: 'Updated Flat Kazanchis' })
      .expect(200);

    const search = await api()
      .get(`${prefix}/properties`)
      .query({ lat: 9.03, lng: 38.75 })
      .expect(200);
    expect(search.body.items).toBeDefined();

    await api().get(`${prefix}/properties/${propertyId}`).expect(404);
  });

  it('admin verify property + user', async () => {
    await api()
      .post(`${prefix}/properties/${propertyId}/verify`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(201);

    const detail = await api().get(`${prefix}/properties/${propertyId}`).expect(200);
    expect(detail.body.owner?.phone).toBeUndefined();

    const ownerMe = await api()
      .get(`${prefix}/users/me`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    ownerId = ownerMe.body.id;

    await api()
      .post(`${prefix}/users/${ownerId}/verify`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(201);
  });

  it('viewings flow + contact after confirm', async () => {
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

    const contact = await api()
      .get(`${prefix}/users/${ownerId}/contact`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);
    expect(contact.body.phone).toBeDefined();

    const list = await api()
      .get(`${prefix}/viewings`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);
    expect(Array.isArray(list.body)).toBe(true);
  });

  it('workers + jobs flow (employer search)', async () => {
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

    const workers = await api()
      .get(`${prefix}/workers`)
      .set('Authorization', `Bearer ${employerToken}`)
      .expect(200);
    expect(Array.isArray(workers.body)).toBe(true);
    if (workers.body[0]?.user) {
      expect(workers.body[0].user.phone).toBeUndefined();
    }
  });

  it('reviews + trust breakdown + notifications', async () => {
    await api()
      .post(`${prefix}/reviews`)
      .set('Authorization', `Bearer ${renterToken}`)
      .send({
        revieweeId: ownerId,
        entityType: 'property',
        entityId: propertyId,
        rating: 5,
        comment: 'Great listing',
      })
      .expect(201);

    const trust = await api()
      .get(`${prefix}/users/${ownerId}/trust-score`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(trust.body.score).toBeGreaterThanOrEqual(30);
    expect(trust.body.badge).toBeDefined();
    const breakdown =
      trust.body.breakdownJson ?? trust.body.breakdown_json;
    expect(breakdown).toBeDefined();
    expect(breakdown.identity).toBe(30);

    const ownerNotifications = await api()
      .get(`${prefix}/notifications`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(
      ownerNotifications.body.some(
        (n: { type: string }) => n.type === 'viewing_requested',
      ),
    ).toBe(true);
  });

  it('admin can suspend and reinstate users', async () => {
    const renterMe = await api()
      .get(`${prefix}/users/me`)
      .set('Authorization', `Bearer ${renterToken}`)
      .expect(200);

    await api()
      .post(`${prefix}/users/${renterMe.body.id}/suspend`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(201);

    await api()
      .post(`${prefix}/users/${renterMe.body.id}/reinstate`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(201);
  });
});
