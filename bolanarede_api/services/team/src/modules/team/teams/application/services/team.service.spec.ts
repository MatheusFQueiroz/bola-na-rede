import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { TeamService } from './team.service';
import { TEAM_REPOSITORY } from '../../domain/repositories/team-repository.interface';
import { TeamMessagingService } from './team-messaging.service';
import type { Team } from '../../domain/models/team.entity';
import type { TeamMember } from '../../domain/models/team-member.entity';

const mockTeamRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findByIdWithMemberCount: jest.fn(),
  update: jest.fn(),
  deactivate: jest.fn(),
  addMember: jest.fn(),
  removeMember: jest.fn(),
  findMember: jest.fn(),
  findMembers: jest.fn(),
  countActiveMembers: jest.fn(),
  setCaptain: jest.fn(),
  updateMemberSnapshot: jest.fn(),
};

const mockMessaging = {
  publishTeamCreated: jest.fn(),
  publishPlayerJoined: jest.fn(),
  publishPlayerLeft: jest.fn(),
  publishTeamBecameInvalid: jest.fn(),
  publishCaptaincyTransferred: jest.fn(),
};

const mockTeam: Team = {
  id: 'team-uuid-1',
  name: 'Los Cracks',
  description: 'Time de pelada',
  captainUserId: 'player-captain',
  minPlayers: 5,
  maxPlayers: 11,
  isActive: true,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

const mockMember: TeamMember = {
  playerUserId: 'player-member',
  displayName: 'João Silva',
  position: null,
  role: 'member',
  joinedAt: new Date('2026-01-01'),
  leftAt: null,
};

describe('TeamService', () => {
  let service: TeamService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module = await Test.createTestingModule({
      providers: [
        TeamService,
        { provide: TEAM_REPOSITORY, useValue: mockTeamRepo },
        { provide: TeamMessagingService, useValue: mockMessaging },
      ],
    }).compile();

    service = module.get(TeamService);
  });

  describe('create', () => {
    it('creates a team and publishes team.created event', async () => {
      mockTeamRepo.create.mockResolvedValue(mockTeam);

      const result = await service.create('player-captain', 'El Capitán', {
        name: 'Los Cracks',
        minPlayers: 5,
        maxPlayers: 11,
      });

      expect(result.id).toBe('team-uuid-1');
      expect(result.memberCount).toBe(1);
      expect(mockTeamRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Los Cracks',
          captainUserId: 'player-captain',
          captainDisplayName: 'El Capitán',
          minPlayers: 5,
          maxPlayers: 11,
        }),
      );
      expect(mockMessaging.publishTeamCreated).toHaveBeenCalledWith(mockTeam, 1);
    });

    it('applies default minPlayers=5 and maxPlayers=11 when not provided', async () => {
      mockTeamRepo.create.mockResolvedValue(mockTeam);
      await service.create('player-captain', 'El Capitán', { name: 'Sem config' });
      expect(mockTeamRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ minPlayers: 5, maxPlayers: 11 }),
      );
    });
  });

  describe('getTeam', () => {
    it('returns TeamDto when team exists', async () => {
      mockTeamRepo.findByIdWithMemberCount.mockResolvedValue({ ...mockTeam, memberCount: 3 });
      const result = await service.getTeam('team-uuid-1');
      expect(result.memberCount).toBe(3);
    });

    it('throws NotFoundException when team does not exist', async () => {
      mockTeamRepo.findByIdWithMemberCount.mockResolvedValue(null);
      await expect(service.getTeam('non-existent')).rejects.toThrow(NotFoundException);
    });
  });

  describe('join', () => {
    it('adds member to team and publishes player-joined event', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      mockTeamRepo.countActiveMembers.mockResolvedValue(4);
      mockTeamRepo.addMember.mockResolvedValue(mockMember);

      const result = await service.join('player-member', 'João Silva', 'team-uuid-1');

      expect(result.playerUserId).toBe('player-member');
      expect(mockMessaging.publishPlayerJoined).toHaveBeenCalledWith(mockTeam, mockMember);
    });

    it('throws NotFoundException when team does not exist', async () => {
      mockTeamRepo.findById.mockResolvedValue(null);
      await expect(service.join('player-member', 'João', 'no-team')).rejects.toThrow(NotFoundException);
    });

    it('throws NotFoundException when team is inactive', async () => {
      mockTeamRepo.findById.mockResolvedValue({ ...mockTeam, isActive: false });
      await expect(service.join('player-member', 'João', 'team-uuid-1')).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when player is already a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      await expect(service.join('player-member', 'João', 'team-uuid-1')).rejects.toThrow(ConflictException);
    });

    it('throws ConflictException when team is full', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      mockTeamRepo.countActiveMembers.mockResolvedValue(11); // maxPlayers = 11
      await expect(service.join('player-new', 'Novo', 'team-uuid-1')).rejects.toThrow(ConflictException);
    });
  });

  describe('leave', () => {
    it('removes member and publishes player-left event', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(6);

      await service.leave('player-member', 'team-uuid-1');

      expect(mockTeamRepo.removeMember).toHaveBeenCalledWith('team-uuid-1', 'player-member');
      expect(mockMessaging.publishPlayerLeft).toHaveBeenCalledWith(mockTeam, 'player-member');
      expect(mockMessaging.publishTeamBecameInvalid).not.toHaveBeenCalled();
    });

    it('publishes team.became-invalid when count drops below minPlayers', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(4); // below minPlayers=5

      await service.leave('player-member', 'team-uuid-1');

      expect(mockMessaging.publishTeamBecameInvalid).toHaveBeenCalledWith(mockTeam);
    });

    it('throws ForbiddenException when captain tries to leave without transferring', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(service.leave('player-captain', 'team-uuid-1')).rejects.toThrow(ForbiddenException);
    });

    it('throws NotFoundException when player is not a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      await expect(service.leave('player-member', 'team-uuid-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('removeMember', () => {
    it('captain can remove a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(6);

      await service.removeMember('player-captain', 'team-uuid-1', 'player-member');

      expect(mockTeamRepo.removeMember).toHaveBeenCalledWith('team-uuid-1', 'player-member');
      expect(mockMessaging.publishPlayerLeft).toHaveBeenCalledWith(mockTeam, 'player-member');
    });

    it('throws ForbiddenException when non-captain tries to remove', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(
        service.removeMember('player-other', 'team-uuid-1', 'player-member'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws ForbiddenException when captain tries to remove themselves', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(
        service.removeMember('player-captain', 'team-uuid-1', 'player-captain'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('transferCaptaincy', () => {
    it('transfers captaincy to an active member', async () => {
      const updatedTeam = { ...mockTeam, captainUserId: 'player-member' };
      mockTeamRepo.findById
        .mockResolvedValueOnce(mockTeam)
        .mockResolvedValueOnce(updatedTeam);
      mockTeamRepo.findMember.mockResolvedValue(mockMember);
      mockTeamRepo.countActiveMembers.mockResolvedValue(5);

      const result = await service.transferCaptaincy('player-captain', 'team-uuid-1', {
        newCaptainId: 'player-member',
      });

      expect(mockTeamRepo.setCaptain).toHaveBeenCalledWith('team-uuid-1', 'player-member');
      expect(mockMessaging.publishCaptaincyTransferred).toHaveBeenCalledWith(
        updatedTeam,
        'player-captain',
        'player-member',
      );
      expect(result.captainUserId).toBe('player-member');
    });

    it('throws ForbiddenException when non-captain tries to transfer', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(
        service.transferCaptaincy('player-other', 'team-uuid-1', { newCaptainId: 'player-member' }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws NotFoundException when new captain is not a member', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      mockTeamRepo.findMember.mockResolvedValue(null);
      await expect(
        service.transferCaptaincy('player-captain', 'team-uuid-1', { newCaptainId: 'stranger' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deactivate', () => {
    it('deactivates team and publishes team.became-invalid event', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await service.deactivate('player-captain', 'team-uuid-1');
      expect(mockTeamRepo.deactivate).toHaveBeenCalledWith('team-uuid-1');
      expect(mockMessaging.publishTeamBecameInvalid).toHaveBeenCalledWith(mockTeam);
    });

    it('throws ForbiddenException when non-captain tries to deactivate', async () => {
      mockTeamRepo.findById.mockResolvedValue(mockTeam);
      await expect(service.deactivate('player-other', 'team-uuid-1')).rejects.toThrow(ForbiddenException);
    });
  });
});
