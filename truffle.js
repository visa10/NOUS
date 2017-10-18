module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas:   6993166,
            from: "0x6e7dc7528e8a6edeb343e0df09fcd6a780f4fe20",
        },
        ropsten:  {
            network_id: 3,
            host: "192.168.88.8",
            port:  8545,
            gas:   6993200,
            //from: "0xad4016f585da476073c7d53a5e53d9ec6c735204",
            from: "0x74e85fC4E59E6CFA129D69cdC23A3d54b4807894",

        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    }
};
