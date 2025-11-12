const express = require("express")
const app = express()
const port = 3000

// Middleware
app.use(express.json())

// In-memory storage for enodes
let enodes = []

// In-memory storage for validator updates
let validators = new Map() // Map<validatorAddress, validatorInfo>
let updateHistory = [] // Array of update events

// Authentication token - Updated for private network
const ACCESS_TOKEN = 'private-network-1757346718388-suqw4gu5e'
console.log("New Access Token:", ACCESS_TOKEN)

// Initialize validators storage (no sample data)
function initializeValidators() {
  // Validators will be registered automatically when nodes start up
  console.log('Validator tracking system initialized - waiting for validator registrations')
}

// Initialize validators on startup
initializeValidators()

// Middleware to check authorization
function authenticate(req, res, next) {
  const token = req.headers.authorization
  if (token !== ACCESS_TOKEN) {
    return res.status(401).json({ error: "Unauthorized" })
  }
  next()
}

// POST endpoint to add enode
app.post("/post-enode", authenticate, (req, res) => {
  const { enode } = req.body

  if (!enode) {
    return res.status(400).json({ error: "Enode is required" })
  }

  if (!enode.startsWith("enode://") && !enode.startsWith("enr:-")) {
    return res.status(400).json({
      error: "Invalid enode format. Must start with 'enode://' or 'enr:-'",
    })
  }

  // Add enode if not already present
  if (!enodes.includes(enode)) {
    enodes.push(enode)
    console.log(`Added enode: ${enode}`)
  }

  res.json({ success: true, message: "Enode added successfully" })
})

// GET endpoint to retrieve all enodes
app.get("/get-enode", (req, res) => {
  res.json(enodes)
})

// GET endpoint to retrieve all enodes without authentication
app.get("/get-enodes-public", (req, res) => {
  res.json(enodes)
})

// ============= VALIDATOR UPDATE TRACKING ENDPOINTS =============

// POST endpoint for validators to report update completion
app.post("/api/update-complete", authenticate, (req, res) => {
  const { validator_address, validator_ip, commit_hash, timestamp, node_type } = req.body

  // Validate required fields
  if (!validator_address || !commit_hash || !timestamp) {
    return res.status(400).json({
      error: "Missing required fields: validator_address, commit_hash, timestamp"
    })
  }

  // Check if validator exists or create new one
  let validator = validators.get(validator_address)
  if (!validator) {
    validator = {
      address: validator_address,
      ip: validator_ip || 'unknown',
      status: 'PENDING',
      registeredAt: new Date().toISOString(),
      lastUpdate: null,
      commitHash: null,
      nodeType: null
    }
    validators.set(validator_address, validator)
  }

  // Update validator status
  validator.status = 'COMPLETED'
  validator.lastUpdate = timestamp
  validator.commitHash = commit_hash
  validator.nodeType = node_type || 'unknown'
  if (validator_ip) validator.ip = validator_ip

  // Add to update history
  const updateEvent = {
    validator_address,
    validator_ip: validator.ip,
    commit_hash,
    timestamp,
    node_type,
    eventTime: new Date().toISOString()
  }
  updateHistory.push(updateEvent)

  // Keep only last 100 update events
  if (updateHistory.length > 100) {
    updateHistory = updateHistory.slice(-100)
  }

  console.log(`Update completed for validator: ${validator_address} at ${timestamp}`)

  res.json({
    success: true,
    message: "Update completion recorded successfully",
    validator: validator
  })
})

// GET endpoint to get current update status of all validators
app.get("/api/status", (req, res) => {
  const validatorArray = Array.from(validators.values())
  const totalValidators = validatorArray.length
  const completedValidators = validatorArray.filter(v => v.status === 'COMPLETED').length
  const pendingValidators = totalValidators - completedValidators
  const progressPercentage = totalValidators > 0 ? Math.round((completedValidators / totalValidators) * 100) : 0

  const lastUpdate = validatorArray
    .filter(v => v.lastUpdate)
    .sort((a, b) => new Date(b.lastUpdate) - new Date(a.lastUpdate))[0]?.lastUpdate || null

  res.json({
    total_validators: totalValidators,
    completed: completedValidators,
    pending: pendingValidators,
    progress_percentage: progressPercentage,
    last_update: lastUpdate,
    validators: validatorArray
  })
})

// GET endpoint to get list of validators that haven't updated
app.get("/api/pending", (req, res) => {
  const pendingValidators = Array.from(validators.values())
    .filter(v => v.status === 'PENDING')

  res.json({
    count: pendingValidators.length,
    validators: pendingValidators
  })
})

// GET endpoint to get update history
app.get("/api/history", (req, res) => {
  const limit = parseInt(req.query.limit) || 50
  const history = updateHistory.slice(-limit).reverse()

  res.json({
    count: history.length,
    total_events: updateHistory.length,
    history: history
  })
})

// POST endpoint to register a new validator
app.post("/api/register-validator", authenticate, (req, res) => {
  const { validator_address, validator_ip, node_type } = req.body

  if (!validator_address) {
    return res.status(400).json({ error: "validator_address is required" })
  }

  if (validators.has(validator_address)) {
    return res.status(409).json({ error: "Validator already registered" })
  }

  const validator = {
    address: validator_address,
    ip: validator_ip || 'unknown',
    status: 'PENDING',
    registeredAt: new Date().toISOString(),
    lastUpdate: null,
    commitHash: null,
    nodeType: node_type || 'unknown'
  }

  validators.set(validator_address, validator)
  console.log(`Registered new validator: ${validator_address}`)

  res.json({
    success: true,
    message: "Validator registered successfully",
    validator: validator
  })
})

// GET endpoint for web dashboard
app.get("/api/dashboard", (req, res) => {
  const validatorArray = Array.from(validators.values())
  const totalValidators = validatorArray.length
  const completedValidators = validatorArray.filter(v => v.status === 'COMPLETED').length
  const progressPercentage = totalValidators > 0 ? Math.round((completedValidators / totalValidators) * 100) : 0

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Validator Update Dashboard</title>
        <meta http-equiv="refresh" content="30">
        <style>
            body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
            .header { background: #007cba; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; text-align: center; }
            .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
            .stat-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
            .stat-number { font-size: 2em; font-weight: bold; color: #007cba; }
            .stat-label { color: #666; margin-top: 5px; }
            .progress-bar { background: #e0e0e0; border-radius: 10px; height: 20px; margin: 10px 0; overflow: hidden; }
            .progress-fill { background: #28a745; height: 100%; transition: width 0.3s ease; }
            .validators-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 15px; }
            .validator-card { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .validator-status { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 0.8em; font-weight: bold; }
            .status-completed { background: #d4edda; color: #155724; }
            .status-pending { background: #fff3cd; color: #856404; }
            .validator-info { margin: 8px 0; font-size: 0.9em; color: #666; }
            .refresh-info { text-align: center; margin-top: 20px; color: #666; font-size: 0.9em; }
            .copy-btn {
                background: #f8f9fa;
                border: 1px solid #dee2e6;
                border-radius: 4px;
                padding: 4px 8px;
                cursor: pointer;
                font-size: 0.8em;
                transition: all 0.2s ease;
                min-width: 30px;
                height: 24px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
            }
            .copy-btn:hover {
                background: #e9ecef;
                border-color: #adb5bd;
            }
            .copy-btn:active {
                background: #dee2e6;
                transform: scale(0.95);
            }
            .copy-btn.copied {
                background: #d4edda;
                border-color: #c3e6cb;
                color: #155724;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔄 Validator Update Dashboard</h1>
            <p>Real-time tracking of validator updates across the network</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-number">${totalValidators}</div>
                <div class="stat-label">Total Validators</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">${completedValidators}</div>
                <div class="stat-label">Updated</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">${totalValidators - completedValidators}</div>
                <div class="stat-label">Pending</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">${progressPercentage}%</div>
                <div class="stat-label">Progress</div>
            </div>
        </div>

        <div class="progress-bar">
            <div class="progress-fill" style="width: ${progressPercentage}%"></div>
        </div>

        <div class="validators-grid">
            ${validatorArray.map((validator, index) => `
                <div class="validator-card">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <strong>${validator.address.substring(0, 5)}...${validator.address.substring(validator.address.length - 5)}</strong>
                            <button class="copy-btn" onclick="copyToClipboard('${validator.address}', 'address-${index}')" id="address-${index}" title="Copy full address">
                                📋
                            </button>
                        </div>
                        <span class="validator-status status-${validator.status.toLowerCase()}">
                            ${validator.status === 'COMPLETED' ? '✅' : '⏳'} ${validator.status}
                        </span>
                    </div>
                    <div class="validator-info" style="display: flex; align-items: center; gap: 8px;">
                        <span>IP: ${validator.ip}</span>
                        <button class="copy-btn" onclick="copyToClipboard('${validator.ip}', 'ip-${index}')" id="ip-${index}" title="Copy IP address">
                            📋
                        </button>
                    </div>
                    <div class="validator-info">Type: ${validator.nodeType || 'Unknown'}</div>
                    ${validator.lastUpdate ? `<div class="validator-info">Updated: ${new Date(validator.lastUpdate).toLocaleString()}</div>` : ''}
                    ${validator.commitHash ? `<div class="validator-info">Commit: ${validator.commitHash.substring(0, 8)}...</div>` : ''}
                </div>
            `).join('')}
        </div>

        <div class="refresh-info">
            <p>🔄 Page auto-refreshes every 30 seconds | Last updated: ${new Date().toLocaleString()}</p>
            <p><a href="/api/status">JSON API</a> | <a href="/api/pending">Pending Validators</a> | <a href="/api/history">Update History</a></p>
        </div>

        <script>
            async function copyToClipboard(text, buttonId) {
                try {
                    await navigator.clipboard.writeText(text);

                    // Update button to show success
                    const button = document.getElementById(buttonId);
                    const originalText = button.innerHTML;

                    button.innerHTML = '✅';
                    button.classList.add('copied');

                    // Reset button after 2 seconds
                    setTimeout(() => {
                        button.innerHTML = originalText;
                        button.classList.remove('copied');
                    }, 2000);

                } catch (err) {
                    console.error('Failed to copy text: ', err);

                    // Fallback for older browsers
                    const textArea = document.createElement('textarea');
                    textArea.value = text;
                    textArea.style.position = 'fixed';
                    textArea.style.left = '-999999px';
                    textArea.style.top = '-999999px';
                    document.body.appendChild(textArea);
                    textArea.focus();
                    textArea.select();

                    try {
                        document.execCommand('copy');
                        const button = document.getElementById(buttonId);
                        const originalText = button.innerHTML;

                        button.innerHTML = '✅';
                        button.classList.add('copied');

                        setTimeout(() => {
                            button.innerHTML = originalText;
                            button.classList.remove('copied');
                        }, 2000);
                    } catch (fallbackErr) {
                        console.error('Fallback copy failed: ', fallbackErr);
                        alert('Copy failed. Please copy manually: ' + text);
                    }

                    document.body.removeChild(textArea);
                }
            }
        </script>
    </body>
    </html>
  `)
})

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    enodeCount: enodes.length,
    validatorCount: validators.size,
    updateHistoryCount: updateHistory.length,
    timestamp: new Date().toISOString(),
  })
})

app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Enode Manager</title>
        <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
            .container { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 10px 0; }
            input[type="text"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
            button { background: #007cba; color: white; padding: 10px 20px; border: none; border-radius: 4px; margin: 5px; cursor: pointer; }
            button:hover { background: #005a87; }
            .result { margin: 20px 0; padding: 15px; border-radius: 4px; display: none; }
            .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
            .error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
            pre { background: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
        </style>
    </head>
    <body>
        <h1>Enode Manager</h1>

        <div class="container">
            <h3>Add New Enode</h3>
            <input type="text" id="enodeInput" placeholder="Enter enode string..." />
            <button onclick="postEnode()">Add Enode</button>
            <button onclick="clearInput()">Clear</button>
        </div>

        <div class="container">
            <h3>Actions</h3>
            <button onclick="getEnodes()">Get All Enodes</button>
            <button onclick="getEnodesPublic()">Get All Enodes Publicly</button>
            <button onclick="getHealth()">Health Check</button>
        </div>

        <div id="result" class="result"></div>

        <script>
            const ACCESS_TOKEN = "${ACCESS_TOKEN}";

            function showResult(message, isError = false) {
                const resultDiv = document.getElementById("result");
                resultDiv.style.display = "block";
                resultDiv.className = "result " + (isError ? "error" : "success");
                resultDiv.innerHTML = message;
            }

            async function postEnode() {
                const enode = document.getElementById("enodeInput").value.trim();
                if (!enode) {
                    showResult("<strong>Error:</strong> Please enter an enode", true);
                    return;
                }

                try {
                    const response = await fetch("/post-enode", {
                        method: "POST",
                        headers: { "Content-Type": "application/json", "Authorization": ACCESS_TOKEN },
                        body: JSON.stringify({ enode })
                    });

                    const result = await response.json();

                    if (response.ok) {
                        showResult("<strong>Success:</strong> " + result.message);
                        document.getElementById("enodeInput").value = "";
                    } else {
                        showResult("<strong>Error:</strong> " + result.error, true);
                    }
                } catch (error) {
                    showResult("<strong>Network Error:</strong> " + error.message, true);
                }
            }

            async function getEnodes() {
                try {
                    const response = await fetch("/get-enode");
                    const result = await response.json();

                    if (response.ok) {
                        const count = Array.isArray(result) ? result.length : 0;
                        showResult("<strong>Current Enodes (" + count + "):</strong><pre>" + JSON.stringify(result, null, 2) + "</pre>");
                    } else {
                        showResult("<strong>Error:</strong> " + result.error, true);
                    }
                } catch (error) {
                    showResult("<strong>Network Error:</strong> " + error.message, true);
                }
            }

            async function getEnodesPublic() {
                try {
                    const response = await fetch("/get-enodes-public");
                    const result = await response.json();

                    if (response.ok) {
                        const count = Array.isArray(result) ? result.length : 0;
                        showResult("<strong>Current Enodes Publicly (" + count + "):</strong><pre>" + JSON.stringify(result, null, 2) + "</pre>");
                    } else {
                        showResult("<strong>Error:</strong> " + result.error, true);
                    }
                } catch (error) {
                    showResult("<strong>Network Error:</strong> " + error.message, true);
                }
            }

            async function getHealth() {
                try {
                    const response = await fetch("/health");
                    const result = await response.json();
                    showResult("<strong>Health Status:</strong><pre>" + JSON.stringify(result, null, 2) + "</pre>");
                } catch (error) {
                    showResult("<strong>Network Error:</strong> " + error.message, true);
                }
            }

            function clearInput() {
                document.getElementById("enodeInput").value = "";
                showResult("<strong>Input cleared</strong>");
            }
        </script>
    </body>
    </html>
  `)
})

// Start server
app.listen(port, "0.0.0.0", () => {
  console.log(`Enode API server running on port ${port}`)
  console.log(`Health check: http://localhost:${port}/health`)
})

// Cleanup old enodes every 5 minutes
setInterval(() => {
  console.log(`Current enodes: ${enodes.length}`)
  // Keep only the last 10 enodes to prevent memory buildup
  if (enodes.length > 10) {
    enodes = enodes.slice(-10)
    console.log(`Cleaned up enodes, now have: ${enodes.length}`)
  }
}, 300000)
