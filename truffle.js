module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    }
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 1
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 10000
    }
  }
};
