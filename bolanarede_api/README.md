# BolaNaRede API

Monorepo de microserviços NestJS para a plataforma BolaNaRede.

## Estrutura

```
bolanarede_api/
├── shared/          # Módulo compartilhado (@shared/* path alias)
├── services/
│   ├── identity/    # Autenticação e perfil de usuário (porta 4001)
│   └── ...          # Demais serviços (em desenvolvimento)
├── docs/plans/      # Planos de implementação
├── tsconfig.base.json
├── biome.json
└── docker-compose.yml
```

## Pré-requisitos

- Node.js 22+
- Docker + Docker Compose

## Rodando com Docker

```bash
docker compose up --build
```

Serviços disponíveis:
- **Identity API**: http://localhost:4001
- **Swagger**: http://localhost:4001/docs
- **RabbitMQ Management**: http://localhost:15672 (admin/admin)
- **PostgreSQL Identity**: localhost:5432

## Desenvolvimento local (sem Docker)

```bash
# Identity service
cd services/identity
cp .env.example .env
npm install
npm run db:generate
npm run db:migrate
npm run start:dev
```

## Serviços implementados

| Serviço    | Porta | Status |
|------------|-------|--------|
| identity   | 4001  | ✅ Completo |
| team       | 4002  | ⏳ Pendente |
| field      | 4003  | ⏳ Pendente |
| open-game  | 4004  | ⏳ Pendente |
| social     | 4005  | ⏳ Pendente |
| gamification | 4006 | ⏳ Pendente |
| matchmaking | 4007 | ⏳ Pendente |
| game       | 4008  | ⏳ Pendente |
| ranking    | 4009  | ⏳ Pendente |
| notification | 4010 | ⏳ Pendente |
