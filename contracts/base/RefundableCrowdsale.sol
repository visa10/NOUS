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
		require(targetEthMin > 0);

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
	function forwardFunds() internal {
		vault.deposit.value(msg.value)(msg.sender);
	}

	// if crowdsale is unsuccessful, investors can claim refunds here
	function claimRefund() public {
		require(isFinalized); // if finalized global
		require(!goalReached());

		vault.refund(msg.sender);
	}

	// vault global finalization task, called when owner calls finalize()
	function globalFinalization() internal {
		if (goalReached()) {
			vault.close();
		} else {
	  		vault.enableRefunds();
		}

		super.globalFinalization();
	}

	function goalReached() public constant returns (bool) {
		return weiRaised >= targetEthMin;
	}

}
