pragma solidity ^0.4.4;

import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import '../token/MintableToken.sol';
import '../NOUSToken.sol';

contract BaseContract is Ownable {

	/**** Libs *****************/

	using SafeMath for uint256;

	MintableToken public token; // The token being sold

	uint8 public constant decimals = 18;
	uint256 public exponent = 10**uint256(decimals);

	/**** Properties ***********/


	// 3% Community, 2% Will Be Used To Cover Token Sale
	address grantsAddress;

	// 20% Will Be Retained by Nousplatform
	// Nousplatform retained tokens are locked for the first 4 months, and will be vested over a period of 20 months total,
	// 5% every month. The total vesting period is 24 months.
	address teamAddress;

	// 5% Advisors, Grants, Partnerships  Advisors tokens are locked for 2 months and distributed fully.
	address advisersAddress;


	uint256 public totalSupplyCap; // 777 Million tokens Capitalize max count NOUS tokens
	uint256 public availablePurchase; // 543 900 000 tokens  Available for purchase
	uint256 public targetEthMin; // minimum amount of funds to be raised in weis

	uint256 public rate; // todo  rate is bonus

	address public wallet; // address where funds are collected
	uint256 public weiRaised; // amount of raised money in wei
	bool isGlobalFinalized = false; // global finalization

	/*** Sale Addresses *********/

	mapping (address => SalesAgent) salesAgents; // Our contract addresses of our sales contracts
	address[] private salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration


	struct BonusRateStruct {
		uint256 period; // in week rate
		uint256 rate;
	}

	struct SalesAgent {                     // These are contract addresses that are authorised to mint tokens
		address saleContractAddress;        // Address of the contract
		bytes32 saleContractType;           // Type of the contract ie. presale, crowdsale
		uint256 tokensLimit;                // The maximum amount of tokens this sale contract is allowed to distribute
		uint256 tokensMinted;               // The current amount of tokens minted by this agent
		uint256 rate;						// default rate
		uint256 targetEthMax;               // The max amount of ether the agent is allowed raise
		uint256 targetEthMin;               // The min amount of ether to raise to consider this contracts sales a success
		uint256 minDeposit;                 // The minimum deposit amount allowed
		uint256 maxDeposit;                 // The maximum deposit amount allowed
		uint256 startTime;                  // The start time (unix format) when allowed to mint tokens
		uint256 endTime;                    // The end time from unix format when to finish minting tokens
		bool isFinalized;                   // Has this sales contract been completed and the ether sent to the deposit address?
		bool exists;                        // Check to see if the mapping exists
		bool isLastSale; 					// Last sale
		uint256[] bonusRatesIndex;			// index rates
		mapping (uint256 => BonusRateStruct) bonusRates; // if one bonus is default
	}

	event SaleFinalised(address _agent, address _address, uint256 _value);


	/// @dev Only allow access from the latest version of a sales contract
	modifier isSalesContract(address _sender) {
		// Is this an authorised sale contract?
		assert(salesAgents[_sender].exists == true);
		_;
	}

	function BaseContract(){
		if (address(token) == 0x0) {
			token = createTokenContract();
		}
	}

	// creates the token to be sold.
	// override this method to have crowdsale of a specific mintable token.
	function createTokenContract() internal returns (MintableToken) {
		return new NOUSToken();
	}

	/// @dev Set the address of a new crowdsale/presale contract agent if needed, usefull for upgrading
	/// @param _saleAddress The address of the new token sale contract
	/// @param _saleContractType Type of the contract ie. presale, crowdsale, quarterly
	/// @param _tokensLimit The maximum amount of tokens this sale contract is allowed to distribute
	/// @param _minDeposit The minimum deposit amount allowed
	/// @param _maxDeposit The maximum deposit amount allowed
	/// @param _startTime The start block when allowed to mint tokens
	/// @param _endTime The end block when to finish minting tokens
	function setSaleAgentContract(
		address _saleAddress,
		bytes32 _saleContractType,
		uint256 _tokensLimit,
		uint256 _minDeposit,
		uint256 _maxDeposit,
		uint256 _startTime,
		uint256 _endTime,
		bool _isLastSale
	)
	// Only the owner can register a new sale agent
	public onlyOwner
	{
		// Valid addresses?
		require(_saleAddress != 0x0);
		// Must have some available tokens
		require(_tokensLimit > 0 && _tokensLimit <= totalSupplyCap);
		// Make sure the min deposit is less than or equal to the max
		require(_minDeposit <= _maxDeposit);

		require(_startTime >= now);

		require(_endTime >= _startTime);

		// Add the new sales contract

		SalesAgent memory newSalesAgent;
		newSalesAgent.saleContractAddress = _saleAddress;
		newSalesAgent.saleContractType = _saleContractType;
		newSalesAgent.tokensLimit = _tokensLimit;
		newSalesAgent.tokensMinted = 0;
		newSalesAgent.minDeposit = _minDeposit;
		newSalesAgent.maxDeposit = _maxDeposit;
		newSalesAgent.startTime = _startTime;
		newSalesAgent.endTime = _endTime;
		newSalesAgent.isFinalized = false;
		newSalesAgent.exists = true;
		newSalesAgent.isLastSale = _isLastSale; // after sale start global finalize
		//newSalesAgent.bonusRates = new BonusRateStruct[](0); // after sale start global finalize

		salesAgents[_saleAddress] = newSalesAgent;

		// Store our agent address so we can iterate over it if needed
		salesAgentsAddresses.push(_saleAddress);
	}

	/// @dev Returns true if this sales contract has finalised
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractIsFinalised(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
		return salesAgents[_salesAgentAddress].isFinalized;
	}


	/// @dev Returns the min target amount of ether the contract wants to raise
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTargetEtherMin(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].targetEthMin;
	}

	/// @dev Returns the max target amount of ether the contract can raise
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTargetEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].targetEthMax;
	}


	/// @dev Returns the start block for the sale agent
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractStartTime(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].startTime;
	}

	/// @dev Returns the start block for the sale agent
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractEndTime(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].endTime;
	}

	/// @dev Returns the max tokens for the sale agent
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTokensLimit(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].tokensLimit;
	}

	/// @dev Returns the token total currently minted by the sale agent
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTokensMinted(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].tokensMinted;
	}

}
