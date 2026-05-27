import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { USER_REPOSITORY } from '../../../users/domain/repositories/user-repository.interface';

jest.mock('bcrypt');
const bcryptMock = bcrypt as jest.Mocked<typeof bcrypt>;

const mockUserRepo = {
  findByEmail: jest.fn(),
  create: jest.fn(),
  findById: jest.fn(),
  findProfileById: jest.fn(),
  updateProfile: jest.fn(),
};

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: USER_REPOSITORY, useValue: mockUserRepo },
        {
          provide: JwtService,
          useValue: { signAsync: jest.fn().mockResolvedValue('mock-access-token') },
        },
        {
          provide: ConfigService,
          useValue: { getOrThrow: jest.fn().mockReturnValue('test-jwt-secret') },
        },
      ],
    }).compile();

    service = module.get(AuthService);
  });

  describe('register', () => {
    it('throws ConflictException when email already in use', async () => {
      mockUserRepo.findByEmail.mockResolvedValue({
        id: 'existing-uuid',
        email: 'test@test.com',
        passwordHash: 'hash',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });

      await expect(
        service.register({ email: 'test@test.com', password: '123456', displayName: 'Test' }),
      ).rejects.toThrow(ConflictException);

      expect(mockUserRepo.create).not.toHaveBeenCalled();
    });

    it('creates user and returns accessToken on success', async () => {
      mockUserRepo.findByEmail.mockResolvedValue(null);
      mockUserRepo.create.mockResolvedValue({
        id: 'new-uuid',
        email: 'new@test.com',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
      (bcryptMock.hash as jest.Mock).mockResolvedValue('hashed-password');

      const result = await service.register({
        email: 'new@test.com',
        password: 'senha123',
        displayName: 'Novo Jogador',
      });

      expect(result.accessToken).toBe('mock-access-token');
      expect(mockUserRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ email: 'new@test.com', displayName: 'Novo Jogador' }),
      );
    });
  });

  describe('login', () => {
    it('throws UnauthorizedException when user not found', async () => {
      mockUserRepo.findByEmail.mockResolvedValue(null);

      await expect(
        service.login({ email: 'notfound@test.com', password: '123456' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException when password is wrong', async () => {
      mockUserRepo.findByEmail.mockResolvedValue({
        id: 'uuid-1',
        email: 'test@test.com',
        passwordHash: '$2b$10$wronghash',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
      (bcryptMock.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.login({ email: 'test@test.com', password: 'wrongpassword' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('returns accessToken when credentials are valid', async () => {
      mockUserRepo.findByEmail.mockResolvedValue({
        id: 'uuid-1',
        email: 'test@test.com',
        passwordHash: '$2b$10$validhash',
        phone: null,
        status: 'ACTIVE',
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
      mockUserRepo.findProfileById.mockResolvedValue({
        id: 'uuid-1',
        displayName: 'Test User',
        photoUrl: null,
        bio: null,
        city: null,
        position: null,
        skillLevel: null,
        isPublic: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      (bcryptMock.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.login({ email: 'test@test.com', password: 'correta123' });
      expect(result.accessToken).toBe('mock-access-token');
    });
  });
});
