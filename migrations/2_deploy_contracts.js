var NOUSToken = artifacts.require("./NOUSToken.sol");
var NOUSSale = artifacts.require("./NOUSSale.sol");

var NOUSPresale = artifacts.require("./NOUSPresale.sol");
var NOUSCrowdsale = artifacts.require("./NOUSCrowdsale.sol");
var NOUSReservFund = artifacts.require("./NOUSReservFund.sol");


module.exports = function(deployer) {
    deployer.deploy(NOUSSale, {gas: 6993166});
    deployer.deploy(NOUSToken);
    deployer.deploy([NOUSPresale, NOUSCrowdsale, NOUSReservFund]);
};
