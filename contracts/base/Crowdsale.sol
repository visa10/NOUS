pragma solidity ^0.4.11;


import './BaseContract.sol';

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


	// fallback function can be used to buy tokens
	function () payable {
		buyTokens(msg.sender);
	}

	// low level token purchase function
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != 0x0);
		require(validPurchase());

		uint256 weiAmount = msg.value;

		//uint256 currentRate = getRate();

		// calculate token amount to be created
		uint256 tokens = weiAmount.mul(rate).div(1 ether);

		// update state
		weiRaised = weiRaised.add(weiAmount);

		token.mint(beneficiary, tokens);
		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	// send ether to the fund collection wallet
	// override to create custom fund forwarding mechanisms
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	// @return true if the transaction can buy tokens
	function validPurchase() internal constant returns (bool) {
			now >= salesAgents[msg.sender].startTime && now <= salesAgents[msg.sender].endTime // within time
			&& weiRaised.add(msg.value) <= totalSupplyCap // within cap
			&& msg.value > 0 // non zero
			&& salesAgents[msg.sender].tokensMinted <= salesAgents[msg.sender].tokensLimit; // within Tokens mined
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
			isGlobalFinalized= true;

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
