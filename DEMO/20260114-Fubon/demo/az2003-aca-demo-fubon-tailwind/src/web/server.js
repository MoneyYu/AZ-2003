const express = require('express');
const axios = require('axios');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

// Dapr
const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const quoteApiAppId = process.env.QUOTE_API_APP_ID || 'fubon-quote-api';
const directApiUrl = process.env.QUOTE_API_URL || 'http://localhost:8000';

// Version/Revision labels (ACA injects CONTAINER_APP_REVISION)
const build = {
  version: process.env.APP_VERSION || '1.0.0',
  revision: process.env.CONTAINER_APP_REVISION || 'local',
  label: process.env.DEPLOYMENT_LABEL || 'local'
};

// Optional volume logging: if mounted, append simple access log
const logPath = process.env.ACCESS_LOG_PATH || '/mnt/files/access.log';
function tryAppend(line){
  try {
    fs.mkdirSync(require('path').dirname(logPath), { recursive: true });
    fs.appendFileSync(logPath, line + "
", { encoding: 'utf8' });
  } catch(e) {
    // ignore when volume not mounted
  }
}

app.use((req,res,next)=>{
  const t = new Date().toISOString();
  tryAppend(`${t}	${req.method}	${req.path}	${build.version}	${build.revision}	${build.label}`);
  next();
});

app.use(express.static('public'));

app.get('/api/version', (req, res) => {
  res.json({ service: 'web', ...build, now: new Date().toISOString() });
});

app.get('/api/quote', async (req, res) => {
  const age = Number(req.query.age || 35);
  const coverage = Number(req.query.coverage || 1000000);
  const term = Number(req.query.term || 20);

  try {
    let url;
    if (process.env.DAPR_ENABLED === 'true') {
      url = `http://localhost:${daprPort}/v1.0/invoke/${quoteApiAppId}/method/quote?age=${age}&coverage=${coverage}&term=${term}`;
    } else {
      url = `${directApiUrl}/quote?age=${age}&coverage=${coverage}&term=${term}`;
    }

    const r = await axios.get(url, { timeout: 8000 });
    res.json({ via: process.env.DAPR_ENABLED === 'true' ? 'dapr' : 'direct', web: build, quote: r.data });
  } catch (e) {
    // rich error for demo debugging
    res.status(500).json({
      error: e.message,
      code: e.code,
      responseStatus: e.response?.status,
      responseData: e.response?.data,
      hint: '若是 DAPR 模式：請檢查 web/api 是否都 enable dapr，且 QUOTE_API_APP_ID == api 的 dapr.appId，dapr.appPort 正確。'
    });
  }
});

app.get('/', (req, res) => res.sendFile(__dirname + '/public/index.html'));

app.listen(port, () => console.log(`fubon-web listening on ${port}`));
