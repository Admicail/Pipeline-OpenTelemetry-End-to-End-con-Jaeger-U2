import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL;

if (!BASE_URL) {
    throw new Error('Debe especificarse BASE_URL');
}

export const options = {
    scenarios: {
        warmup: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 10 }
            ],
            gracefulRampDown: '0s'
        },

        sustained_load: {
            executor: 'constant-vus',
            vus: 50,
            duration: '3m',
            startTime: '1m'
        },

        spike: {
            executor: 'ramping-vus',
            startVUs: 50,
            startTime: '4m',
            stages: [
                { duration: '20s', target: 100 },
                { duration: '20s', target: 100 },
                { duration: '20s', target: 50 }
            ],
            gracefulRampDown: '0s'
        }
    },

    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: [
            'p(95)<500',
            'p(99)<1000'
        ],
        checks: ['rate>0.99']
    }
};

export default function () {

    const input = `k6-${__VU}-${__ITER}`;
    const url = http.url`${BASE_URL}/request?input=${input}`;

    const response = http.get(
        url
    );

    check(response, {
        'HTTP status 200': (r) => r.status === 200
    });
}
