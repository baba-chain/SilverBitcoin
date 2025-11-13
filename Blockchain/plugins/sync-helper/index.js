import fs from 'fs';
import net from 'net';
import axios from 'axios';
import { Web3 } from 'web3';
import { IpcProvider } from 'web3-providers-ipc';

// ============= CONFIGURATION =============
// TODO: Update these values with your dashboard server details
const DASHBOARD_SERVER = 'http://YOUR_SERVER_IP:3000'; // Change to your server IP
const ACCESS_TOKEN = 'private-network-1762823146663-irgfta'; // Your generated token
const IPC_PATH = process.env.IPC_PATH || '/root/.silverbitcoin/geth.ipc';
const INTERVAL = 5000;

// API Endpoints
const POST_API_URL = `${DASHBOARD_SERVER}/post-enode`;
const GET_API_URL = `${DASHBOARD_SERVER}/get-enode`;
const UPDATE_COMPLETE_URL = `${DASHBOARD_SERVER}/api/update-complete`;
const REGISTER_VALIDATOR_URL = `${DASHBOARD_SERVER}/api/register-validator`;

let provider;
let web3;

// ============= JSON-RPC FUNCTIONS =============

function sendJsonRpcRequest(method, params = []) {
  return new Promise((resolve, reject) => {
    const client = net.createConnection(IPC_PATH);

    client.on('connect', () => {
      const request = JSON.stringify({
        jsonrpc: '2.0',
        method,
        params,
        id: Date.now(),
      });

      client.write(`${request}\n`);
    });

    client.on('data', (data) => {
      try {
        const response = JSON.parse(data.toString());
        if (response.error) {
          reject(response.error);
        } else {
          resolve(response.result);
        }
      } catch (error) {
        reject(error);
      } finally {
        client.end();
      }
    });

    client.on('error', (error) => {
      reject(error);
    });
  });
}

// ============= ENODE MANAGEMENT =============

async function getEnodeAddress() {
  try {
    let nodeInfo = await sendJsonRpcRequest('admin_nodeInfo');
    return nodeInfo.enode;
  } catch (error) {
    console.error('Error fetching enode address:', error);
    throw error;
  }
}

async function postEnodeAddress() {
  try {
    const enode = await getEnodeAddress();
    console.log('📡 Posting enode address to dashboard...');

    if (!ACCESS_TOKEN) {
      throw new Error('ACCESS_TOKEN is not defined');
    }

    const response = await axios.post(POST_API_URL, { enode }, {
      headers: { Authorization: ACCESS_TOKEN },
      timeout: 5000
    });

    console.log('✅ Enode posted successfully');
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.error('❌ Cannot connect to dashboard server. Is it running?');
    } else {
      console.error('❌ Error posting enode:', error.message);
    }
  }
}

async function addPeers() {
  try {
    if (!ACCESS_TOKEN) {
      throw new Error('ACCESS_TOKEN is not defined');
    }

    const response = await axios.get(GET_API_URL, {
      headers: { Authorization: ACCESS_TOKEN },
      timeout: 5000
    });

    const enodeList = response.data;
    const ownEnode = await getEnodeAddress();

    let addedCount = 0;
    for (const enode of enodeList) {
      if (enode !== ownEnode) {
        try {
          await sendJsonRpcRequest('admin_addPeer', [enode]);
          addedCount++;
        } catch (error) {
          // Peer might already be connected, ignore
        }
      }
    }

    if (addedCount > 0) {
      console.log(`✅ Added ${addedCount} new peers`);
    }
  } catch (error) {
    if (error.code !== 'ECONNREFUSED') {
      console.error('❌ Error adding peers:', error.message);
    }
  }
}

// ============= VALIDATOR TRACKING =============

async function getNodeAddress() {
  try {
    const nodeType = await getNodeType();

    if (nodeType === 'validator') {
      // Try to get coinbase address (validator address)
      try {
        const coinbase = await sendJsonRpcRequest('eth_coinbase');
        if (coinbase && coinbase !== '0x0000000000000000000000000000000000000000') {
          console.log(`✅ Found validator coinbase address: ${coinbase}`);
          return coinbase;
        }
      } catch (error) {
        // Coinbase might not be set yet
      }

      // Fallback: try to get from accounts
      try {
        const accounts = await sendJsonRpcRequest('eth_accounts');
        if (accounts && accounts.length > 0) {
          console.log(`✅ Found validator account address: ${accounts[0]}`);
          return accounts[0];
        }
      } catch (error) {
        // No accounts available
      }

      // Last resort: read from address.txt file
      try {
        const addressFile = IPC_PATH.replace('/geth.ipc', '/address.txt');
        if (fs.existsSync(addressFile)) {
          const address = fs.readFileSync(addressFile, 'utf8').trim();
          console.log(`✅ Found validator address from file: ${address}`);
          return address;
        }
      } catch (error) {
        // File doesn't exist
      }
    }

    if (nodeType === 'rpc') {
      // RPC nodes use enode-based identifier
      const enode = await getEnodeAddress();
      const nodeId = enode.split('@')[0].replace('enode://', '');
      const identifier = 'rpc-' + nodeId.substring(0, 16);
      console.log(`✅ Generated RPC node identifier: ${identifier}`);
      return identifier;
    }

    return null;

  } catch (error) {
    console.error('❌ Error getting node address:', error);
    return null;
  }
}

async function getNodeType() {
  try {
    // Check for marker files
    const basePath = IPC_PATH.replace('/geth.ipc', '');
    const validatorFile = `${basePath}/.validator`;
    const rpcFile = `${basePath}/.rpc`;

    if (fs.existsSync(validatorFile)) {
      return 'validator';
    } else if (fs.existsSync(rpcFile)) {
      return 'rpc';
    }

    // Default to validator if no marker file
    return 'validator';
  } catch (error) {
    console.error('❌ Error determining node type:', error);
    return 'validator';
  }
}

async function getCommitHash() {
  try {
    const { execSync } = await import('child_process');
    const commitHash = execSync('git rev-parse HEAD 2>/dev/null', {
      encoding: 'utf8',
      cwd: process.cwd()
    }).trim();
    return commitHash;
  } catch (error) {
    return 'unknown';
  }
}

async function getValidatorIP() {
  try {
    const response = await axios.get('https://api.ipify.org?format=json', { timeout: 5000 });
    return response.data.ip;
  } catch (error) {
    return 'unknown';
  }
}

async function registerNode() {
  try {
    const nodeAddress = await getNodeAddress();
    const nodeIP = await getValidatorIP();
    const nodeType = await getNodeType();

    console.log(`📝 Registering ${nodeType} node: ${nodeAddress}`);

    if (!nodeAddress) {
      console.log('⚠️  Could not determine node address, skipping registration');
      return;
    }

    const registrationData = {
      validator_address: nodeAddress,
      validator_ip: nodeIP,
      node_type: nodeType
    };

    const response = await axios.post(REGISTER_VALIDATOR_URL, registrationData, {
      headers: {
        Authorization: ACCESS_TOKEN,
        'Content-Type': 'application/json'
      },
      timeout: 5000
    });

    console.log(`✅ ${nodeType.toUpperCase()} node registered successfully`);
  } catch (error) {
    if (error.response && error.response.status === 409) {
      console.log(`✅ Node already registered`);
    } else if (error.code === 'ECONNREFUSED') {
      console.error('❌ Cannot connect to dashboard server');
    } else {
      console.error(`❌ Error registering node:`, error.message);
    }
  }
}

async function reportUpdateCompletion() {
  try {
    const nodeAddress = await getNodeAddress();
    const nodeIP = await getValidatorIP();
    const commitHash = await getCommitHash();
    const nodeType = await getNodeType();
    const timestamp = new Date().toISOString();

    if (!nodeAddress) {
      return;
    }

    const updateData = {
      validator_address: nodeAddress,
      validator_ip: nodeIP,
      commit_hash: commitHash,
      timestamp: timestamp,
      node_type: nodeType
    };

    const response = await axios.post(UPDATE_COMPLETE_URL, updateData, {
      headers: {
        Authorization: ACCESS_TOKEN,
        'Content-Type': 'application/json'
      },
      timeout: 5000
    });

    console.log(`✅ Update completion reported successfully`);
    return true;
  } catch (error) {
    if (error.code !== 'ECONNREFUSED') {
      console.error(`❌ Error reporting update:`, error.message);
    }
    return false;
  }
}

async function checkAndReportUpdate() {
  try {
    const updateFlagFile = '/var/tmp/silverbitcoin-update-completed';

    if (fs.existsSync(updateFlagFile)) {
      console.log('🔄 Update flag file found, reporting...');
      const success = await reportUpdateCompletion();

      if (success) {
        fs.unlinkSync(updateFlagFile);
        console.log('✅ Update reported and flag removed');
      }
    }
  } catch (error) {
    console.error('❌ Error checking update flag:', error);
  }
}

// ============= PERIODIC EXECUTION =============

function runPeriodically(fn, interval) {
  let isRunning = false;

  const execute = async () => {
    if (isRunning) return;
    isRunning = true;
    try {
      await fn();
    } catch (error) {
      console.error('❌ Error executing function:', error.message);
    }
    isRunning = false;
  };

  setInterval(execute, interval);
}

function waitForIpcFile() {
  const checkFileExists = () => {
    if (fs.existsSync(IPC_PATH)) {
      console.log('✅ IPC file found. Starting sync-helper...');
      provider = new IpcProvider(IPC_PATH, net);
      web3 = new Web3(provider);

      // Initialize node tracking
      setTimeout(async () => {
        console.log('🚀 Initializing node tracking...');
        await registerNode();
        await checkAndReportUpdate();
      }, 5000);

      // Start periodic tasks
      runPeriodically(postEnodeAddress, 15000);  // Every 15 seconds
      runPeriodically(addPeers, 9000);           // Every 9 seconds
      runPeriodically(checkAndReportUpdate, 60000); // Every minute
    } else {
      console.log('⏳ Waiting for IPC file...');
      setTimeout(checkFileExists, INTERVAL);
    }
  };

  checkFileExists();
}

// ============= STARTUP =============

console.log(`
╔════════════════════════════════════════════════════════════╗
║   🚀 SilverBitcoin Sync Helper                             ║
╠════════════════════════════════════════════════════════════╣
║   Dashboard: ${DASHBOARD_SERVER}                           ║
║   IPC Path: ${IPC_PATH}                                    ║
╠════════════════════════════════════════════════════════════╣
║   Waiting for node to start...                             ║
╚════════════════════════════════════════════════════════════╝
`);

// Start the IPC file check
waitForIpcFile();
