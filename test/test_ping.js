import fetch from 'node-fetch';

const totalRequests = parseInt(process.argv[2]) || 1000;
const concurrent = parseInt(process.argv[3]) || 50;
const target = 'http://192.168.66.10:32425'; 

const makeRequest = () => fetch(target).then(res => res.text());

const run = async () => {
  console.time('Ping Test');
  const queue = Array.from({ length: totalRequests });
  for (let i = 0; i < queue.length; i += concurrent) {
    await Promise.all(queue.slice(i, i + concurrent).map(() => makeRequest()));
  }
  console.timeEnd('Ping Test');
};

run();
