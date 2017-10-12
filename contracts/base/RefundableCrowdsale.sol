pragma solidity ^0.4.11;

import './RefundVault.sol';
import './Crowdsale.sol';


/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract RefundableCrowdsale is Crowdsale {

	// refund vault used to hold funds while crowdsale is running
	RefundVault public vault;

	function RefundableCrowdsale() {
		//require(_targetEthMin > 0);

		if (address(vault) == 0x0) {
			vault = createRefundVault();
		}
	}


	function createRefundVault() internal returns (RefundVault){
		return new RefundVault(wallet);
	}

	// We're overriding the fund forwarding from Crowdsale.
	// In addition to sending the funds, we want to call
	// the RefundVault deposit function
	function forwardFunds(address _sender) internal {
		vault.deposit.value(msg.value)(_sender);
	}

	// if crowdsale is unsuccessful, investors can claim refunds here
	function claimRefund(address beneficiary) isSalesContract(msg.sender) public returns (uint256) {
		require(saleState == SaleState.Ended); // refund started only closed contract
		require(!goalReached());

		//token. TODO get token
		return vault.refund(beneficiary);
	}

	// vault global finalization task, called when owner calls finalize()
	function globalFinalization() internal {
		require(!isGlobalFinalized);
		if (goalReached()) {
			vault.close();
		} else {
	  		vault.enableRefunds();
		}

		super.globalFinalization();
	}

	// todo max test
	function goalReached() public constant returns (bool) {
		return weiRaised < targetEthMin;
	}

}
