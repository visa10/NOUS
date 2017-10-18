pragma solidity ^0.4.11;

import "../NOUSSale.sol";
import "../base/Ownable.sol";

contract SalesAgent is Ownable{

    //address saleContractAddress;                           // Main contract token address

    NOUSSale nousTokenSale; // contract nous sale

    /**
	* event for token purchase logging
	* @param beneficiary who got the tokens
	* @param value weis paid for purchase
	* @param amount amount of tokens purchased
	*/
	event TokenPurchase(address _agent, address indexed beneficiary, uint256 value, uint256 amount);

	// refund token if not valid;
	event TokenValidateRefund(address _agent, address indexed beneficiary, uint256 value);


	//uint256[] bonusRatesIndex;			// index rates
	//mapping (uint256 => BonusRateStruct) bonusRates; // if one bonus is default


//    mapping (address => uint256) public contributions;      // Contributions per address
//    uint256 public contributedTotal;                        // Total ETH contributed
//
//    /// @dev Only allow access from the main token contract
//    modifier onlyTokenContract() {
//        assert(saleContractAddress != 0 && msg.sender == saleContractAddress);
//        _;
//    }
//
    event Contribute(address _agent, address _sender, uint256 _value);
    event FinaliseSale(address _agent, address _sender, uint256 _value);
    event Refund(address _agent, address _sender, uint256 _value);
    event ClaimTokens(address _agent, address _sender, uint256 _value);
//    event TransferToDepositAddress(address _agent, address _sender, uint256 _value);
//
//
//    /// @dev Get the contribution total of ETH from a contributor
//    /// @param _owner The owners address
//    function getContributionOf(address _owner) constant returns (uint256 balance) {
//        return contributions[_owner];
//    }

    /// @dev The address used for the depositAddress must checkin with the contract to verify it can interact with this contract, must happen or it won't accept funds
    /*function setDepositAddressVerify() public {
        // Get the token contract
        NOUSSale nousSale = NOUSSale(saleContractAddress);
        // Is it the right address? Will throw if incorrect
        nousSale.setSaleContractDepositAddressVerified(msg.sender);
    }*/

	function finaliseFunding() onlyOwner {

		// Do some common contribution validation, will throw if an error occurs - address calling this should match the deposit address
		if (nousTokenSale.finalizeSaleContract(this)) {
			uint256 tokenMinted = nousTokenSale.getSaleContractTokensMinted(this);
			FinaliseSale(this, msg.sender, tokenMinted);
		}
	}

	/*function setSaleAddress(address _saleContractAddress) onlyOwner {
		nousTokenSale = NOUSSale(_saleContractAddress);
	}*/


}