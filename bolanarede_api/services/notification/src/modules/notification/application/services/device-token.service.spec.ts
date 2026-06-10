import { Test, TestingModule } from '@nestjs/testing';
import { DeviceTokenService } from './device-token.service';
import { DEVICE_TOKEN_REPOSITORY } from '../../domain/repositories/device-token-repository.interface';

const mockRepo = { upsert: jest.fn(), findByUserId: jest.fn() };

describe('DeviceTokenService', () => {
  let service: DeviceTokenService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeviceTokenService,
        { provide: DEVICE_TOKEN_REPOSITORY, useValue: mockRepo },
      ],
    }).compile();
    service = module.get(DeviceTokenService);
  });

  it('delegates upsert to repository with correct args', async () => {
    const expected = {
      id: '1',
      userId: 'u1',
      token: 'tok',
      platform: 'ios' as const,
      updatedAt: new Date(),
    };
    mockRepo.upsert.mockResolvedValue(expected);

    const result = await service.upsertToken('u1', 'tok', 'ios');

    expect(mockRepo.upsert).toHaveBeenCalledWith({ userId: 'u1', token: 'tok', platform: 'ios' });
    expect(result).toEqual(expected);
  });

  it('returns null when no token found', async () => {
    mockRepo.findByUserId.mockResolvedValue(null);
    const result = await service.getToken('u1');
    expect(result).toBeNull();
  });

  it('returns token when found', async () => {
    const token = {
      id: '1',
      userId: 'u1',
      token: 'tok',
      platform: 'android' as const,
      updatedAt: new Date(),
    };
    mockRepo.findByUserId.mockResolvedValue(token);
    const result = await service.getToken('u1');
    expect(result).toEqual(token);
  });
});
