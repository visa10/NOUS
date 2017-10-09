pragma solidity ^0.4.11;


import './BaseFunctions.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is BaseFunctions {

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


	// fallback function can be used to buy tokens
	function () payable {
		buyTokens(msg.sender);
	}

	// low level token purchase function
	function buyTokens(address beneficiary) isSalesContract(msg.sender)  public payable returns(bool) {
		require(beneficiary != 0x0);

		uint256 weiAmount = msg.value;

		//uint256 currentRate = getRate();

		// calculate token amount to be created
		uint256 tokens = weiAmount.mul(rate).div(1 ether);

		//validate
		require(validPurchase(tokens));

		// update state
		weiRaised = weiRaised.add(weiAmount);

		token.mint(beneficiary, tokens);
		salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(tokens);

		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();

		return true;
	}

	// send ether to the fund collection wallet
	// override to create custom fund forwarding mechanisms
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	// @return true if the transaction can buy tokens
	function validPurchase(uint _tokens) internal constant returns (bool) {
			now >= salesAgents[msg.sender].startTime && now <= salesAgents[msg.sender].endTime // within time
			&& salesAgents[msg.sender].isFinalized == false // No minting if the sale contract has finalised
			&& weiRaised.add(msg.value) <= totalSupplyCap // within cap
			&& msg.value > 0 // non zero
			&& salesAgents[msg.sender].tokensLimit >= salesAgents[msg.sender].tokensMinted.add(_tokens); // within Tokens mined
	}

	/**
	* @dev Must be called after crowdsale ends, to do some extra finalization
	* work. Calls the contract's finalization function.
	*/
	function finalize() onlyOwner {
		require(!salesAgents[msg.sender].isFinalized);
		require(hasEnded());

		finalization();

		Finalized();

		salesAgents[msg.sender].isFinalized = true;

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
		&& weiRaised >= totalSupplyCap //capReachedWei
		&& now > salesAgents[msg.sender].endTime; //timeAllow
	}

	/**
	* @dev Function to send NOUS to presale investors
	* Can only be called while the presale is not over.
	* @param _batchOfAddresses list of addresses
	* @param _amountOf matching list of address balances
	*/
	function deliverPresaleTokens(address[] _batchOfAddresses, uint256[] _amountOf)
		external isSalesContract(msg.sender)  returns (bool success) {

		require(now < salesAgents[msg.sender].startTime);
		require(_batchOfAddresses.length == _amountOf.length);
		require(salesAgents[msg.sender].saleContractType == 'presale');

		for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
			deliverTokenToClient(_batchOfAddresses[i], _amountOf[i]);
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
	function deliverTokenToClient(address _accountHolder, uint256 _amountOf) isSalesContract(msg.sender) public returns(bool){
		require(_accountHolder != 0x0);
		require(_amountOf > 0);
		require(salesAgents[msg.sender].isFinalized == false);
		require(salesAgents[msg.sender].tokensLimit >= salesAgents[msg.sender].tokensMinted.add(_amountOf));

		token.mint(_accountHolder, _amountOf);
		salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(_amountOf);

		TokenPurchase(msg.sender, _accountHolder, 0, _amountOf);
		return true;
	}

	/**
	* @dev Can be overridden to add finalization logic. The overriding function
	* should call super.finalization() to ensure the chain of finalization is
	* executed entirely.
	*/
	function finalization() internal {}

	/**
	* @dev Add global finalization logic after all sales agents
	*/
	function globalFinalization() internal {
		//todo finalize NOUSToken contract
	}





}
