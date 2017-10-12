module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        ropsten:  {
            network_id: 3,
            host: "localhost",
            port:  8545,
            gas:   6993166,
            from: "0xad4016f585da476073c7d53a5e53d9ec6c735204",
        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    }
};
