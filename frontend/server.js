const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;

const server = http.createServer((req, res) => {
    let filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
    
    const extname = path.extname(filePath);
    let contentType = 'text/html';
    
    switch (extname) {
        case '.js':
            contentType = 'text/javascript';
            break;
        case '.css':
            contentType = 'text/css';
            break;
        case '.json':
            contentType = 'application/json';
            break;
    }
    
    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404);
                res.end('File not found');
            } else {
                res.writeHead(500);
                res.end('Server error: ' + error.code);
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, () => {
    console.log('🚀 Dashboard Server Running!');
    console.log('============================================');
    console.log(`📱 Open in browser: http://localhost:${PORT}`);
    console.log('============================================');
    console.log('\n✅ Features:');
    console.log('   • Connect MetaMask wallet');
    console.log('   • View system statistics');
    console.log('   • Submit new credentials');
    console.log('   • View your active credentials');
    console.log('\n⚠️  Note: Using mock ZK verifier for testing');
    console.log('   All proofs will be accepted\n');
});
