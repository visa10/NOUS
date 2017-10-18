pragma solidity ^0.4.4;

import "./SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";


import "./NOUSCrowdsale.sol";
import "./NOUSReservFund.sol";



contract NOUSPresale is SalesAgent {

  	using SafeMath for uint;

	function NOUSPresale(address _saleContractAddress){
		nousTokenSale = NOUSSale(_saleContractAddress);
	}

	function() payable external {
		// The target ether amount
		require(nousTokenSale.validateStateSaleContract(this));
		require(nousTokenSale.validateContribution(msg.value));
		require(msg.sender != 0x0);

		uint256 weiAmount = msg.value;

		uint256 rate = nousTokenSale.getSaleContractTokensRate(this);
		// calculate tokens - get bonus rate
		uint256 tokens = weiAmount.mul(rate);

		require(nousTokenSale.validPurchase(this, tokens)); // require tokens

		bool success = nousTokenSale.buyTokens.value(msg.value)(msg.sender, tokens);

		if (!success) {
			msg.sender.transfer(msg.value); // return back if not
			TokenValidateRefund(this, msg.sender, msg.value);
		} else {
			TokenPurchase(this, msg.sender, msg.value, tokens);
		}
	} 

}
