const request = require('supertest');
const app = require('./server');

describe('app', () => {
    it('GET / returns greeting', async () => {
        const res = await request(app).get('/');
        expect(res.statusCode).toBe(200);
        expect(res.text).toMatch(/Hello from Node\.js/);
    });

    it('GET /healthz returns ok', async () => {
        const res = await request(app).get('/healthz');
        expect(res.statusCode).toBe(200);
        expect(res.text).toBe('ok');
    });
});
