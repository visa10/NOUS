pragma solidity ^0.4.4;

import "../base/SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";
import "../base/Ownable.sol";

contract NOUSReservFund is SalesAgent, Ownable {

	function NOUSReservFund(address _saleContractAddress){
		nousTokenSale = NOUSSale(_saleContractAddress);
	}

	function claimRefund() public {
		uint256 _value = nousTokenSale.claimRefund(msg.sender);
		Refund(this, msg.sender, _value);
	}




}
