# Database: notification-service

**Technology:** MongoDB + Redis  
**Bounded Context:** Notification Context (Generic)  
**Responsibility:** Push notification delivery, preferences

---

## MongoDB Collections

### Collection: `notifications`

```js
// Document schema
{
  _id:              ObjectId,
  recipient_id:     String,    // user external_id from identity-service
  type:             String,    // see Notification Types below
  title:            String,
  body:             String,
  data:             Object,    // arbitrary deep-link / event payload
  device_token:     String,    // FCM token at time of send
  status:           String,    // PENDING | SENT | FAILED | READ
  created_at:       Date,
  sent_at:          Date,
  read_at:          Date,
  error:            String     // populated if status = FAILED
}

// Indexes
db.notifications.createIndex({ recipient_id: 1, created_at: -1 });
db.notifications.createIndex({ status: 1, created_at: 1 }, { partialFilterExpression: { status: "PENDING" } });
db.notifications.createIndex({ created_at: 1 }, { expireAfterSeconds: 2592000 }); // TTL: 30 days
```

### Collection: `notification_preferences`

```js
// Document schema
{
  _id:        ObjectId,
  user_id:    String,   // user external_id from identity-service
  push:       Boolean,  // global push toggle
  email:      Boolean,  // global email toggle
  types: {
    MATCH_REQUEST:     { push: Boolean, email: Boolean },
    MATCH_ACCEPTED:    { push: Boolean, email: Boolean },
    RESULT_CONFIRMED:  { push: Boolean, email: Boolean },
    RANK_UPDATED:      { push: Boolean, email: Boolean },
    TEAM_INVITATION:   { push: Boolean, email: Boolean },
    DISPUTE_OPENED:    { push: Boolean, email: Boolean }
  },
  updated_at: Date
}

// Indexes
db.notification_preferences.createIndex({ user_id: 1 }, { unique: true });
```

---

## Notification Types

| Type                | Triggering Event      | Description                       |
| ------------------- | --------------------- | --------------------------------- |
| `MATCH_REQUEST`     | `MatchRequested`      | A team wants to play against you  |
| `MATCH_ACCEPTED`    | `MatchAccepted`       | Your match request was accepted   |
| `MATCH_EXPIRED`     | `MatchExpired`        | Your match proposal expired       |
| `RESULT_REGISTERED` | `ResultRegistered`    | Opponent submitted a match result |
| `RESULT_CONFIRMED`  | `ResultConfirmed`     | Match result confirmed            |
| `DISPUTE_OPENED`    | `ResultDisputed`      | Opponent opened a dispute         |
| `RANK_UPDATED`      | `RankingRecalculated` | Your team's ranking changed       |
| `TEAM_INVITATION`   | `PlayerJoined`        | You were invited to a team        |

---

## Redis Usage

| Key Pattern                     | Type   | TTL    | Purpose                                    |
| ------------------------------- | ------ | ------ | ------------------------------------------ |
| `device_token:{user_id}`        | String | 7 days | Latest FCM device token per user           |
| `notif_queue`                   | List   | —      | FIFO queue for outgoing push notifications |
| `notif_retry:{notification_id}` | String | 24h    | Retry counter for failed notifications     |

---

## Domain Events Consumed

| Event                 | Source              | Action                                         |
| --------------------- | ------------------- | ---------------------------------------------- |
| `MatchRequested`      | matchmaking-service | Send `MATCH_REQUEST` push to target teams      |
| `MatchAccepted`       | matchmaking-service | Send `MATCH_ACCEPTED` push to requesting team  |
| `MatchExpired`        | matchmaking-service | Send `MATCH_EXPIRED` push to involved teams    |
| `ResultRegistered`    | game-service        | Send `RESULT_REGISTERED` push to opposing team |
| `ResultConfirmed`     | game-service        | Send `RESULT_CONFIRMED` to both teams          |
| `ResultDisputed`      | game-service        | Send `DISPUTE_OPENED` to both teams            |
| `RankingRecalculated` | ranking-service     | Send `RANK_UPDATED` to affected teams          |
