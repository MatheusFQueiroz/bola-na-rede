'use strict';

const { MongoClient } = require('mongodb');

const url = process.env.MONGODB_URL;
if (!url) {
  console.error('MONGODB_URL is not set');
  process.exit(1);
}

async function setupIndexes() {
  const client = new MongoClient(url);
  await client.connect();

  const dbName = new URL(url).pathname.slice(1);
  const db = client.db(dbName || 'bolanarededb_notification');

  await db.collection('notifications').createIndex(
    { recipientUserId: 1, createdAt: -1 },
    { background: true },
  );
  await db.collection('notifications').createIndex(
    { recipientUserId: 1, isRead: 1 },
    { background: true },
  );
  await db.collection('device_tokens').createIndex(
    { userId: 1 },
    { unique: true, background: true },
  );

  console.log('MongoDB indexes created successfully');
  await client.close();
}

setupIndexes().catch((err) => {
  console.error('Failed to set up indexes:', err);
  process.exit(1);
});
