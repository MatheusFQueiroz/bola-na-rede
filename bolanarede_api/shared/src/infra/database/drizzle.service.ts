import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DrizzleService.name);
  private pool!: Pool;
  db!: NodePgDatabase;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const url = this.config.getOrThrow<string>('DATABASE_URL');
    this.pool = new Pool({ connectionString: url });
    this.db = drizzle(this.pool);
    this.logger.log('Database connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
    this.logger.log('Database disconnected');
  }
}
