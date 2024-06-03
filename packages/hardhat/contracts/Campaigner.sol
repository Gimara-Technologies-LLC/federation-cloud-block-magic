// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Campaigner
/// @author Greatly Inspired By Chainlink Docs And Village committees
/// @notice Trying out my own take on putting data on chain and interacting with it
/// from both the decentralized and the web2
/// @dev Explain to a developer any extra details

contract Campaigner is FunctionsClient, ConfirmedOwner, ERC20 {
	using FunctionsRequest for FunctionsRequest.Request;

	struct User {
		address userAddress;
		string name;
		uint256 balance;
	}

	struct Campaign {
		uint256 id;
		string name;
		string description;
		uint256 reward;
		address owner;
		bool active;
		uint256 performance; // New field for performance data
	}

	bytes32 public s_lastRequestId;
	bytes public s_lastResponse;
	bytes public s_lastError;

	uint256 public campaignCount;
	mapping(address => User) public users;
	mapping(uint256 => Campaign) public campaigns;

	event UserRegistered(address indexed userAddress, string name);
	event CampaignCreated(
		uint256 indexed campaignId,
		string name,
		string description,
		uint256 reward,
		address owner
	);
	event CampaignPerformanceUpdated(
		uint256 indexed campaignId,
		uint256 performance
	);
	event Response(bytes32 indexed requestId, bytes response, bytes err);

	error UnexpectedRequestID(bytes32 requestId);

	constructor(
		address router,
		string memory token_name,
		string memory token_symbol
	)
		FunctionsClient(router)
		ConfirmedOwner(msg.sender)
		ERC20(token_name, token_symbol)
	{
		_mint(msg.sender, 1000000 * 10 ** 18); // Initial supply of 1,000,000 tokens
	}

	function registerUser(string memory _name) public {
		require(bytes(_name).length > 0, "Name is required");
		users[msg.sender] = User(msg.sender, _name, 0);
		emit UserRegistered(msg.sender, _name);
	}

	function createCampaign(
		string memory _name,
		string memory _description,
		uint256 _reward
	) public {
		require(bytes(_name).length > 0, "Campaign name is required");
		require(
			bytes(_description).length > 0,
			"Campaign description is required"
		);
		require(_reward > 0, "Reward must be greater than zero");

		campaigns[campaignCount] = Campaign(
			campaignCount,
			_name,
			_description,
			_reward,
			msg.sender,
			true,
			0
		);
		campaignCount++;

		emit CampaignCreated(
			campaignCount,
			_name,
			_description,
			_reward,
			msg.sender
		);
	}

	/// @notice Function from the chainlink example. Used to interact with javascript code
	/// @dev
	/// @param source a parameter just like in doxygen (must be followed by parameter name)
	/// @return requestId the return variables of a contract’s function state variable
	function sendRequest(
		string memory source,
		bytes memory encryptedSecretsUrls,
		uint8 donHostedSecretsSlotID,
		uint64 donHostedSecretsVersion,
		string[] memory args,
		bytes[] memory bytesArgs,
		uint64 subscriptionId,
		uint32 gasLimit,
		bytes32 donID
	) external onlyOwner returns (bytes32 requestId) {
		FunctionsRequest.Request memory req;
		req.initializeRequestForInlineJavaScript(source);
		if (encryptedSecretsUrls.length > 0)
			req.addSecretsReference(encryptedSecretsUrls);
		else if (donHostedSecretsVersion > 0) {
			req.addDONHostedSecrets(
				donHostedSecretsSlotID,
				donHostedSecretsVersion
			);
		}
		if (args.length > 0) req.setArgs(args);
		if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);

		s_lastRequestId = _sendRequest(
			req.encodeCBOR(),
			subscriptionId,
			gasLimit,
			donID
		);
		return s_lastRequestId;
	}

	function sendRequestCBOR(
		bytes memory request,
		uint64 subscriptionId,
		uint32 gasLimit,
		bytes32 donID
	) external onlyOwner returns (bytes32 requestId) {
		s_lastRequestId = _sendRequest(
			request,
			subscriptionId,
			gasLimit,
			donID
		);
		return s_lastRequestId;
	}

	function fulfillRequest(
		bytes32 requestId,
		bytes memory response,
		bytes memory err
	) internal override {
		if (s_lastRequestId != requestId) {
			revert UnexpectedRequestID(requestId);
		}
		s_lastResponse = response;
		s_lastError = err;
		emit Response(requestId, s_lastResponse, s_lastError);
	}

	function updateCampaignPerformance(
		uint256 _campaignId,
		uint256 _performance
	) public {
		require(
			campaigns[_campaignId].owner == msg.sender,
			"Only the campaign owner can update performance"
		);
		campaigns[_campaignId].performance = _performance;
		emit CampaignPerformanceUpdated(_campaignId, _performance);
	}

	function rewardUser(address _user, uint256 _amount) public {
		_transfer(msg.sender, _user, _amount);
		users[_user].balance += _amount;
	}

	function getCampaign(
		uint256 _campaignId
	) public view returns (Campaign memory) {
		return campaigns[_campaignId];
	}
}
