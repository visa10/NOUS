pragma solidity ^0.4.4;

import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../token/MintableToken.sol";
import "../NOUSToken.sol";


contract BaseContract is Ownable {

	/**** Libs *****************/

	using SafeMath for uint256;

	MintableToken public token; // The token being sold

	enum SaleState { Active, Pending, Closed }
	SaleState public saleState;

	uint8 public constant decimals = 18;
	uint256 public exponent = 10**uint256(decimals);

	/**** Properties ***********/

	uint256 public totalSupplyCap; // 777 Million tokens Capitalize max count NOUS tokens
	uint256 public availablePurchase; // 543 900 000 tokens  Available for purchase
	uint256 public targetEthMax;               // The max amount of ether the agent is allowed raise
	uint256 public targetEthMin; // minimum amount of funds to be raised in weis

	uint256 public rate; // todo  rate is bonus

	address public wallet; // address where funds are collected Deposit address
	uint256 public weiRaised; // amount of raised money in wei

	bool isGlobalFinalized = false; // global finalization

	/// events ///
	event SaleFinalised(address _agent, address _address, uint256 _value);

	event TotalOutBounty(address _agent, address _wallet, bytes32 _name, uint256 _totalPayout); // all payed to bonus

	event PayBounty(address _agent, address _wallet, bytes32 _name, uint256 _amount);

	event SaleFinalised(address _agent, address _address, uint256 _value);

	struct Bounty {
		address wallet; // wallet address for transfer
		bytes32 name; // name bonus
		uint256 delay; // delay to payment in month
		uint256 percent; // percent payed
		uint256 periodForPay; // period for payaut equal patch. month if 0 then payed after delay?
		uint256 percentPeriodPay;
		uint256 amount; // amount acured
		uint256 totalPayout; // how is payed
	}

	Bounty[] bountyPayment; // array bonuses

	mapping (address => SalesAgent) salesAgents; // Our contract addresses of our sales contracts
	address[] private salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration

	/*struct BonusRateStruct {
		uint256 period; // in week rate
		uint256 rate;
	}*/

	struct SalesAgent {                     // These are contract addresses that are authorised to mint tokens
		address saleContractAddress;        // Address of the contract
		bytes32 saleContractType;           // Type of the contract ie. presale, crowdsale
		uint256 tokensLimit;                // The maximum amount of tokens this sale contract is allowed to distribute
		uint256 tokensMinted;               // The current amount of tokens minted by this agent
		uint256 rate;						// default rate
		uint256 minDeposit;                 // The minimum deposit amount allowed
		uint256 maxDeposit;                 // The maximum deposit amount allowed
		uint256 startTime;                  // The start time (unix format) when allowed to mint tokens
		uint256 endTime;                    // The end time from unix format when to finish minting tokens
		bool isFinalized;                   // Has this sales contract been completed and the ether sent to the deposit address?
		bool exists;                        // Check to see if the mapping exists
		bool isLastSale; 					// Last sale
		//uint256[] bonusRatesIndex;			// index rates
		//mapping (uint256 => BonusRateStruct) bonusRates; // if one bonus is default
	}



	/// @dev Only allow access from the latest version of a sales contract
	modifier isSalesContract(address _sender) {
		// Is this an authorised sale contract?
		assert(salesAgents[_sender].exists == true);
		_;
	}

	modifier ownerOrSale(){
		assert(salesAgents[msg.sender].exists == true || msg.sender == owner);
		_;
	}

	/// @dev constructor
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
		// if Sale state closed do not add sale config
		require(saleState != SaleState.Closed);
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

	/// @dev add bounty initial state
	function addPaymentBounty(address _walletAddress, bytes32 _name, uint256 _percent, uint256 _delay, uint256 _periodForPay, uint256 _percentPeriodPay) internal {
		assert(_walletAddress != 0x0);

		Bounty memory newBounty;
		newBounty.wallet = _walletAddress;
		newBounty.name = _name;
		newBounty.percent = _percent;
		newBounty.delay = _delay;
		newBounty.periodForPay = _periodForPay;
		newBounty.percentPeriodPay = _percentPeriodPay;

		bountyPayment.push(newBounty);
	}

	/// @dev Sets the contract sale agent process as completed, that sales agent is now retired
	/// oweride if ne logic and coll super finalize
	function finalizeSaleContract(address _sender) isSalesContract(msg.sender) public returns(bool) {
		require(!salesAgents[msg.sender].isFinalized);
		require(hasEnded());

		salesAgents[msg.sender].isFinalized = true;
		SaleFinalised(msg.sender, _sender, salesAgents[msg.sender].tokensMinted);
		return true;
	}

	/// @dev global finalization is activate this function all sales wos stoped.
	function finalizeICO() isSalesContract(msg.sender) public returns(bool)  {
		require(!isGlobalFinalized);
		require(hasEnded());
		globalFinalization();
		saleState != SaleState.Closed; // close all sale
		token.finishMinting(); // stop mining tokens
		return true;
	}

	function globalFinalization() internal {
		isGlobalFinalized = true;
		//logic global finalization
	}

	/// @return true if crowdsale event has ended and call super.hasEnded
	function hasEnded() public constant returns (bool) {
		salesAgents[msg.sender].tokensMinted >= salesAgents[msg.sender].tokensLimit //capReachedToken
		|| weiRaised >= targetEthMax //capReachedWei
		|| totalSupplyCap >= token.totalSupply()
		|| now > salesAgents[msg.sender].endTime; //timeAllow
	}

	/// @dev stop sale
	function setPendingSale() onlyOwner {
		if (saleState != SaleState.Closed){
			saleState = SaleState.Pending;
		}
	}

	/// @dev Activate
	function setActiveSale() onlyOwner {
		if (saleState != SaleState.Closed){
			saleState = SaleState.Active;
		}
	}

	/// @dev warning Change owner token contact
	function changeTokenOwner(address newOwner) onlyOwner {
		token.transferOwnership(newOwner);
	}

	/// @dev Returns true if this sales contract has finalised
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractIsFinalised(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
		return salesAgents[_salesAgentAddress].isFinalized;
	}


	/// @dev Returns the min target amount of ether the contract wants to raise
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTargetEtherMin(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return targetEthMin;
	}

	/// @dev Returns the max target amount of ether the contract can raise
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTargetEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return targetEthMax;
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

	/// @dev Returns the token total currently minted by the sale agent
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractTokensRate(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return salesAgents[_salesAgentAddress].rate;
	}

}
