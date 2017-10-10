pragma solidity ^0.4.11;


import './BaseContract.sol';
import "../interfaces/SalesAgentInterface.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is BaseContract {

	/**
	* event for token purchase logging
	* @param purchaser who paid for the tokens
	* @param beneficiary who got the tokens
	* @param value weis paid for purchase
	* @param amount amount of tokens purchased
	*/
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	event Finalized();

	event GlobalFinalized();

	function buyTokens(address beneficiary, uint256 tokens) isSalesContract(msg.sender) public payable returns(bool) {
		require(beneficiary != 0x0);
		require(msg.value > 0);

		token.mint(beneficiary, tokens);
		salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(tokens); // increment tokensMinted
		TokenPurchase(msg.sender, beneficiary, msg.value, tokens);
		forwardFunds(); // transfer ETH to refund contract
		weiRaised = weiRaised.add(msg.value); // increment wei Raised

		return true;
	}

	// @dev Validate Mined tokens
	function validPurchase(uint _tokens) isSalesContract(msg.sender) returns (bool) {
		salesAgents[msg.sender].isFinalized == false // No minting if the sale contract has finalised
		&& now > salesAgents[msg.sender].startTime
		&& now < salesAgents[msg.sender].endTime // within time
		&& _tokens > 0 // non zero
		&& salesAgents[msg.sender].tokensLimit >= salesAgents[msg.sender].tokensMinted.add(_tokens) // within Tokens mined
		&& totalSupplyCap >= token.totalSupply().add(_tokens);
	}

	// @dev General validation for a sales agent contract receiving a contribution, additional validation can be done in the sale contract if required
	// @param _value The value of the contribution in wei
	// @return A boolean that indicates if the operation was successful.
	function validateContribution(uint256 _value) isSalesContract(msg.sender) returns (bool) {
		_value > 0
		&& wallet != 0x0 // Check the depositAddress has been verified by the account holder
		&& salesAgents[msg.sender].isFinalized == false
		&& now > salesAgents[msg.sender].startTime  // Check started
		&& now < salesAgents[msg.sender].endTime
		&& _value >= salesAgents[msg.sender].minDeposit // Is it above the min deposit amount?
		&& _value <= salesAgents[msg.sender].maxDeposit
		&& weiRaised.add(_value) <= targetEthMax; // Does this deposit put it over the max target ether for the sale contract?
	}


	// send ether to the fund collection wallet
	// override to create custom fund forwarding mechanisms
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	/**
	* @dev Must be called after crowdsale ends, to do some extra finalization
	* work. Calls the contract's finalization function.
	*/
	function finalize(address _saleAgentAddress) onlyOwner {
		require(!salesAgents[_saleAgentAddress].isFinalized);
		require(hasEnded());

		salesAgents[_saleAgentAddress].isFinalized = true;

		Finalized();

		// if is last sale, start global finalization transfer eth, stop mine
		if (salesAgents[msg.sender].isLastSale) {

			assert(!isGlobalFinalized);

			globalFinalization();
			isGlobalFinalized = true;

			GlobalFinalized();
		}
	}

	// @return true if crowdsale event has ended and call super.hasEnded
	function hasEnded() public constant returns (bool) {
		salesAgents[msg.sender].tokensMinted >= salesAgents[msg.sender].tokensLimit //capReachedToken
		|| weiRaised >= targetEthMax //capReachedWei
		|| totalSupplyCap >= token.totalSupply()
		|| now > salesAgents[msg.sender].endTime; //timeAllow
	}

	/**
	* @dev Add global finalization logic after all sales agents
	*/
	function globalFinalization() internal {
		//todo finalize NOUSToken contract


		//token.mint(this, );

		token.finishMinting();
	}

	/**
	* @dev Function to send NOUS to presale investors
	* Can only be called while the presale is not over.
	* @param _batchOfAddresses list of addresses
	* @param _amountOf matching list of address balances
	*/
	function deliverPresaleTokens(address _salesAgent, address[] _batchOfAddresses, uint256[] _amountOf)
		external onlyOwner returns (bool success) {
		//require(now < salesAgents[msg.sender].startTime);
		//require(salesAgents[msg.sender].saleContractType == 'presale');
		require(_batchOfAddresses.length == _amountOf.length);

		for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
			deliverTokenToClient(_salesAgent, _batchOfAddresses[i], _amountOf[i]);
		}
		return true;
	}

	/**
	* @dev Logic to transfer presale tokens
	* Can only be called while the there are leftover presale tokens to allocate. Any multiple contribution from
	* the same address will be aggregated.
	* @param _accountHolder user address
	* @param _amountOf balance to send out
	*/
	function deliverTokenToClient(address _salesAgent, address _accountHolder, uint256 _amountOf) onlyOwner public returns(bool){
		require(_accountHolder != 0x0);
		require(_amountOf > 0);
		require(salesAgents[_salesAgent].isFinalized == false);
		require(salesAgents[_salesAgent].tokensLimit >= salesAgents[_salesAgent].tokensMinted.add(_amountOf));

		token.mint(_accountHolder, _amountOf);
		salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(_amountOf);

		TokenPurchase(msg.sender, _accountHolder, 0, _amountOf);
		return true;
	}

	function payDelayBonuses() public isSalesContract(msg.sender) {
		require(salesAgents[msg.sender].saleContractType == 'reserve');
		require(salesAgents[msg.sender].endTime > now);

		uint256 totalSupply = token.totalSupply();

		for (uint256 i = 0; i < paymentIndex.length; i++ ){
			Bounty bounty = bountyPercent[paymentIndex[i]];

			if (bounty.paymentDelay == true){ //validate for payment
				continue;
			}

			uint256 dateEndDelay = salesAgents[msg.sender].startTime;

			for (uint256 p; p < bounty.delay; p++){
				dateEndDelay = dateEndDelay + (30 days);
			}

			if (now <= dateEndDelay) {
				uint256 sumForPay = totalSupply.mul(bounty.percentForPay).div(100);
				token.mint(bounty.wallet, sumForPay);
				salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(sumForPay);
			}
		}

	}





}
