// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/fundme.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    //uint256 constant GAS = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumUSDisFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIsOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesAmountFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundersToArrayOfFunders() public funded {
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function testAddAmountToAddressToAmountFunded() public funded {
        uint256 amount = fundMe.getAddressToAmountFunded(USER);
        assertEq(SEND_VALUE, amount);
    }

    function testWithdrawOnlyOwner() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleAddress() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingOwnerBalance
        );
    }

    function testWithdrawWithMultipleAddress() public funded {
        //arrange
        uint160 endingAddress = 10;
        uint160 startingAddress = 1;
        for (uint160 i = startingAddress; i < endingAddress; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE};
            vm.stopPrank();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawWithMultipleAddressCheaper() public funded {
        //arrange
        uint160 endingAddress = 10;
        uint160 startingAddress = 1;
        for (uint160 i = startingAddress; i < endingAddress; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE};
            vm.stopPrank();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }
}

/*
    function testWithdrawWithMultipleAddress() public funded {
        //arrange
        uint160 endingAddress = 10;
        uint160 startingAddress = 1;
        for (uint160 i = startingAddress; i < endingAddress; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE};
            vm.stopPrank();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }

*/
