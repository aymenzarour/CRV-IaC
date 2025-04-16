import fetch from 'node-fetch';

const concurrent = parseInt(process.argv[2]) || 200;
const delay = parseInt(process.argv[3]) || 10000; // en ms
const target = `http://192.168.66.10:32425/pending?wait=${delay}`; 

const makeRequest = () => fetch(target).then(res => res.text());

const run = async () => {
  console.time('Pending Test');
  await Promise.all(Array.from({ length: concurrent }).map(() => makeRequest()));
  console.timeEnd('Pending Test');
};

run();

