import Fastify, { type FastifyInstance } from 'fastify';

export type HealthResponse = {
  status: 'ok';
};

export function buildApp(): FastifyInstance {
  const app = Fastify({ logger: true });

  app.get('/health', (): HealthResponse => ({ status: 'ok' }));

  return app;
}
