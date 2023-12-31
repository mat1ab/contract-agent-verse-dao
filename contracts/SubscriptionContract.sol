pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionContract is Ownable {
    enum SubscriptionTier { Free, Weekly, Monthly, Yearly }

    mapping(SubscriptionTier => uint256) public subscriptionPrices;

    mapping(address => Subscription) public subscriptions;
    mapping(address => bool) public hasUsedFreeSubscription;

    struct Subscription {
        SubscriptionTier tier;
        uint256 expiry;
    }

    event SubscriptionPurchased(address indexed user, SubscriptionTier tier, uint256 expiry);
    event CheckedSubscription(address indexed user, bool isActive);
    event GotSubscriptionTier(address indexed user, SubscriptionTier tier);
    event GotSubscriptionExpiry(address indexed user, uint256 expiry);

    constructor() {
        subscriptionPrices[SubscriptionTier.Free] = 0 ether;
        subscriptionPrices[SubscriptionTier.Weekly] = 0.01 ether;
        subscriptionPrices[SubscriptionTier.Monthly] = 0.03 ether;
        subscriptionPrices[SubscriptionTier.Yearly] = 0.05 ether;
    }

    function purchaseSubscription(SubscriptionTier tier) public payable {

        uint256 duration;
        if (tier == SubscriptionTier.Free) {
            require(!hasUsedFreeSubscription[msg.sender], "You have already used a free subscription.");
            hasUsedFreeSubscription[msg.sender] = true;
            duration = 7 days;
        } else {
            require(msg.value >= subscriptionPrices[tier], "Insufficient payment amount");

            if (tier == SubscriptionTier.Weekly) {
                duration = 7 days;
            } else if (tier == SubscriptionTier.Monthly) {
                duration = 30 days;
            } else if (tier == SubscriptionTier.Yearly) {
                duration = 365 days;
            }

            uint256 refund = msg.value - subscriptionPrices[tier];
            if(refund > 0) {
                payable(msg.sender).transfer(refund);
            }
        }

        Subscription storage subscription = subscriptions[msg.sender];
        subscription.tier = tier;
        if (block.timestamp > subscription.expiry) {
            subscription.expiry = block.timestamp + duration;
        } else {
            subscription.expiry += duration;
        }

        emit SubscriptionPurchased(msg.sender, tier, subscription.expiry);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function checkSubscription(address user) public returns (bool isActive) {
        isActive = (block.timestamp <= subscriptions[user].expiry);
        emit CheckedSubscription(user, isActive);
    }

    function getSubscriptionTier(address user) public returns (SubscriptionTier) {
        SubscriptionTier tier = subscriptions[user].tier;
        emit GotSubscriptionTier(user, tier);
        return tier;
    }

    function getSubscriptionExpiry(address user) public returns (uint256) {
        uint256 expiry = subscriptions[user].expiry;
        emit GotSubscriptionExpiry(user, expiry);
        return expiry;
    }
}
