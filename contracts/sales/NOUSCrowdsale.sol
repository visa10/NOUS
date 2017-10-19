pragma solidity ^0.4.4;

import "./SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";


contract NOUSCrowdsale is SalesAgent {

	using SafeMath for uint;

	struct BonusRateStruct {
		uint256 period; // in week rate
		uint256 rate;
	}

	BonusRateStruct[] bonusRates; // index rates

	/// @dev constructor
	function NOUSCrowdsale(address _saleContractAddress){
		nousTokenSale = NOUSSale(_saleContractAddress);
		addBonusRate(1, 7300); // 1 Week = 7300 NOUS
		addBonusRate(2, 7000); // 2 Week 1 ETH = 7000 NOUS
		addBonusRate(3, 6700); // 3 Week 1 ETH = 6700 NOUS
	}

	function() payable external {
		// The target ether amount
		require(nousTokenSale.validateStateSaleContract(this));
		require(nousTokenSale.validateContribution(msg.value));
		require(msg.sender != 0x0);

		uint256 weiAmount = msg.value;

		uint256 rate = getBonusRate();

		assert(rate != 0);

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

	/*function globalFinalizationStartBonusPayable() onlyOwner {
		nousTokenSale.finalizeICO(this);
	}*/

	/// @dev addBonusRate adding bonuses foe weeks period
	/// @param _period array periods for bonus
	/// @param _rate array periods for bonus
	function addBonusRate(uint256 _period, uint256 _rate) internal {
		require(_period > 0 && _rate > 0);

		bonusRates.push(BonusRateStruct({
			period: _period,
			rate: _rate
		}));
	}

	/// @dev get period rates
	function getBonusRate() internal returns(uint256) {
		for (uint256 i = 0; i < bonusRates.length; i++){
			uint256 toPeriod = nousTokenSale.getSaleContractStartTime(this);
			for (uint256 w = 0; w < bonusRates[i].period; w++) {
				toPeriod = toPeriod + (5 minutes); // TODO FOR TESTING (1 weeks)
			}
			if (now < toPeriod){
				return bonusRates[i].rate;
			}
		}

		return nousTokenSale.getSaleContractTokensRate(this); // return default rate if not config
	}

	function finaliseFunding() onlyOwner {
		super.finaliseFunding();
	}
}
