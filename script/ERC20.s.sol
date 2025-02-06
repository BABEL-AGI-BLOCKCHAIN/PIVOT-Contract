pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import "../src/TopicERC20.sol";

contract ERC20Script is Script {
    function run() external returns(TopicERC20){
        vm.startBroadcast();
        TopicERC20 erc20 = new TopicERC20("PIVOT","PIVOT",1000000000000000000000000);
        vm.stopBroadcast();
        return erc20;
    }
}