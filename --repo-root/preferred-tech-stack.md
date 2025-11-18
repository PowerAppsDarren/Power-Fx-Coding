# PROJECT INSTRUCTIONS: Full-Stack App Development with Claude Code

## Project Purpose
This project is dedicated to building production-grade full-stack database web applications using Claude Code for autonomous development. All applications will be self-hosted on Hostinger KVM8 VPS servers with maximum efficiency and minimal human intervention.

## Core Development Philosophy

**CRITICAL PRINCIPLES:**
- **Convention over flexibility** - Predictable patterns dramatically improve AI code quality
- **Type safety over speed** - TypeScript strict mode catches 60-80% of AI hallucinations at compile time
- **Documentation investment yields 15x ROI** - 20% more time on documentation = 3-5x better AI output
- **Start simple, scale when needed** - Avoid premature optimization; migrate when concrete needs emerge

## Mandatory Tech Stack

### Backend
- **Framework:** NestJS with Fastify adapter
- **Language:** TypeScript with strict mode ENABLED
- **Why:** Convention-over-configuration architecture creates predictable patterns AI excels at generating. Fastify adapter delivers 3x better performance (50k req/s vs 17k). Rigid structure with decorators and dependency injection produces highly maintainable code with minimal human intervention.

### Frontend
- **Framework:** Vue 3 with Composition API
- **Language:** TypeScript (strict mode)
- **Build Tool:** Vite
- **Why:** Better convention-based structure than React reduces AI choice overload. 70%+ developer satisfaction. Composition API more predictable than React hooks. Single-file components provide clear separation AI comprehends well.
- **Alternative if team requires:** React + TypeScript (expect more review for state management)
- **Alternative for performance:** Svelte + SvelteKit (60-70% smaller bundles, superior runtime)

### Database
- **Primary:** PostgreSQL 16
- **Vector Extension:** pgvector 0.7.0+
- **Why:** Unified approach (one database, one backup strategy, one monitoring system). Handles <50M vectors efficiently. ACID transactions across relational and vector data. Recent improvements: 57% storage reduction, 66% index size reduction.
- **When to add Qdrant:** Only when vector operations >30% of queries, scale >50M vectors, or need <10ms latency

### ORM
- **Required:** Prisma
- **Why:** Schema-first approach creates single source of truth. Generated clients provide full type inference. Catches 60-80% AI hallucinations at compile time. Excellent VS Code integration and documentation.

### Testing
- **E2E Testing:** Playwright
- **Unit Testing:** Jest
- **Why:** Playwright 88.68% faster than Cypress. Standard async/await syntax (not custom chaining) means better AI-generated test code. Built-in parallelization, cross-browser support including Safari/WebKit. Industry consensus among AI-powered testing tools.

### Logging & Monitoring
- **Logging:** Pino with async configuration
- **Error Tracking:** GlitchTip (self-hosted)
- **Why Pino:** 5x better performance than Winston. 20-100x throughput increases in high-traffic scenarios. Minimal resource footprint on VPS.
- **Why GlitchTip:** Only 4 components vs Sentry's 12+. 123MB Docker image, 1-2GB RAM. Sentry SDK compatible (drop-in replacement). Built-in uptime monitoring. $15-25/month allocation vs Sentry's 8GB+ RAM requirement.

### Infrastructure
- **Orchestration:** Docker Compose (start) → k3s (scale when needed)
- **Version Control:** Forgejo with Actions
- **Deployment:** Hostinger KVM8 VPS (8 vCPU, 32GB RAM, 400GB NVMe)
- **Why Docker Compose:** Minimal overhead (50-100MB RAM). Simple YAML. Perfect for single-host deployments. Aligns with AI-generated infrastructure-as-code.
- **Why Forgejo:** 512MB-1GB RAM usage. GitHub Actions-compatible CI/CD. Community-driven, faster security patches than Gitea. Single binary deployment.

### Desktop Applications (if needed)
- **Preferred:** Tauri (30-40x smaller bundles, 150-200MB RAM vs Electron's 500MB+)
- **Acceptable:** Electron (if ecosystem/familiarity requirements justify 500MB+ memory usage)

## TypeScript Configuration Requirements

**YOU MUST enable strict mode in tsconfig.json:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true
  }
}
```

**CRITICAL:** TypeScript strict mode is NON-NEGOTIABLE. This catches precisely the categories of mistakes AI makes. Real-world case studies show 40-50% reduction in iteration count and 50%+ decrease in debugging time.

## Code Generation Patterns

### DO USE (These patterns improve AI code quality):

**Discriminated Unions (Type Safety):**
```typescript
// GOOD - Prevents invalid states
interface BaseAnnotation {
  id: string;
  timestamp: Date;
}

interface Note extends BaseAnnotation {
  kind: "note";
  content: string;
}

interface Highlight extends BaseAnnotation {
  kind: "highlight";
  quote: string;
  color: string;
}

type Annotation = Note | Highlight;
```

**Feature-Based Organization:**
```
src/
  features/
    auth/
      components/
      hooks/
      api/
      types/
    posts/
      components/
      hooks/
      api/
      types/
```

**Convention-Heavy Patterns:**
- NestJS decorators (@Controller, @Injectable, @Module)
- Vue 3 Composition API with script setup
- Prisma schema as single source of truth
- Explicit type definitions over implicit inference

### DO NOT USE (These confuse AI):

**❌ Optional Properties Allowing Invalid States:**
```typescript
// BAD - Allows impossible combinations
interface Annotation {
  kind: "note" | "highlight";
  content?: string;
  quote?: string;
}
```

**❌ Overly Abstract Patterns:**
- Deep inheritance hierarchies
- "Clever" metaprogramming
- Excessive design pattern usage
- Abstract architectures without clear boundaries

**❌ Any Type Usage:**
```typescript
// NEVER DO THIS
const data: any = fetchData();
```

## File Structure Requirements

### Root Directory Files

**MUST HAVE: CLAUDE.md**
This file provides AI context for the entire project. Include:
- Tech stack with specific versions
- Project structure with folder purposes
- All development commands (dev, build, test, typecheck)
- Code style preferences with concrete examples
- Explicit "DO NOT" restrictions

**Example CLAUDE.md Structure:**
```markdown
# Project: [App Name]

## Tech Stack
- Backend: NestJS 10.x with Fastify
- Frontend: Vue 3.4+ with TypeScript 5.3+
- Database: PostgreSQL 16 + pgvector 0.7.0+
- ORM: Prisma 5.x

## Project Structure
/src
  /backend - NestJS API server
    /modules - Feature modules
    /common - Shared utilities
  /frontend - Vue 3 application
    /features - Feature-based components
    /composables - Reusable composition functions

## Commands
- `npm run dev` - Start dev servers
- `npm run build` - Production build
- `npm run test` - Run all tests
- `npm run typecheck` - TypeScript validation

## Code Style
- Arrow functions for components
- Composition API with script setup
- No class components
- Explicit return types on functions

## DO NOT
- **DO NOT** edit files in /src/legacy/
- **DO NOT** use class components
- **DO NOT** bypass TypeScript strict checks
- **DO NOT** use any type
```

**SHOULD HAVE:**
- `PROJECT_JOURNAL.md` - Running log of AI mistakes and successful patterns
- `MILESTONES.md` - Current goals and completed work
- `TODO.md` - Task breakdowns with priorities

### Monorepo Structure (RECOMMENDED)

**Use monorepo for AI development:**
- Entire codebase relationships visible to AI
- AI understands cross-project dependencies
- Atomic changes across multiple packages
- Better AI support reported by developers

**Tools:** Nx or Turborepo for caching and task orchestration

**Avoid multi-repo** unless you have distinct products, strong security/access control requirements, or mixing open-source and proprietary code.

## Development Workflow

### Four-Step Process (MANDATORY)

**1. READ PHASE**
- AI examines relevant files
- Provide general pointers or specific filenames
- Explicitly instruct: "DO NOT write code yet, just read and understand"

**2. PLAN PHASE**
- AI creates detailed implementation plan
- Use "think hard" or "ultrathink" keywords
- **REVIEW PLAN BEFORE IMPLEMENTATION**
- Generate GitHub issues from approved plans

**3. IMPLEMENT PHASE**
- Execute in small, reviewable steps
- AI verifies reasonableness as it proceeds
- Iterative approach, not large changes

**4. VERIFY PHASE**
- Commit results
- Create pull request
- Run tests
- **MANDATORY HUMAN CODE REVIEW**
- Update documentation

### Quality Gates (ALL must pass before merge)

- ✅ TypeScript compilation: ZERO errors
- ✅ All tests pass (unit, integration, E2E)
- ✅ Linting: ZERO warnings
- ✅ Security scans: NO critical/high vulnerabilities
- ✅ Code coverage: >80% or doesn't decrease
- ✅ Human code review: APPROVED
- ✅ Documentation: Updated (CLAUDE.md, README, inline comments)
- ✅ Performance benchmarks: Maintained or improved

## Database Patterns

### PostgreSQL with pgvector

**Schema Design:**
```sql
-- Relational data
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector embeddings
ALTER TABLE posts ADD COLUMN embedding vector(1536);

-- Vector index
CREATE INDEX ON posts USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);
```

**When to migrate to Qdrant:**
- Vector operations >30% of total queries
- Scale >50 million vectors
- Need <10ms query latency
- Qdrant deployment: Single Docker container, 4-8GB RAM

### Prisma Schema Pattern

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Post {
  id        String   @id @default(uuid())
  title     String
  content   String
  embedding Unsupported("vector(1536)")?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([embedding], type: Ivfflat)
}
```

## Security Requirements (VPS Deployment)

### Infrastructure Security (MANDATORY)

**Firewall Configuration:**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH (move to custom port)
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

**SSH Hardening:**
```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222  # Custom port (not 22)
```

**Fail2Ban Installation:**
```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

**Automatic Security Updates:**
```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### SSL/TLS (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
# Auto-renewal configured automatically
sudo certbot renew --dry-run  # Test renewal
```

### Application Security Headers (Nginx)

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000" always;
```

### Secret Management

- **NEVER** commit secrets to version control
- Use `.env` files with 600 permissions
- Add `.env` to `.gitignore`
- Consider HashiCorp Vault for enterprise scenarios

## Docker Compose Configuration

### Standard Stack Template

```yaml
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
      NODE_ENV: production
    depends_on:
      - postgres
    ports:
      - "3000:3000"
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "8080:80"
    restart: unless-stopped

  glitchtip:
    image: glitchtip/glitchtip:latest
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/glitchtip
      SECRET_KEY: ${GLITCHTIP_SECRET}
      REDIS_URL: redis://redis:6379
    ports:
      - "8000:8000"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

## Resource Allocation (KVM8 VPS - 32GB RAM)

**Typical Allocation:**
- PostgreSQL: 2-4GB
- Redis: 512MB-1GB
- Docker/Orchestration: 1-1.5GB
- Backend services: 8-12GB
- Frontend/Nginx: 1-2GB
- Monitoring (GlitchTip): 2GB
- System/Buffer: 8-10GB

**Storage (400GB NVMe):**
- System/orchestration: 50GB
- Container images: 20-30GB
- Databases: 50-100GB
- Application data: 100GB
- Backups with rotation: 100GB
- Buffer: 50GB

## Monitoring & Backups (REQUIRED)

### Process Management (Node.js)

```bash
npm install -g pm2
pm2 start npm --name "app" -- start
pm2 startup  # Auto-start on boot
pm2 save     # Save current process list
```

### Database Backups (Daily)

```bash
# PostgreSQL backup script
#!/bin/bash
BACKUP_DIR="/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -U ${DB_USER} ${DB_NAME} | gzip > ${BACKUP_DIR}/backup_${DATE}.sql.gz
# Keep last 30 days
find ${BACKUP_DIR} -name "backup_*.sql.gz" -mtime +30 -delete
```

### System Monitoring

- **Real-time:** `htop` or `netdata`
- **External uptime:** UptimeRobot (free tier) or StatusCake
- **Logs:** Pino → centralized log storage
- **Errors:** GlitchTip with email/webhook alerts

## Performance Optimization

### Vite Configuration (Fast Builds)

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import checker from 'vite-plugin-checker'

export default defineConfig({
  plugins: [
    vue(),
    checker({
      typescript: true,  // Type checking during dev
      vueTsc: true,
    })
  ],
  build: {
    target: 'es2020',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia']
        }
      }
    }
  }
})
```

### NestJS with Fastify

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: true })
  );

  await app.listen(3000, '0.0.0.0');
}
bootstrap();
```

## Cost Expectations

**Infrastructure (Monthly):**
- Hostinger KVM8 VPS: $19.99
- Domain: $1-2
- External backups (optional): $5-10
- **Total: $20-40/month**

**AI API Usage (Monthly):**
- Small projects: $50-80
- Medium projects: $80-160
- Large applications: $200-500
- Enterprise features: $20-50 per feature

**ROI Calculation:**
2-5x productivity gain typically justifies costs at 10-20 development hours monthly.

## Metrics to Track

**AI Effectiveness:**
- Acceptance rate: Target >50% of AI suggestions accepted without modification
- Iteration count: Target <3 attempts for typical features
- Test pass rate: Target >70% first-time success
- Code churn: Monitor for quality drift
- Context efficiency: Optimize to reduce token usage

**System Performance:**
- API response times: p95 <100ms
- Database query times: p95 <50ms
- Frontend load time: <1.5 seconds
- Test execution time: Track and optimize

## Migration Paths

**When to migrate:**

**Docker Compose → k3s:**
- Need multi-node clustering
- Require advanced features (auto-scaling, self-healing)
- Manage 10+ applications
- Need Helm chart ecosystem

**PostgreSQL+pgvector → Add Qdrant:**
- Vector operations >30% of queries
- Scale >50 million vectors
- Need <10ms query latency
- Complex multi-tenant filtering requirements

**Single VPS → Multi-VPS:**
- Resource constraints on single host
- Geographic distribution requirements
- Compliance/isolation needs

## CRITICAL REMINDERS

1. **ALWAYS enable TypeScript strict mode** - This is your first infrastructure improvement
2. **NEVER skip the CLAUDE.md file** - 20% documentation time = 3-5x better output
3. **ALWAYS review AI-generated plans before implementation** - Catch issues early
4. **NEVER merge without quality gates passing** - Automation prevents regression
5. **START with Docker Compose** - Migrate to k3s only when needed
6. **START with PostgreSQL+pgvector** - Add Qdrant only when performance demands it
7. **USE Forgejo over GitLab** unless you need comprehensive DevOps platform
8. **IMPLEMENT security hardening from day one** - Easier than retrofitting
9. **AUTOMATE backups immediately** - Test restoration quarterly
10. **MEASURE AI effectiveness with metrics** - Continuous optimization
