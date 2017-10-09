pragma solidity ^0.4.4;

import './BaseContract.sol';

contract BaseFunctions is BaseContract {



	/// @dev addBonusRate adding bonuses foe weeks period
	/// @param _salesAgentAddress the address of the token sale agent contract
	/// @param _period array periods for bonus
	/// @param _rate array periods for bonus
	function addBonusRate(address _salesAgentAddress, uint256[] _period, uint256[] _rate) external onlyOwner isSalesContract(_salesAgentAddress) {
		if (_salesAgentAddress != 0x0 && _period.length > 0 && _rate.length > 0 && _period.length == _rate.length ){
			salesAgents[_salesAgentAddress].bonusRatesIndex = new uint256[](_rate.length);

			for (uint256 i = 0; i < _period.length; i++) {
				salesAgents[_salesAgentAddress].bonusRatesIndex.push(_period[i]);
				salesAgents[_salesAgentAddress].bonusRates[_period[i]] = BonusRateStruct({
					period: _period[i],
					rate: _rate[i]
				});
			}
		}
	}

	/// @dev get period rates
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getBonusRate(address _salesAgentAddress) internal isSalesContract(_salesAgentAddress) returns  (uint256){

		for (uint256 i = 0; i < salesAgents[_salesAgentAddress].bonusRatesIndex.length; i++ ) {
			uint256 curMaxPeriod = salesAgents[_salesAgentAddress].startTime;
			for (uint256 w = 0; w < salesAgents[_salesAgentAddress].bonusRates[salesAgents[_salesAgentAddress].bonusRatesIndex[i]].period; w++){
				curMaxPeriod = curMaxPeriod + (1 weeks);
			}
			if (now < curMaxPeriod){
				return salesAgents[_salesAgentAddress].bonusRates[salesAgents[_salesAgentAddress].bonusRatesIndex[i]].rate;
			}
		}
		return salesAgents[msg.sender].rate; // return default rate if not config
	}

	/// @dev get all rates bonuses
	/// @param _salesAgentAddress The address of the token sale agent contract
	function getRates(address _salesAgentAddress) constant public returns (uint256[], uint256[]){
		uint256[] bonusRatesIndex = salesAgents[_salesAgentAddress].bonusRatesIndex;
		uint256[] memory periods = new uint256[](bonusRatesIndex.length);
		uint256[] memory rates = new uint256[](bonusRatesIndex.length);
		for (uint256 i = 0; i < bonusRatesIndex.length; i++ ) {
			periods[i] = salesAgents[_salesAgentAddress].bonusRates[bonusRatesIndex[i]].period;
			rates[i] = salesAgents[_salesAgentAddress].bonusRates[bonusRatesIndex[i]].rate;
		}
		return (periods, rates);
	}





}
