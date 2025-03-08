// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PivotTopic {
    address public owner;
    address public sbtAddress;
    ISBTContract public sbtContract;
    uint256 private _topicId;
    uint16  private _commissionrate = 3;
    uint256 private _nonce;

    mapping (uint256 topicId => uint256) public _totalCommission;
    mapping (uint256 topicId => uint256) public _totalBalance;
    mapping (uint256 topicId => address) private _promoter;
    mapping (uint256 topicId => bytes32) public _topicHash;
    mapping (uint256 topicId => uint256[]) private _prefixSums; 
    mapping (address investor => mapping(uint256 topicId => uint256)) private _receivedIncome;
    mapping (address investor => mapping(uint256 topicId => uint256)) private _investment;
    mapping (uint256 topicId => uint256) private _fixedInvestment;
    mapping (uint256 topicId => uint256) private _position;
    mapping (uint256 topicId => mapping(uint256 position => address)) private _investAddressMap;

    mapping (uint256 topicId => address) public topicCoin;

    event CreateTopic(address indexed promoter, uint256 topicId, uint256 investment, uint256 position, address tokenAddress, uint256 nonce);
    event Invest(address indexed investor, uint256 indexed topicId, uint256 amount, uint256 position, uint256 nonce);
    event Withdraw(address indexed to, uint256 amount, uint256 nonce);
    event WithdrawCommission(address indexed owner, uint256 amount, uint256 nonce);

    constructor(address a) {
        owner = msg.sender;
        sbtAddress = a;
        sbtContract = ISBTContract(a);
        _topicId = 0;
        _nonce = 0;
    }


    function getInvestment(address investor, uint256 topicId) public view returns(uint256) {
        return _investment[investor][topicId];
    }

    function getFixedInvestment(uint256 topicId) public view returns(uint256) {
        return _fixedInvestment[topicId];
    }

    function getPromoter(uint256 topicId) public view returns(address) {
        return _promoter[topicId];
    }


    function createTopic(uint256 amount, address erc20Address, bytes32 topicHash) public {

        address promoter = msg.sender;
        _topicId ++;

        _promoter[_topicId] = msg.sender;

        require(amount > 0,"Insufficient Amount");

        _fixedInvestment[_topicId] = amount;
        _topicHash[_topicId] = topicHash;

        uint256 position = 1;

        _investAddressMap[_topicId][position] = promoter;

        _position[_topicId] = position;
        topicCoin[_topicId] = erc20Address;
        IERC20 erc20Contract = IERC20(erc20Address);
        erc20Contract.transferFrom(promoter, address(this), amount);
        _investment[promoter][_topicId] = amount;
        _prefixSums[_topicId].push(amount);
        _totalBalance[_topicId] = amount;
        sbtContract.mint(promoter, _topicId, position, amount);


        emit CreateTopic(promoter, _topicId, amount, position, erc20Address, _nonce);
        _nonce++;

    }

    function invest(uint256 topicId, uint256 amount) public {
        address investor = msg.sender;
        uint256 fixedInvestment = _fixedInvestment[topicId];
        require(amount > 0 && amount%fixedInvestment == 0, "Invalid Amount");

        address erc20Address = topicCoin[topicId];
        IERC20 erc20Contract = IERC20(erc20Address);
        erc20Contract.transferFrom(investor, address(this), amount);
        _investment[investor][topicId] = _investment[investor][topicId] + amount;
        _totalBalance[topicId] = _totalBalance[topicId] + amount;

        uint256 position = _position[topicId];
        for (uint256 i = 0; i < amount/fixedInvestment; i++) {
            position++;
            _investAddressMap[topicId][position] = investor;
            (bool success, uint256 delta) = Math.tryDiv(fixedInvestment, position);
            require(success,"Calculate Fault");

            _prefixSums[topicId].push(_prefixSums[topicId][position - 2] + delta);
            sbtContract.mint(investor, topicId, position, amount);
            _position[topicId] = position;
            emit Invest(investor, topicId, amount, position, _nonce);
            _nonce ++;
        }
    }

    //按position领取
    function withdraw(uint256 topicId, uint256 position) public {
        address to = msg.sender;
        require(_investAddressMap[topicId][position] == to, "Invalid TopicId Or Position");
        uint256 currentPosition = _position[topicId];
        uint256 income = 0;
        if (position == 1) {
            income = _prefixSums[topicId][currentPosition - 1];
        } else {
            income = _prefixSums[topicId][currentPosition - 1] - _prefixSums[topicId][position - 2];
        }
        
        uint256 receivedIncome =  _receivedIncome[to][topicId];
        require(income > 0,"Insufficient Income");
        uint256 investment = _investment[to][topicId];

        if(investment > receivedIncome && investment < income) {
            (bool success, uint256 diff) = Math.trySub(income, investment);
            require(success,"Calculate Fault");
            uint256 commission = diff / 1000 * _commissionrate;
            _totalCommission[topicId] = _totalCommission[topicId] + commission;
            income = income - commission - receivedIncome;
        }

        if(investment <= receivedIncome) {
            uint256 commission = (income - receivedIncome) / 1000 * _commissionrate;
            _totalCommission[topicId] = _totalCommission[topicId] + commission;
            income = income - receivedIncome - commission;            
        }

        address erc20Address = topicCoin[topicId];
        IERC20 erc20Contract = IERC20(erc20Address);
        erc20Contract.transfer(to, income);
        _receivedIncome[to][topicId] = _receivedIncome[to][topicId] + income;
        _totalBalance[topicId] = _totalBalance[topicId] - income;
        emit Withdraw(msg.sender, income, _nonce);
        _nonce ++;
    }

    function withdrawCommission(uint256 amount, uint256 topicId) public {
        require(amount < _totalCommission[topicId], "Insufficient Balance");
        require(msg.sender == owner, "Invalid Owner");
        address erc20Address = topicCoin[topicId];
        IERC20 erc20Contract = IERC20(erc20Address);
        erc20Contract.transfer(owner, amount);
        _totalCommission[topicId] = _totalCommission[topicId] - amount;
        emit WithdrawCommission(owner, amount, _nonce);
        _nonce ++;
    }


}

interface ISBTContract {
    function mint(address to, uint256 topicId, uint256 position, uint256 inv) external;
}
