pragma solidity ^0.8.20;
import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/TopicSBT.sol";
import "../src/PivotTopic.sol";
import "../src/TopicERC20.sol";

contract PivotTopicTest is Test {
    TopicSBT private sbt;
    PivotTopic private pivotTopic;
    TopicERC20 private erc20;

    uint256 private ownerPrivateKey;
    uint256 private investorPrivateKey;
    uint256 private bigAmountInvestorPrivateKey;

    address private owner;
    address private investor;
    address private bigAmountInvestor;

    function setUp() public {

        ownerPrivateKey = 0xA11CE;
        investorPrivateKey = 0xB0B;
        bigAmountInvestorPrivateKey = 0xC99;

        owner = vm.addr(ownerPrivateKey);
        investor = vm.addr(investorPrivateKey);
        bigAmountInvestor = vm.addr(bigAmountInvestorPrivateKey);

        sbt = new TopicSBT(owner, "sbt", "SBT");

        erc20 = new TopicERC20("erc20", "ERC20", 100000000);
    
        pivotTopic = new PivotTopic(address(sbt));
        erc20.transfer(owner, 10000000);
        erc20.transfer(investor, 10000000);
        erc20.transfer(msg.sender, 10000000);
        erc20.transfer(bigAmountInvestor, 30000000);
        vm.prank(owner);
        sbt.transferOwnership(address(pivotTopic));
    }

    function test_mintSBT() public {

        uint256 topicId = 1;
        uint256 position = 1;
        uint256 investment = 100;

        vm.prank(address(pivotTopic));
        sbt.mint(owner,topicId,position,investment);

        assertEq(sbt.ownerOf(1), owner);
        assertEq(sbt.balanceOf(owner), 1);
        assertEq(sbt.topicId(1), topicId);
        assertEq(sbt.position(topicId), position);
        assertEq(sbt.investmentAmount(topicId), investment);
    }

    function test_ERC20Balance() public {
        assertEq(erc20.balanceOf(msg.sender), 10000000);
        assertEq(erc20.balanceOf(owner), 10000000);
        assertEq(erc20.balanceOf(investor), 10000000);
        assertEq(erc20.balanceOf(address(this)), 100000000 - 60000000);
    }


    function test_createTopic() public {

        address msgSender = msg.sender;
        vm.prank(msgSender);
        erc20.approve(address(pivotTopic),5000000);
        
        string memory hashString = "hello";
        bytes32 testHash = keccak256(abi.encodePacked(hashString));
        vm.prank(msgSender);
        pivotTopic.createTopic(5000000, address(erc20), testHash);
        assertEq(erc20.balanceOf(address(pivotTopic)), 5000000);
        assertEq(pivotTopic.getInvestment(msgSender,1), 5000000);
        assertEq(pivotTopic.getFixedInvestment(1), 5000000);
        assertEq(pivotTopic.getPromoter(1), msgSender);
        assertEq(pivotTopic._totalBalance(1), 5000000);
        assertEq(pivotTopic.topicCoin(1), address(erc20));
        assertEq(pivotTopic.topicCoin(1), address(erc20));
    }

    function test_invest() public {
        address msgSender = msg.sender;
        vm.prank(msgSender);
        erc20.approve(address(pivotTopic),5000000);
        string memory hashString = "hello";
        bytes32 testHash = keccak256(abi.encodePacked(hashString));
        vm.prank(msgSender);
        pivotTopic.createTopic(5000000, address(erc20), testHash);

        vm.prank(owner);
        erc20.approve(address(pivotTopic), 5000000);
        vm.prank(owner);
        pivotTopic.invest(1, 5000000);

        assertEq(pivotTopic.getInvestment(owner,1), 5000000);
        assertEq(erc20.balanceOf(owner), 5000000);
        assertEq(pivotTopic._totalBalance(1), 10000000);

        vm.prank(investor);
        erc20.approve(address(pivotTopic), 5000000);
        vm.prank(investor);
        pivotTopic.invest(1, 5000000);
        assertEq(pivotTopic.getInvestment(investor,1), 5000000);

        vm.startPrank(bigAmountInvestor);
        erc20.approve(address(pivotTopic), 20000000);
        // vm.expectRevert();
        // pivotTopic.invest(1, 1000000);
        // vm.expectRevert();
        // pivotTopic.invest(1, 7999999);

        pivotTopic.invest(1, 20000000);
        vm.stopPrank;
    }

    function test_withdraw() public {
        address msgSender = msg.sender;
        vm.prank(msgSender);
        erc20.approve(address(pivotTopic),5000000);
        string memory hashString = "hello";
        bytes32 testHash = keccak256(abi.encodePacked(hashString));
        vm.prank(msgSender);
        pivotTopic.createTopic(5000000, address(erc20), testHash);

        vm.startPrank(owner);
        erc20.approve(address(pivotTopic), 5000000);
        pivotTopic.invest(1, 5000000);
        pivotTopic.withdraw(1,2);
        vm.stopPrank();
        assertEq(pivotTopic._totalBalance(1), 7500000);
        assertEq(erc20.balanceOf(owner), 7500000);
        assertEq(erc20.balanceOf(address(pivotTopic)), 7500000);
    }

    function test_withdrawCommission() public {
        address msgSender = msg.sender;
        vm.startPrank(msgSender);
        erc20.approve(address(pivotTopic),5000000);
        string memory hashString = "hello";
        bytes32 testHash = keccak256(abi.encodePacked(hashString));
        pivotTopic.createTopic(5000000, address(erc20), testHash);
        pivotTopic.withdraw(1,1);
        vm.stopPrank();
        vm.startPrank(owner);
        erc20.approve(address(pivotTopic), 5000000);
        pivotTopic.invest(1, 5000000);
        vm.stopPrank();
        vm.prank(msgSender);
        pivotTopic.withdraw(1,1);
        assertEq(erc20.balanceOf(msgSender), 12492500);
        assertEq(pivotTopic._totalCommission(1), 7500);
        pivotTopic.withdrawCommission(1500, 1);
        assertEq(pivotTopic._totalCommission(1), 6000);
        assertEq(erc20.balanceOf(address(this)), 40001500);
    }
}