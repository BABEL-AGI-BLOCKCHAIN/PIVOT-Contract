// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";

contract PivotTopic {
    address public owner;
    address public sbtAddress;
    ISBTContract private sbtContract;
    uint256 private _topicId;
    uint16  private _commissionrate = 3;
    uint256 public _totalBalance;

    mapping (uint256 topicId => address) private _promoter;
    mapping (address owner => uint256) private _income;
    mapping (address owner => uint256) private _investment;
    mapping (uint256 topicId => uint256) private _fixedInvestment;
    mapping (uint256 topicId => uint256) private _position;
    mapping (uint256 topicId => mapping(uint256 position => address)) private _investAddressMap;

    event CreateTopic(address indexed promoter, uint256 topicId);
    event Invest(address indexed investor, uint256 indexed topicId, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor(address a) {
        owner = msg.sender;
        sbtAddress = a;
        sbtContract = ISBTContract(a);
        _topicId = 1;
    }

    function getIncome(address owner) public view returns(uint256) {
        return _income[owner];
    }

    function getInvestment(address owner) public view returns(uint256) {
        return _investment[owner];
    }

    function getFixedInvestment(uint256 topicId) public view returns(uint256) {
        return _fixedInvestment[topicId];
    }

    function getPromoter(uint256 topicId) public view returns(address) {
        return _promoter[topicId];
    }

    function createTopic(uint256 amount) public {

        address promoter = msg.sender;

        _promoter[_topicId] = msg.sender;

        require(amount > 0,"Insufficient Amount");

        _fixedInvestment[_topicId] = amount;

        uint256 position = 1;

        _investAddressMap[_topicId][position] = promoter;

        position ++;

        _position[_topicId] = position;

        _topicId ++;

        emit CreateTopic(promoter, _topicId);

    }

    function invest(uint256 topicId) public payable{

        uint256 fixedInvestment = _fixedInvestment[topicId];
        require(fixedInvestment == msg.value, "Insufficient Balance");

        _totalBalance += msg.value;

        uint256 position = _position[topicId] + 1;

        sbtContract.mint(msg.sender, topicId, position);

        for (uint256 i = 0; i < position; i++) {
            address investAddress = _investAddressMap[topicId][i + 1];
            (bool success, uint256 income) = Math.tryDiv(fixedInvestment, position);
            require(success,"Calculate Fault");
            _income[investAddress] = _income[investAddress] + income;
        }
        _position[topicId] = position;
        emit Invest(msg.sender, topicId, fixedInvestment);
    }

    function withdraw() public {

        address to = msg.sender;
        uint256 income = _income[to];
        require(income >= 0,"Insufficient Balance");
        uint256 investment = _investment[to];

        if(investment < income) {
            (bool success,uint256 diff) = Math.trySub(income, investment);
            require(success,"Calculate Fault");
            uint256 commission = diff / 100 * _commissionrate;
            (success,income) = Math.trySub(income, commission);
            require(success,"Calculate Fault");
        }

        _transferTo(to, income);
        _income[to] = 0;

        emit Withdraw(msg.sender, income);
    }

    function _transferTo(address to, uint256 amount) internal {
        payable(to).transfer(amount);
    }


}

interface ISBTContract {
    function mint(address to, uint256 topicId, uint256 position) external;
}
