// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./interfaces/IOffChainDataSource.sol";
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

contract ChainlinkDataSource  is IOffChainDataSource, ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    using Strings for uint256;

    bytes32 private jobId;
    uint256 private fee;

    mapping(address=>string) public userData;
    mapping(bytes32=>address) public requests;

    event RequestData(bytes32 indexed requestId, string data);

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        // uint256
        // jobId = "ca98366cc7314957b8c012c72f05aeeb";
        // string
        jobId = "7d80a6386ef543a3abb52817f6707e3b";

        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

    }

    function getData(address user) public view override returns(string memory data) {
        return userData[user];
    }

    function load(address user, string memory url, string memory path) public override {
        bytes32 requestId = requestUserData(url, path);
        requests[requestId] = user;
    }

    function requestUserData(string memory url, string memory path) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add(
            "get",
            url
        );

        req.add("path", path); // Chainlink nodes 1.0.0 and later support this format

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    function fulfill(
        bytes32 _requestId,
        string memory _data
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestData(_requestId, _data);
        userData[requests[_requestId]] = _data;
    }
}
