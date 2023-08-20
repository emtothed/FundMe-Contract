// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testDemo() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwner() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceConverter() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFails() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdates() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddresstoAmoundFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 startingBalanceOfFundMe = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        uint256 finalBalanceOfOwner = fundMe.getOwner().balance;
        uint256 finalBalanceOfFundMe = address(fundMe).balance;

        assertEq(finalBalanceOfFundMe, 0);
        assertEq(
            finalBalanceOfOwner,
            startingBalanceOfFundMe + startingBalanceOfOwner
        );
    }

    function testWithdrawFromTenFunders() public funded {
        for (uint160 i = 1; i < 10; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 startingBalanceOfFundMe = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 finalBalanceOfOwner = fundMe.getOwner().balance;
        uint256 finalBalanceOfFundMe = address(fundMe).balance;

        assertEq(finalBalanceOfFundMe, 0);
        assertEq(
            finalBalanceOfOwner,
            startingBalanceOfFundMe + startingBalanceOfOwner
        );
    }
}
