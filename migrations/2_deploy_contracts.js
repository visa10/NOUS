var NOUSToken = artifacts.require("./NOUSToken.sol");
var NOUSSale = artifacts.require("./NOUSSale.sol");
var RefundVault = artifacts.require("./RefundVault.sol");

var NOUSPresale = artifacts.require("./NOUSPresale.sol");
var NOUSCrowdsale = artifacts.require("./NOUSCrowdsale.sol");
var NOUSReservFund = artifacts.require("./NOUSReservFund.sol");


module.exports = function(deployer) {

    var wallet = "0xEF6e578c42Ac21AeA5b225e7c96Bf0F8206bd019";

    deployer
        .then(function() {
            Promise.all(
                [
                    NOUSToken.new(),
                    RefundVault.new(wallet)
                ]
            )
            .then(function(instances) {
                console.log("NOUSToken:", instances[0].address);
                console.log("RefundVault:", instances[1].address);
                return NOUSSale.new(wallet, instances[0].address, instances[1].address);
            })
            .then(function (nousSaleInst) {
                var newSale = nousSaleInst.address;
                console.log("NOUSSale:", newSale);
                deployer.deploy([[NOUSPresale, newSale], [NOUSCrowdsale, newSale], [NOUSReservFund, newSale]]);
            });

    });

};


function toJson(obj) { return JSON.stringify(obj.abi);}
function unloc(i){return personal.unlockAccount(eth.accounts[i])}

/*
NOUSToken: 0x860134d046fd08406fad30217ea3a21c32dd7fab
RefundVault: 0x3522d17023919a33fd7dd7fca443a9a878051687
NOUSSale: 0x572a7d0e0eacb71c1305250d75acb0830b37d5b9
  Replacing NOUSPresale...
  Replacing NOUSCrowdsale...
  Replacing NOUSReservFund...
  NOUSCrowdsale: 0x64729085f3065a81504dff5d1758dfcdee25abd7
  NOUSPresale: 0xace2c215e47c97a9c6ae288a0d981cd7d6a6d530
  NOUSReservFund: 0x8c55d9de8fe1f198e27093aeab1770f820404f30
 */

/*
NOUSToken: 0xfc7b61ac981d8a668ea01972c998929143b712ae
RefundVault: 0x6f0714b87ca073b1c12153c6751e921594c00037
NOUSSale: 0xadce3dd7888a28b3c10a68c2c4e57728f1c5b6a0
Replacing NOUSPresale...
    Replacing NOUSCrowdsale...
    Replacing NOUSReservFund...
    NOUSCrowdsale: 0x03bb336c2cb70461eb2cf435f37362a4c6ca5125
NOUSPresale: 0x56d3f5046c5eee5bd111cd6f30bbea2fe4ad7518
NOUSReservFund: 0x857d476e369927c6a4a66149fa2fd55297105b6a
*/
