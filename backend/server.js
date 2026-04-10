const app = require('./api/index');
const dotenv = require('dotenv');

// Load env vars if they exist
dotenv.config();

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Local development server running on port ${PORT}`);
    console.log(`Test URL: http://localhost:${PORT}/`);
    console.log(`Test Login: http://localhost:${PORT}/api/auth/login (POST)`);
});
