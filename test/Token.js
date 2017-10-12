// Load contracts
var rocketPoolToken = artifacts.require("./contract/RocketPoolToken.sol");
var rocketPoolReserveFund = artifacts.require("./contract/RocketPoolReserveFund.sol");

// Show events
var displayEvents = false;

// Display events triggered during the tests
if(displayEvents) {
    rocketPoolCrowdsale.deployed().then(function (rocketPoolCrowdsaleInstance) {
        var eventWatch = rocketPoolCrowdsaleInstance.allEvents({
            fromBlock: 0,
            toBlock: 'latest',
        }).watch(function (error, result) {
            // Print the event to console
            var printEvent = function(type, result, colour) {
                console.log("\n");
                console.log(colour, '*** '+type.toUpperCase()+' EVENT: ' + result.event + ' *******************************');
                console.log("\n");
                console.log(result.args);
                console.log("\n");
            }
            // This will catch all events, regardless of how they originated.
            if (error == null) {
                // Print the event
                printEvent('rocket', result, '\x1b[33m%s\x1b[0m:');
            }
        });
    });
}

// Print nice titles for each unit test
var printTitle = function(user, desc) {
    return '\x1b[33m'+user+'\033[00m\: \033[01;34m'+desc;
}

// Checks to see if a throw was triggered
var checkThrow = function (error) {
    if(error.toString().indexOf("VM Exception") == -1) {
        // Didn't throw like we expected
        return assert(false, error.toString());
    } 
    // Always show out of gas errors
    if(error.toString().indexOf("out of gas") != -1) {
        return assert(false, error.toString());
    }
}


// Start the token and agent tests now
contract('RocketPoolToken', function (accounts) {


    // Set our units
    var exponent = 0;
    var totalSupply = 0;
    var totalSupplyCap = 0;

    // Set our crowdsale addresses
    var depositAddress = 0;

    // Our contributers    
    var owner = accounts[0];
    var userFirst = accounts[1];
    var userSecond = accounts[2];
    var userThird = accounts[3];
    var userFourth = accounts[4];
    var userFifth = accounts[5];

    // Our sales contracts
    var saleContracts = {
        // Type of contract ie presale, crowdsale, quarterly 
        'reserveFund': {
            // The min amount to raise to consider the sale a success
            targetEthMin: 0,
            // The max amount the sale agent can raise
            targetEthMax: 0,
            // Maximum tokens the contract can distribute 
            tokensLimit: 0,
            // Min ether allowed per deposit
            minDeposit: 0,
            // Max ether allowed per deposit
            maxDeposit: 0,
            // Start block
            fundingStartBlock: 0,
            // End block
            fundingEndBlock: 0,
            // Deposit address that will be allowed to withdraw the crowdsales ether - this is overwritten with the coinbase address for testing here
            depositAddress: 0
        }
    }

  
    
    // Load our token contract settings
    it(printTitle('contractToken', 'load token contract settings'), function () {
        // Crowdsale contract   
        return rocketPoolToken.deployed().then(function (rocketPoolTokenInstance) {
            // Set the exponent
            return rocketPoolTokenInstance.exponent.call().then(function(result) {
                exponent = result.valueOf();
                // Set the total supply currently in existance
                return rocketPoolTokenInstance.totalSupply.call().then(function(result) {
                    totalSupply = result.valueOf();
                    // Set the total supply cap
                    return rocketPoolTokenInstance.totalSupplyCap.call().then(function(result) {
                        totalSupplyCap = result.valueOf();
                        // console.log(exponent, totalSupply, totalSupplyCap);
                    });
                });
            });
        });
    }); 


    // Load our reserveFund contract settings
    it(printTitle('contractreserveFund', 'load reserveFund contract settings'), function () {
        // Token contract   
        return rocketPoolToken.deployed().then(function (rocketPoolTokenInstance) {
            // reserveFund contract   
            return rocketPoolReserveFund.deployed().then(function (rocketPoolReserveFundInstance) {
                // Get the contract details
                return rocketPoolTokenInstance.getSaleContractTargetEtherMin.call(rocketPoolReserveFundInstance.address).then(function(result) {
                    saleContracts.reserveFund.targetEthMin = result.valueOf();
                    return rocketPoolTokenInstance.getSaleContractTargetEtherMax.call(rocketPoolReserveFundInstance.address).then(function(result) {
                        saleContracts.reserveFund.targetEthMax = result.valueOf();
                        return rocketPoolTokenInstance.getSaleContractTokensLimit.call(rocketPoolReserveFundInstance.address).then(function(result) {
                            saleContracts.reserveFund.tokensLimit = result.valueOf();
                            return rocketPoolTokenInstance.getSaleContractStartBlock.call(rocketPoolReserveFundInstance.address).then(function(result) {
                                saleContracts.reserveFund.fundingStartBlock = result.valueOf();
                                return rocketPoolTokenInstance.getSaleContractEndBlock.call(rocketPoolReserveFundInstance.address).then(function(result) {
                                    saleContracts.reserveFund.fundingEndBlock = result.valueOf();
                                    return rocketPoolTokenInstance.getSaleContractDepositEtherMin.call(rocketPoolReserveFundInstance.address).then(function(result) {
                                        saleContracts.reserveFund.minDeposit = result.valueOf();
                                        return rocketPoolTokenInstance.getSaleContractDepositEtherMax.call(rocketPoolReserveFundInstance.address).then(function (result) {
                                            saleContracts.reserveFund.maxDeposit = result.valueOf();
                                            return rocketPoolTokenInstance.getSaleContractDepositAddress.call(rocketPoolReserveFundInstance.address).then(function (result) {
                                                saleContracts.reserveFund.depositAddress = result.valueOf();
                                                // Set the token price in ether now - maxTargetEth / tokensLimit
                                                tokenPriceInEther = saleContracts.reserveFund.targetEthMax / saleContracts.reserveFund.tokensLimit;
                                                return saleContracts.reserveFund.depositAddress != 0 ? true : false;
                                            }).then(function (result) {
                                                assert.isTrue(result, "rocketPoolReserveFundInstance depositAddress verified.");
                                            });
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    }); 
   
    // Begin Tests
    it(printTitle('userFirst', 'fails to register new sale agent contract as they are not the owner of the token contract'), function () {
        // Contract   
        return rocketPoolToken.deployed().then(function (rocketPoolTokenInstance) {
            // Contract   
            return rocketPoolReserveFund.deployed().then(function (rocketPoolReserveFundInstance) {
                // Transaction
                return rocketPoolTokenInstance.setSaleAgentContract(
                    userFirst, 
                    'myowncontract',
                    1,
                    100,
                    saleContracts.reserveFund.tokensLimit, 
                    0,
                    100,
                    saleContracts.reserveFund.fundingStartBlock,
                    saleContracts.reserveFund.fundingEndBlock,
                    saleContracts.reserveFund.depositAddress,
                    { from:userFirst, gas: 550000 }).then(function (result) {
                        return result;
                    }).then(function(result) { 
                    assert(false, "Expect throw but didn't.");
                    }).catch(function (error) {
                        return checkThrow(error);
                    });
            });
        });    
    }); // End Test 
    

    // Begin Tests
    it(printTitle('userFirst', 'fails to register new sale agent contract with more tokens than the totalSupplyCap'), function () {
        // Contract   
        return rocketPoolToken.deployed().then(function (rocketPoolTokenInstance) {
            // Contract   
            return rocketPoolReserveFund.deployed().then(function (rocketPoolReserveFundInstance) {
                // Transaction
                return rocketPoolTokenInstance.setSaleAgentContract(
                    userFirst, 
                    'myowncontract',
                    1,
                    100,
                    web3.toWei('50000001', 'ether'), 
                    0,
                    100,
                    saleContracts.reserveFund.fundingStartBlock,
                    saleContracts.reserveFund.fundingEndBlock,
                    saleContracts.reserveFund.depositAddress,
                    { from:owner, gas: 550000 }).then(function (result) {
                        return result;
                    }).then(function(result) { 
                    assert(false, "Expect throw but didn't.");
                    }).catch(function (error) {
                        return checkThrow(error);
                    });
            });
        });    
    }); // End Test 


    it(printTitle('userFirst', 'fails to call mint function on main token contract'), function () {
        // Contract   
        return rocketPoolToken.deployed().then(function (rocketPoolTokenInstance) {
            // Transaction
            return rocketPoolTokenInstance.mint(userFirst, 100, { from:userFirst, gas: 250000 }).then(function (result) {
                    return result;
            }).then(function(result) { 
                assert(false, "Expect throw but didn't.");
            }).catch(function (error) {
                return checkThrow(error);
            });
        });    
    }); // End Test  
   
});



 


