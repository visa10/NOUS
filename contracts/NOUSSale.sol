pragma solidity ^0.4.11;


import "./token/MintableToken.sol";
import "./base/Crowdsale.sol";


contract NOUSSale is Crowdsale {

	//wallet = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148; // todo add address wallet amount

	function NOUSSale(address _wallet, address _token)
	BaseContract(_wallet)
	{
		//777 Million tokens
		totalSupplyCap = 777 * (10**6);

		//543 900 000 tokens  Available for purchase
		availablePurchase = 543900000;

		// minimum amount of funds to be raised in weis
		targetEthMax = 85000 * (1 ether);

		// minimum amount of funds to be raised in weis
		targetEthMin = 5500  * (1 ether);
		//rate = 6400;
		
		token = MintableToken(_token);

		//TODO Set Real address
		// 20% Will Be Retained by Nousplatform
		// Nousplatform retained tokens are locked for the first 4 months, and will be vested over a period of 20 months total,
		// 5% every month. The total vesting period is 24 months.
		addPaymentBounty(0xe594004148C30B1762A108F017999F081aDa8143, "TeamBonus", 20, 4, 5); // test account 4

		// 5% Advisors, Grants, Partnerships  Advisors tokens are locked for 2 months and distributed fully.
		addPaymentBounty(0x4043BF02966Fa198fa24489Ca76DE1Be669f6e33, "AdvisorsBonus", 5, 2, 1); // test account 5

		// 3% Community, 2% Will Be Used To Cover Token Sale
		addPaymentBounty(0x96473fFE81913158a113bA5683B050DD264d2a9C, "GrantsBonus",  5, 0, 1); // test account 6

	}



}
