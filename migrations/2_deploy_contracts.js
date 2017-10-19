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

                var instanceNousSale = NOUSSale.new(wallet, instances[0].address, instances[1].address);

                instances[0].transferOwnership(instanceNousSale.address);
                instances[1].transferOwnership(instanceNousSale.address);

                return instanceNousSale.address;
            })
            .then(function (nousSaleSddr) {
                console.log("NOUSSale:", nousSaleSddr);
                deployer.deploy([[NOUSPresale, nousSaleSddr], [NOUSCrowdsale, nousSaleSddr], [NOUSReservFund, nousSaleSddr]]);
            })


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



/*
 minETH 5500
NOUSToken: 0x4c51903cd51f6d1dd95594eaec030ed9f88e1b26
RefundVault: 0xb9aeae4633220c234af551c5d96836c9d1d33e5b
NOUSSale: 0xf0b69f818985e3fbe6da23083b59303223adf84b
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSPresale: 0x153e12097117988e48d9c673759afa8cfc48eb95
NOUSCrowdsale: 0x77716b97029a6ebb977ee51f683c5bda97748a43
NOUSReservFund: 0xc4e6456534d2aefe54b299f0a04f24eb9c7338a9
*/


/*
ETHMix 5
NOUSToken: 0xc9a4c7575645aa4dc9c2e24d1202c8b9b5156446
RefundVault: 0xf5d0c21b603560ccb26ec005784cd9d5dd779358
NOUSSale: 0xa29ce17d2d93ab02a41924b696504802820a7b9b
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSCrowdsale: 0xc7184f000f0b74ad6f8bf55158e9137a20179926
NOUSPresale: 0xcab91b76e1a94b91582688c8beeaf4a774c35e27
NOUSReservFund: 0x47da3301d02246ab5e1e010c3733aa084ee42943
*/
