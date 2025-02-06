pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import "../src/PivotTopic.sol";
import "../src/TopicSBT.sol";

contract TopicScript is Script {
    function run() external returns(TopicSBT,PivotTopic){
        vm.startBroadcast();
        TopicSBT sbt = new TopicSBT(0xe1BB7c9dF15E2fd02a3dE40Db44961F84563CFf2, "TopicSBT","TopicSBT");
        PivotTopic topic = new PivotTopic(address(sbt));
        sbt.transferOwnership(address(topic));
        vm.stopBroadcast();
        return (sbt,topic);
    }
}