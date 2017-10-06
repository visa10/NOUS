pragma solidity ^0.4.11;


import "./token/MintableToken.sol";
import "./base/RefundableCrowdsale.sol";


contract Sale is RefundableCrowdsale {


	function Sale(){

		totalSupplyCap = 777 * (10**6) * exponent;    //777 Million tokens
		availablePurchase = 543900000 * exponent;    //543 900 000 tokens  Available for purchase
		targetEthMin = 5500; // minimum amount of funds to be raised in weis
		rate = 6400;
	}



}
