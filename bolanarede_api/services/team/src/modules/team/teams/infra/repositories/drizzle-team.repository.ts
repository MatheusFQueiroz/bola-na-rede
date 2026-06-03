import { Injectable } from '@nestjs/common';
import { and, eq, isNull, sql } from 'drizzle-orm';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type {
  CreateTeamData,
  TeamRepositoryInterface,
  TeamWithCount,
} from '../../domain/repositories/team-repository.interface';
import type { Team } from '../../domain/models/team.entity';
import type { TeamMember } from '../../domain/models/team-member.entity';
import { teams, type TeamRow } from '../database/schemas/team.schema';
import { teamMembers, type TeamMemberRow } from '../database/schemas/team-member.schema';

@Injectable()
export class DrizzleTeamRepository implements TeamRepositoryInterface {
  constructor(private readonly drizzle: DrizzleService) {}

  async create(data: CreateTeamData): Promise<Team> {
    return this.drizzle.db.transaction(async (tx) => {
      const [teamRow] = await tx
        .insert(teams)
        .values({
          name: data.name,
          description: data.description ?? null,
          captainUserId: data.captainUserId,
          minPlayers: data.minPlayers,
          maxPlayers: data.maxPlayers,
        })
        .returning();

      await tx.insert(teamMembers).values({
        teamId: teamRow.id,
        playerUserId: data.captainUserId,
        displayName: data.captainDisplayName,
        position: null,
        role: 'captain',
      });

      return this.toTeam(teamRow);
    });
  }

  async findById(externalId: string): Promise<Team | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(teams)
      .where(eq(teams.externalId, externalId))
      .limit(1);
    return row ? this.toTeam(row) : null;
  }

  async findByIdWithMemberCount(externalId: string): Promise<TeamWithCount | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(teams)
      .where(eq(teams.externalId, externalId))
      .limit(1);

    if (!row) return null;

    const count = await this.countActiveMembers(externalId);
    return { ...this.toTeam(row), memberCount: count };
  }

  async update(externalId: string, data: Partial<Pick<Team, 'name' | 'description'>>): Promise<Team> {
    const updateData: Partial<typeof teams.$inferInsert> = { updatedAt: new Date() };
    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;

    const [row] = await this.drizzle.db
      .update(teams)
      .set(updateData)
      .where(eq(teams.externalId, externalId))
      .returning();

    if (!row) throw new Error(`Team "${externalId}" not found`);
    return this.toTeam(row);
  }

  async deactivate(externalId: string): Promise<void> {
    await this.drizzle.db
      .update(teams)
      .set({ isActive: false, updatedAt: new Date() })
      .where(eq(teams.externalId, externalId));
  }

  async addMember(
    teamExternalId: string,
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<TeamMember> {
    const [teamRow] = await this.drizzle.db
      .select({ id: teams.id })
      .from(teams)
      .where(eq(teams.externalId, teamExternalId))
      .limit(1);

    if (!teamRow) throw new Error(`Team "${teamExternalId}" not found`);

    const [row] = await this.drizzle.db
      .insert(teamMembers)
      .values({ teamId: teamRow.id, playerUserId, displayName, position, role: 'member' })
      .returning();

    if (!row) throw new Error(`Failed to add member to team "${teamExternalId}"`);
    return this.toMember(row);
  }

  async removeMember(teamExternalId: string, playerUserId: string): Promise<void> {
    const [teamRow] = await this.drizzle.db
      .select({ id: teams.id })
      .from(teams)
      .where(eq(teams.externalId, teamExternalId))
      .limit(1);

    if (!teamRow) throw new Error(`Team "${teamExternalId}" not found`);

    await this.drizzle.db
      .update(teamMembers)
      .set({ leftAt: new Date() })
      .where(
        and(
          eq(teamMembers.teamId, teamRow.id),
          eq(teamMembers.playerUserId, playerUserId),
          isNull(teamMembers.leftAt),
        ),
      );
  }

  async findMember(teamExternalId: string, playerUserId: string): Promise<TeamMember | null> {
    const [row] = await this.drizzle.db
      .select({ tm: teamMembers })
      .from(teamMembers)
      .innerJoin(teams, eq(teams.id, teamMembers.teamId))
      .where(
        and(
          eq(teams.externalId, teamExternalId),
          eq(teamMembers.playerUserId, playerUserId),
          isNull(teamMembers.leftAt),
        ),
      )
      .limit(1);

    return row ? this.toMember(row.tm) : null;
  }

  async findMembers(teamExternalId: string): Promise<TeamMember[]> {
    const rows = await this.drizzle.db
      .select({ tm: teamMembers })
      .from(teamMembers)
      .innerJoin(teams, eq(teams.id, teamMembers.teamId))
      .where(
        and(
          eq(teams.externalId, teamExternalId),
          isNull(teamMembers.leftAt),
        ),
      );

    return rows.map((r) => this.toMember(r.tm));
  }

  async countActiveMembers(teamExternalId: string): Promise<number> {
    const [teamRow] = await this.drizzle.db
      .select({ id: teams.id })
      .from(teams)
      .where(eq(teams.externalId, teamExternalId))
      .limit(1);

    if (!teamRow) return 0;

    const [result] = await this.drizzle.db
      .select({ count: sql<number>`count(*)::int` })
      .from(teamMembers)
      .where(
        and(
          eq(teamMembers.teamId, teamRow.id),
          isNull(teamMembers.leftAt),
        ),
      );

    return result?.count ?? 0;
  }

  async setCaptain(teamExternalId: string, newCaptainUserId: string): Promise<void> {
    await this.drizzle.db.transaction(async (tx) => {
      const [teamRow] = await tx
        .select({ id: teams.id, captainUserId: teams.captainUserId })
        .from(teams)
        .where(eq(teams.externalId, teamExternalId))
        .limit(1);

      if (!teamRow) throw new Error(`Team "${teamExternalId}" not found`);

      await tx
        .update(teams)
        .set({ captainUserId: newCaptainUserId, updatedAt: new Date() })
        .where(eq(teams.externalId, teamExternalId));

      await tx
        .update(teamMembers)
        .set({ role: 'member' })
        .where(
          and(
            eq(teamMembers.teamId, teamRow.id),
            eq(teamMembers.playerUserId, teamRow.captainUserId),
            isNull(teamMembers.leftAt),
          ),
        );

      await tx
        .update(teamMembers)
        .set({ role: 'captain' })
        .where(
          and(
            eq(teamMembers.teamId, teamRow.id),
            eq(teamMembers.playerUserId, newCaptainUserId),
            isNull(teamMembers.leftAt),
          ),
        );
    });
  }

  async updateMemberSnapshot(
    playerUserId: string,
    displayName: string,
    position: string | null,
  ): Promise<void> {
    await this.drizzle.db
      .update(teamMembers)
      .set({ displayName, position })
      .where(
        and(
          eq(teamMembers.playerUserId, playerUserId),
          isNull(teamMembers.leftAt),
        ),
      );
  }

  private toTeam(row: TeamRow): Team {
    return {
      id: row.externalId,
      name: row.name,
      description: row.description ?? null,
      captainUserId: row.captainUserId,
      minPlayers: row.minPlayers,
      maxPlayers: row.maxPlayers,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toMember(row: TeamMemberRow): TeamMember {
    return {
      playerUserId: row.playerUserId,
      displayName: row.displayName,
      position: row.position ?? null,
      role: row.role as 'captain' | 'member',
      joinedAt: row.joinedAt,
      leftAt: row.leftAt ?? null,
    };
  }
}
