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

	/// @dev reserve all bounty on this NOUSSale address contract
	function reserveBonuses() internal {
		require(saleState != SaleState.Ended);
		require(salesAgents[msg.sender].saleContractType == 'reserve_funds');

		uint256 totalSupply = token.totalSupply();

		for (uint256 i = 0; i < bountyPayment.length; i++) {
			if (bountyPayment[i].amountReserve == 0) {
				bountyPayment[i].amountReserve = totalSupply.mul(bountyPayment[i].percent).div(100); // reserve fonds on this contract
				token.mint(this, bountyPayment[i].amountReserve);
			}
		}
	}

	// @dev start only minet close
	function payDelayBonuses() public isSalesContract(msg.sender) {
		require(salesAgents[msg.sender].saleContractType == 'reserve_funds');
		require(saleState == SaleState.Ended);

		uint256 delayNextTime = 0;

		for (uint256 i = 0; i < bountyPayment.length; i++ )
		{
			uint256 dateDelay = salesAgents[msg.sender].startTime;

			for (uint256 p; p < bountyPayment[i].delay; p++){
				dateDelay = dateDelay + (30 days);
			}

			if ( bountyPayment[i].timeLastPayout == 0 ){
				delayNextTime = dateDelay;
			} else {
				delayNextTime = bountyPayment[i].timeLastPayout + (30 days);
			}

			if (now >= dateDelay
				&& bountyPayment[i].amountReserve > bountyPayment[i].totalPayout
				&& now >= delayNextTime)
			{
				uint256 payout = bountyPayment[i].amountReserve.div(bountyPayment[i].periodPathOfPay);
				token.transferFrom(this, bountyPayment[i].wallet, payout);
				bountyPayment[i].timeLastPayout = delayNextTime;
			}

		}

	}





}
