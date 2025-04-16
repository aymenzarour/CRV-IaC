import fetch from 'node-fetch';
import { v4 as uuidv4 } from 'uuid';

const totalRequests = parseInt(process.argv[2]) || 1000;
const concurrent = parseInt(process.argv[3]) || 50;
const target = 'http://192.168.66.10:32425';

const makeRequest = async () => {
  const id = uuidv4();
  await fetch(`${target}/item`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, val: 'valeur-' + id }),
  });
  await fetch(`${target}/item?id=${id}`);
};

const run = async () => {
  console.time('WriteRead Test');
  const queue = Array.from({ length: totalRequests });
  for (let i = 0; i < queue.length; i += concurrent) {
    await Promise.all(queue.slice(i, i + concurrent).map(() => makeRequest()));
  }
  console.timeEnd('WriteRead Test');
};

run();
