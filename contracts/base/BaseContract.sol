pragma solidity ^0.4.4;

import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../token/MintableToken.sol";
import "../NOUSToken.sol";
import './RefundVault.sol';


contract BaseContract is Ownable {

	/**** Libs *****************/

	using SafeMath for uint256;

	/**** Variables ****************/

	MintableToken public token; // The token being sold

	RefundVault public vault; // contract refunded value

	enum SaleState { Active, Pending, Ended }
	SaleState public saleState;

	uint8 public constant decimals = 18;
	uint256 public exponent = 10**uint256(decimals);

	/**** Properties ***********/

	uint256 public totalSupplyCap; // 777 Million tokens Capitalize max count NOUS tokens
	uint256 public availablePurchase; // 543 900 000 tokens  Available for purchase
	uint256 public targetEthMax; // The max amount of ether the agent is allowed raise
	uint256 public targetEthMin; // minimum amount of funds to be raised in weis

	address public wallet; // address where funds are collected Deposit address
	uint256 public weiRaised; // amount of raised money in wei

	//bool public isGlobalFinalized = false; // global finalization

	/**** Events ***********/

	event SaleFinalised(address _agent, address _address, uint256 _amountMint);

	event TotalOutBounty(address _agent, address _wallet, bytes32 _name, uint256 _totalPayout); // all payed to bonus

	event PayBounty(address _agent, address _wallet, bytes32 _name, uint256 _amount);


	struct Bounty {
		address wallet; // wallet address for transfer
		bytes32 name; // name bonus
		uint256 delay; // delay to payment in month
		uint256 percent; // percent payed
		uint256 periodPathOfPay; // on how many equal parts to pay
		uint256 amountReserve; // amount acured
		uint256 totalPayout; // how is payed
		uint256 timeLastPayout; // how is payed
	}

	Bounty[] bountyPayment; // array bonuses

	mapping (address => SalesAgent) salesAgents; // Our contract addresses of our sales contracts
	address[] private salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration

	/*struct BonusRateStruct {
		uint256 period; // in week rate
		uint256 rate;
	}*/

	enum SaleContractType { Presale, Crowdsale, ReserveFunds }

	struct SalesAgent {                     // These are contract addresses that are authorised to mint tokens
		address saleContractAddress;        // Address of the contract
		SaleContractType saleContractType;   // Type of the contract ie. presale, crowdsale, reserve_funds
		uint256 tokensLimit;                // The maximum amount of tokens this sale contract is allowed to distribute
		uint256 tokensMinted;               // The current amount of tokens minted by this agent
		uint256 rate;						// default rate
		uint256 minDeposit;                 // The minimum deposit amount allowed
		//uint256 maxDeposit;                 // The maximum deposit amount allowed
		uint256 startTime;                  // The start time (unix format) when allowed to mint tokens
		uint256 endTime;                    // The end time from unix format when to finish minting tokens
		bool isFinalized;                   // Has this sales contract been completed and the ether sent to the deposit address?
		bool exists;                        // Check to see if the mapping exists
		//uint256[] bonusRatesIndex;			// index rates
		//mapping (uint256 => BonusRateStruct) bonusRates; // if one bonus is default
	}

	/**** Modifier ***********/

	/// @dev Only allow access from the latest version of a sales contract
	modifier isSalesContract(address _sender) {
		// Is this an authorised sale contract?
		assert(salesAgents[_sender].exists == true);
		_;
	}

	modifier ownerOrSale() {
		assert(salesAgents[msg.sender].exists == true || msg.sender == owner);
		_;
	}

	//****************Constructors*******************//

	/// @dev constructor
	function BaseContract(address _wallet, address _token, address _vault){
		wallet = _wallet;

		if (address(token) == 0x0) {
			token = createTokenContract(_token);
		}

		if (address(vault) == 0x0) {
			vault = createRefundVault(_vault);
		}
	}

	// creates the token to be sold.
	// override this method to have crowdsale of a specific mintable token.
	function createTokenContract(address _token) internal returns (MintableToken) {
		//return new NOUSToken();
		return MintableToken(_token);
	}

	function createRefundVault(address _vault) internal returns (RefundVault){
		//return new RefundVault(_wallet);
		return RefundVault(_vault);
	}

	//**************Setters*****************//

	/// @dev Set the address of a new crowdsale/presale contract agent if needed, usefull for upgrading
	/// @param _saleAddress The address of the new token sale contract
	/// @param _saleContractType Type of the contract ie. presale, crowdsale, quarterly
	/// @param _tokensLimit The maximum amount of tokens this sale contract is allowed to distribute
	/// @param _minDeposit The minimum deposit amount allowed
	/// @param _startTime The start block when allowed to mint tokens
	/// @param _endTime The end block when to finish minting tokens
	function setSaleAgentContract(
		address _saleAddress,
		SaleContractType _saleContractType,
		uint256 _tokensLimit,
		uint256 _minDeposit,
		//uint256 _maxDeposit,
		uint256 _startTime,
		uint256 _endTime,
		uint256 _rate
	)
	// Only the owner can register a new sale agent
	public onlyOwner
	{
		uint256 _tokensMinted = changeActiveSale(_saleContractType);
		// if Sale state closed do not add sale config
		require(saleState != SaleState.Ended);
		// Valid addresses?
		require(_saleAddress != 0x0);
		// Must have some available tokens
		require(_tokensLimit > 0 && _tokensLimit <= totalSupplyCap);
		// Make sure the min deposit is less than or equal to the max
		//require(_minDeposit <= _maxDeposit);
		//require(_startTime >= now);
		require(_endTime > _startTime);
		// Add the new sales contract
		SalesAgent memory newSalesAgent;
		newSalesAgent.saleContractAddress = _saleAddress;
		newSalesAgent.saleContractType = _saleContractType;
		newSalesAgent.tokensLimit = _tokensLimit * exponent;
		newSalesAgent.tokensMinted = 0;
		newSalesAgent.minDeposit = _minDeposit;
		//newSalesAgent.maxDeposit = _maxDeposit;
		newSalesAgent.startTime = _startTime;
		newSalesAgent.endTime = _endTime;
		newSalesAgent.rate = _rate;
		newSalesAgent.isFinalized = false;
		newSalesAgent.exists = true;
		newSalesAgent.tokensMinted = _tokensMinted;

		//newSalesAgent.bonusRates = new BonusRateStruct[](0); // after sale start global finalize
		salesAgents[_saleAddress] = newSalesAgent;
		// Store our agent address so we can iterate over it if needed
		salesAgentsAddresses.push(_saleAddress);
	}

	/// @dev add bounty initial state
	function setPaymentBounty(address _walletAddress, bytes32 _name, uint256 _percent, uint256 _delay, uint256 _periodPathOfPay) internal {
		assert(_walletAddress != 0x0);

		Bounty memory newBounty;
		newBounty.wallet = _walletAddress;
		newBounty.name = _name;
		newBounty.percent = _percent;
		newBounty.delay = _delay;
		newBounty.periodPathOfPay = _periodPathOfPay;
		newBounty.amountReserve = 0;
		newBounty.totalPayout = 0;

		bountyPayment.push(newBounty);
	}

	//****************Refund*******************//

	// validate goal
	function goalReached() public constant returns (bool) {
		return weiRaised > targetEthMin;
	}

	// if crowdsale is unsuccessful, investors can claim refunds here
	function claimRefund(address beneficiary) isSalesContract(msg.sender) public returns (uint256) {
		require(saleState == SaleState.Ended); // refund started only closed contract
		require(!goalReached());

		//token. TODO get token
		return vault.refund(beneficiary);
	}

	//****************Manager*******************//

	/// @dev stop sale
	function pendingActiveSale() onlyOwner {
		require(saleState != SaleState.Ended);
		if (saleState == SaleState.Pending){
			saleState = SaleState.Active;
		} else {
			saleState = SaleState.Pending;
		}
	}

	function changeActiveSale(SaleContractType _saleContractType) internal returns(uint256) {
		for (uint256 i=0; i<salesAgentsAddresses.length; i++){
			if (salesAgents[salesAgentsAddresses[i]].saleContractType == _saleContractType
				&& salesAgents[salesAgentsAddresses[i]].isFinalized == false)
				{
					salesAgents[salesAgentsAddresses[i]].isFinalized = true;
					return salesAgents[salesAgentsAddresses[i]].tokensMinted;
				}
		}
		return 0;
	}

	/// @dev warning Change owner token contact
	function changeTokenOwner(address newOwner) onlyOwner {
		token.transferOwnership(newOwner);
	}

	//***************Getters******************/

	/// @dev Returns true if this sales contract has finalised
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getSaleContractIsFinalised(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
		return salesAgents[_salesAgentAddress].isFinalized;
	}

	/// @dev Returns the min target amount of ether the contract wants to raise
	/// @param _salesAgentAddress The address of the token sale agent contract
	/*function getTargetEtherMin() constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return targetEthMin;
	}*/

	/// @dev Returns the max target amount of ether the contract can raise
	/// @param _salesAgentAddress The address of the token sale agent contract
	/*function getTargetEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
		return targetEthMax;
	}*/

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
