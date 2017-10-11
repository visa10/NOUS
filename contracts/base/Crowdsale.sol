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

	/// @dev this contact sale not payed/ Payed only forwardFunds TODO validate this
	function() payable external {}

	function buyTokens(address beneficiary, uint256 tokens) isSalesContract(msg.sender) public payable returns(bool) {
		require(saleState == SaleState.Active); // if sale is frozen
		require(beneficiary != 0x0);
		//require(msg.value > 0); // TODO validate

		token.mint(beneficiary, tokens);
		salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(tokens); // increment tokensMinted
		TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

		forwardFunds(beneficiary); // transfer ETH to refund contract
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
	function forwardFunds(address _sender) internal {
		wallet.transfer(msg.value);
	}

	/**
	* @dev Function to send NOUS to presale investors
	* Can only be called while the presale is not over.
	* @param _batchOfAddresses list of addresses
	* @param _amountOf matching list of address balances
	*/
	function deliverPresaleTokens(address _salesAgent, address[] _batchOfAddresses, uint256[] _amountOf)
		external ownerOrSale returns (bool success) {
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
	function deliverTokenToClient(address _salesAgent, address _accountHolder, uint256 _amountOf) ownerOrSale public returns(bool){
		require(_accountHolder != 0x0);
		require(_amountOf > 0);
		require(salesAgents[_salesAgent].isFinalized == false);
		require(salesAgents[_salesAgent].tokensLimit >= salesAgents[_salesAgent].tokensMinted.add(_amountOf));

		token.mint(_accountHolder, _amountOf);
		salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(_amountOf);

		TokenPurchase(msg.sender, _accountHolder, 0, _amountOf);
		return true;
	}

	function reserveBonuses() {

	}

	/*function payDelayBonuses() public isSalesContract(msg.sender) {
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

	}*/





}
