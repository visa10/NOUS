pragma solidity ^0.4.11;


import "./token/MintableToken.sol";
import "./base/RefundableCrowdsale.sol";


contract NOUSSale is RefundableCrowdsale {

	function Sale(){

		totalSupplyCap = 777 * (10**6) * exponent;    //777 Million tokens
		availablePurchase = 543900000 * exponent;    //543 900 000 tokens  Available for purchase
		targetEthMax = 85000 * (1 ether); // minimum amount of funds to be raised in weis
		targetEthMin = 5500  * (1 ether); // minimum amount of funds to be raised in weis
		rate = 6400;
		wallet = 0x0; // todo add address wallet amount

		//TODO Set Real address
		// 20% Will Be Retained by Nousplatform
		// Nousplatform retained tokens are locked for the first 4 months, and will be vested over a period of 20 months total,
		// 5% every month. The total vesting period is 24 months.
		addPaymentBounty("0xAD4016f585DA476073c7D53a5E53d9Ec6c735204", "TeamBonus", 20, 4, 20, 5);

		// 5% Advisors, Grants, Partnerships  Advisors tokens are locked for 2 months and distributed fully.
		addPaymentBounty("0xAD4016f585DA476073c7D53a5E53d9Ec6c735204", "AdvisorsBonus", 5, 2, 0, 100); // Advisors tokens are locked for 2 months and distributed fully.

		// 3% Community, 2% Will Be Used To Cover Token Sale
		addPaymentBounty("0xAD4016f585DA476073c7D53a5E53d9Ec6c735204", "GrantsBonus",  5, 0, 0, 100);

	}



}
