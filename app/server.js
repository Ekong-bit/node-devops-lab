const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// tiny healthcheck for probes/alarms
app.get('/healthz', (_req, res) => res.status(200).send('ok'));

app.get('/', (_req, res) => {
    res.send('Hello from Node.js on Elastic Beanstalk via Docker! 🚀');
});

if (require.main === module) {
    app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
}

module.exports = app; // exported for tests
