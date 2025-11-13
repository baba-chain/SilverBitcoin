# SilverBitcoin Sync Helper with Update Tracking

This plugin provides two main functionalities:
1. **Peer Discovery & Synchronization** - Helps nodes discover and connect to other network peers
2. **Validator Update Tracking** - Centralized tracking system for monitoring validator updates

## Features

### 🔗 Peer Discovery
- Automatic enode address posting and retrieval
- Dynamic peer addition for network synchronization
- Periodic peer discovery and connection

### 📊 Update Tracking
- **Centralized Server**: Tracks all validator updates in real-time
- **Automatic Reporting**: Validators automatically report update completion
- **Web Dashboard**: Visual interface showing update progress
- **REST API**: Programmatic access to update status
- **Historical Data**: Complete audit trail of all updates

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Validator 1   │    │   Validator 2   │    │   Validator N   │
│                 │    │                 │    │                 │
│ 1. Run update   │    │ 1. Run update   │    │ 1. Run update   │
│ 2. Create flag  │    │ 2. Create flag  │    │ 2. Create flag  │
│ 3. Start node   │    │ 3. Start node   │    │ 3. Start node   │
│ 4. Report update│    │ 4. Report update│    │ 4. Report update│
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Central Tracking Server │
                    │                         │
                    │ • Validator Registry    │
                    │ • Update Status         │
                    │ • Web Dashboard         │
                    │ • REST API              │
                    │ • Alert System          │
                    └─────────────────────────┘
```

## Files

### Server Side (`enode-server.js`)
- **Express.js server** running on port 3000
- **Enode management** for peer discovery
- **Validator update tracking** endpoints
- **Web dashboard** for monitoring
- **In-memory storage** for validators and update history

### Client Side (`index.js`)
- **Node.js client** that runs on each validator
- **Automatic validator registration**
- **Update completion reporting**
- **Peer discovery and connection**
- **IPC communication** with blockchain node

### Update Script Integration
- **Modified update.sh** creates completion flag
- **Automatic detection** by client
- **Seamless reporting** to central server

## API Endpoints

### Validator Update Tracking

#### `POST /api/update-complete`
Report update completion from validator
```json
{
  "validator_address": "0x123...",
  "validator_ip": "1.2.3.4",
  "commit_hash": "ef432b30...",
  "timestamp": "2025-11-06T01:22:00Z",
  "node_type": "validator"
}
```

#### `GET /api/status`
Get current update status of all validators
```json
{
  "total_validators": 10,
  "completed": 7,
  "pending": 3,
  "progress_percentage": 70,
  "last_update": "2025-11-06T01:22:00Z",
  "validators": [...]
}
```

#### `GET /api/pending`
Get list of validators that haven't updated
```json
{
  "count": 3,
  "validators": [...]
}
```

#### `GET /api/history`
Get update history (last 50 events by default)
```json
{
  "count": 50,
  "total_events": 150,
  "history": [...]
}
```

#### `POST /api/register-validator`
Register a new validator
```json
{
  "validator_address": "0x123...",
  "validator_ip": "1.2.3.4",
  "node_type": "validator"
}
```

#### `GET /api/dashboard`
Web dashboard for visual monitoring

### Peer Discovery (Legacy)

#### `POST /post-enode`
Add enode to the network registry

#### `GET /get-enode`
Retrieve all registered enodes

#### `GET /get-enodes-public`
Public endpoint for enode retrieval

## Installation & Setup

### 1. Install Dependencies
```bash
cd /root/silverbitcoinfoundation/SilverBitcoin/plugins/sync-helper
npm install
```

### 2. Start the Central Server
```bash
# On your central tracking server
node enode-server.js
```

### 3. Configure Client Nodes
Update the server URLs in `index.js`:
```javascript
const UPDATE_COMPLETE_URL = 'http://YOUR_SERVER_IP:3000/api/update-complete';
const REGISTER_VALIDATOR_URL = 'http://YOUR_SERVER_IP:3000/api/register-validator';
```

### 4. Start Client on Each Validator
```bash
# On each validator node
cd /root/silverbitcoinfoundation/SilverBitcoin/plugins/sync-helper
node index.js
```

## Usage

### Running Updates with Tracking

1. **Execute Update Script** on any validator:
   ```bash
   cd /root && \
   curl -fsSL -H 'Accept: application/vnd.github.raw' \
     "https://api.github.com/repos/SilverBitcoinFoundation/silverbitcoinfoundation/contents/updates/update.sh?ref=main" \
     -o update.sh && chmod +x update.sh && ./update.sh
   ```

2. **Monitor Progress** via web dashboard:
   ```
   http://YOUR_SERVER_IP:3000/api/dashboard
   ```

3. **Check Status** programmatically:
   ```bash
   curl http://YOUR_SERVER_IP:3000/api/status
   ```

### Dashboard Features

- **Real-time Progress**: Visual progress bar and statistics
- **Validator Grid**: Individual validator status cards
- **Auto-refresh**: Page updates every 30 seconds
- **Status Indicators**: ✅ Completed, ⏳ Pending
- **Detailed Info**: IP addresses, commit hashes, timestamps

## Configuration

### Environment Variables
```bash
# Server configuration
PORT=3000
ACCESS_TOKEN='private-network-1757346718388-suqw4gu5e'

# Client configuration
IPC_PATH='/root/silverbitcoinfoundation/SilverBitcoin/chaindata/node1/geth.ipc'
SERVER_URL='http://72.60.24.227:3000'
```

### Authentication
All API endpoints (except public ones) require the `Authorization` header:
```
Authorization: private-network-1757346718388-suqw4gu5e
```

## Monitoring & Alerts

### Health Check
```bash
curl http://YOUR_SERVER_IP:3000/health
```

### Update History
```bash
curl http://YOUR_SERVER_IP:3000/api/history?limit=100
```

### Pending Validators
```bash
curl http://YOUR_SERVER_IP:3000/api/pending
```

## Troubleshooting

### Common Issues

1. **Client not reporting updates**
   - Check if IPC file exists: `/root/silverbitcoinfoundation/SilverBitcoin/chaindata/node1/geth.ipc`
   - Verify node is running and accessible
   - Check network connectivity to central server

2. **Server not receiving updates**
   - Verify server is running on correct port
   - Check firewall settings
   - Validate API authentication token

3. **Update flag not created**
   - Ensure update script completed successfully
   - Check if `/var/tmp/silverbitcoin-update-completed` exists
   - Verify git repository is accessible

4. **PM2 directory errors**
   - Use the provided ecosystem.config.js: `pm2 start ecosystem.config.js`
   - Ensure PM2 is run from `/root` directory
   - Check PM2 logs: `pm2 logs sync-helper`

### Logs
- **Server logs**: Console output from `enode-server.js`
- **Client logs**: Console output from `index.js`
- **Update logs**: Output from `update.sh` script

## Security Considerations

- **API Authentication**: All sensitive endpoints require valid token
- **Input Validation**: Server validates all incoming data
- **Rate Limiting**: Consider implementing rate limiting for production
- **HTTPS**: Use HTTPS in production environments
- **Network Security**: Restrict server access to validator network only

## Development

### Adding New Features
1. **Server-side**: Add endpoints to `enode-server.js`
2. **Client-side**: Add functions to `index.js`
3. **Update integration**: Modify `update.sh` as needed

### Testing
```bash
# Test server endpoints
curl -X POST http://localhost:3000/api/update-complete \
  -H "Authorization: private-network-1757346718388-suqw4gu5e" \
  -H "Content-Type: application/json" \
  -d '{"validator_address":"0x123","commit_hash":"abc123","timestamp":"2025-11-06T01:22:00Z"}'
```

## Version History

- **v2.1**: Added comprehensive update tracking system
- **v2.0**: Enhanced update script with auto-detection
- **v1.0**: Basic peer discovery functionality

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review server and client logs
3. Verify network connectivity and configuration
4. Test API endpoints manually

---

**Note**: This system provides real-time visibility into validator updates across your entire network, transforming manual checking into an automated, centralized tracking solution.
