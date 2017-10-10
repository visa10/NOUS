pragma solidity ^0.4.4;

import "../base/SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";

contract NOUSPresale is SalesAgent, Ownable {

  	using SafeMath for uint;

	function NOUSPresale(address _saleContractAddress){
		nousTokenSale = NOUSSale(_saleContractAddress);
	}

	function() payable external {
		// The target ether amount
		require(nousTokenSale.validateContribution(msg.value));
		require(msg.sender != 0x0);

		uint256 weiAmount = msg.value;

		uint256 rate = nousTokenSale.getSaleContractTokensRate(this);
		// calculate tokens - get bonus rate
		uint256 tokens = weiAmount.mul(rate).div(1 ether);

		require(nousTokenSale.validPurchase(tokens)); // require tokens

		bool success = nousTokenSale.buyTokens.value(msg.value)(msg.sender, tokens);

		if (!success) {
			msg.sender.transfer(msg.value); // return back if not
			TokenValidateRefund(msg.sender, msg.value);
		} else {
			TokenPurchase(msg.sender, msg.value, tokens);
		}
	}



}
