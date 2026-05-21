import 'package:json_annotation/json_annotation.dart';

// ---------------------------------------------------------------------------
// Enums compartilhados entre múltiplos serviços
// Usar estes em vez de redefinir localmente para garantir consistência
// ---------------------------------------------------------------------------

/// Status genérico de reserva — field-service
enum ReservationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('NO_SHOW')
  noShow,
  @JsonValue('COMPLETED')
  completed,
}

/// Status de pagamento — field-service
enum PaymentStatus {
  @JsonValue('UNPAID')
  unpaid,
  @JsonValue('PAID')
  paid,
  @JsonValue('REFUNDED')
  refunded,

  /// Pagamento realizado fora do app (dinheiro, pix direto, etc.)
  @JsonValue('EXTERNAL')
  external,
}

/// Canal de origem da reserva — field-service
enum ReservationChannel {
  @JsonValue('bolanarededb_app')
  bolanarededbApp,
  @JsonValue('manual')
  manual,
  @JsonValue('whatsapp')
  whatsapp,
  @JsonValue('phone')
  phone,
  @JsonValue('link')
  link,
}

/// Status de partida formal — game-service
enum MatchStatus {
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('NO_SHOW')
  noShow,
}

/// Status de resultado de partida — game-service
enum MatchResultStatus {
  @JsonValue('PENDING_CONFIRMATION')
  pendingConfirmation,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('DISPUTED')
  disputed,
  @JsonValue('AUTO_ACCEPTED')
  autoAccepted,
}

/// Status de disputa — game-service
enum DisputeStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('RESOLVED')
  resolved,
  @JsonValue('DISMISSED')
  dismissed,
}

/// Status de time — team-service
enum TeamStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('INACTIVE')
  inactive,

  /// Abaixo de 5 membros ativos (RN04)
  @JsonValue('INVALID')
  invalid,
}

/// Papel do membro no time — team-service
enum TeamMemberRole {
  @JsonValue('CAPTAIN')
  captain,
  @JsonValue('MEMBER')
  member,
}

/// Status de convite de time — team-service
enum InvitationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('EXPIRED')
  expired,
}

/// Status de solicitação de partida — matchmaking-service
enum MatchRequestStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('MATCHED')
  matched,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('CANCELLED')
  cancelled,
}

/// Status de proposta de partida — matchmaking-service
enum MatchProposalStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('EXPIRED')
  expired,
}

/// Posição do jogador em campo
enum PlayerPosition {
  @JsonValue('goalkeeper')
  goalkeeper,
  @JsonValue('defender')
  defender,
  @JsonValue('midfielder')
  midfielder,
  @JsonValue('forward')
  forward,
}

/// Nível de habilidade do jogador (1–5)
enum SkillLevel {
  @JsonValue(1)
  beginner,
  @JsonValue(2)
  recreational,
  @JsonValue(3)
  intermediate,
  @JsonValue(4)
  advanced,
  @JsonValue(5)
  competitive,
}
