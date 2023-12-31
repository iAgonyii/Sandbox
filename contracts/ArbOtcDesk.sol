// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenDistributor {
    function claimableTokens(address wallet) external view returns (uint256);
}


contract ArbOtc is Ownable, ReentrancyGuard {

    event TradeOfferCreated(uint256 tradeId, address creator, uint256 costPerToken, uint256 tokens);
    event TradeOfferCancelled(uint256 tradeId);
    event TradeOfferAccepted(uint256 tradeId);
    event AgreementFulfilled(uint256 agreementId);

    address public USDC_ADDRESS = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public ARB_ADDRESS = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    address public FEE_1 = 0xFf73A0d213effF9864B2Cda7bDBc05821BF1eE1B;
    address public FEE_2 = 0xD999b4C785804CF8e2B34F64EB0b3CB5e1a6Eef3;

    //Max and min costs to prevent over/under paying mistakes.
    uint256 public MAX_COST = 100000000; //Max of 100 USDC
    uint256 public MIN_COST = 100000; //Min of 0.1 USDC

    bool public OFFERS_EXPIRED = false;
    bool public EMERGENCY_WITHDRAWAL = false;

    mapping(address => uint256) public USDCDeposited;

    TradeOffer[] public tradeOffers;
    Agreement[] public agreements;

    struct TradeOffer {
        address creator;
        uint256 tokens;
        uint256 costPerToken;
        uint256 tradeId;
        bool active;
    }

    struct Agreement {
        address seller;
        address buyer;
        uint256 tokens;
        uint256 costPerToken;
        uint256 tradeId;
        bool active;
    }

    /// @notice Allows a seller to create a trade offer
    /// @dev Requires the seller to lock 25% of the total cost as collateral
    /// @param _costPerToken The cost per token in USDC
    /// @param _tokens The number of tokens offered in the trade in an 18 decimal format.
    function createOffer(uint256 _costPerToken, uint256 _tokens) public nonReentrant {
        require(_tokens >= 1 ether, "Must be 18 decimal value");

        _tokens = _tokens / 1 ether;

        require(_costPerToken >= MIN_COST, "Below min cost");
        require(_costPerToken <= MAX_COST, "Above max cost");
        require(_tokens > 0, "Non zero value");
        require(!OFFERS_EXPIRED, "Offers not allowed");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWAL, "Emergency withdrawl enabled");


        uint256 collateral = ((_costPerToken * _tokens) * 25 / 100);

        USDCDeposited[msg.sender] += collateral;

        IERC20(USDC_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            collateral
        );


        TradeOffer memory newOffer = TradeOffer({
            creator: msg.sender,
            tokens: _tokens,
            costPerToken: _costPerToken,
            tradeId: tradeOffers.length,
            active: true
        });

        tradeOffers.push(newOffer);
    }

    /// @notice Allows the creator of a trade offer to cancel it
    /// @dev Returns the collateral locked by the creator and marks the offer as inactive
    /// @param tradeId The ID of the trade offer to cancel
    function cancelOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        require(offer.creator == msg.sender, "Not your offer");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWAL, "Emergency withdrawl enabled");

        uint256 collateral = ((offer.costPerToken * offer.tokens) * 25 / 100);

        offer.active = false;

        USDCDeposited[msg.sender] -= collateral;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral
        );

        emit TradeOfferCancelled(tradeId);
    }

    /// @notice Allows a user to accept an existing trade offer
    /// @dev The buyer pays the full cost of the tokens and the offer is marked as inactive
    /// @param tradeId The ID of the trade offer to accept
    function acceptOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        require(msg.sender != offer.creator, "Can't accept own offer");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWAL, "Emergency withdrawl enabled");
        require(!OFFERS_EXPIRED, "Offers have expired");

        uint256 cost = offer.costPerToken * offer.tokens;

        USDCDeposited[msg.sender] += cost;

        IERC20(USDC_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            cost
        );

        offer.active = false;

        Agreement memory newAgreement = Agreement({
            seller: offer.creator,
            buyer: msg.sender,
            tokens: offer.tokens,
            costPerToken: offer.costPerToken,
            tradeId: agreements.length,
            active: true
        });

        agreements.push(newAgreement);

        emit TradeOfferAccepted(tradeId);
    }

    /// @notice Allows the seller of an agreement to fulfill it
    /// @dev The seller receives the payment minus a 5% fee, and the collateral is returned
    /// @param agreementId The ID of the agreement to fulfill
    function fulfilOffer(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.active, "Not active");
        require(msg.sender == agreement.seller, "Not seller");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWAL, "Emergency withdrawl enabled");

        agreement.active = false;

        uint256 arbToSend = agreement.tokens * 1 ether;

        uint256 arbFee = arbToSend * 5 / 100;

        IERC20(ARB_ADDRESS).transferFrom(
            msg.sender,
            agreement.buyer,
            arbToSend - arbFee
        );

        IERC20(ARB_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            arbFee
        );

        IERC20(ARB_ADDRESS).transfer(
            FEE_1,
            arbFee / 2
        );

        IERC20(ARB_ADDRESS).transfer(
            FEE_2,
            arbFee / 2
        );

        uint256 cost = agreement.costPerToken * agreement.tokens;
        uint256 fee = cost * 5 / 100;

        USDCDeposited[agreement.buyer] -= cost;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            cost - fee
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_1,
            fee / 2
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_2,
            fee / 2
        );

        //Return collateral.
        uint256 collateral = ((agreement.costPerToken * agreement.tokens) * 25 / 100);


        USDCDeposited[msg.sender] -= collateral;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral
        );

        emit AgreementFulfilled(agreementId);
    }

    /// @notice Allows the buyer of an agreement to claim the collateral if the agreement has not been fulfilled after the expiration time
    /// @dev The buyer receives the collateral minus a 5% fee
    /// @param agreementId The ID of the agreement to claim the collateral for
    function claimCollateral(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.buyer, "Not buyer");
        require(OFFERS_EXPIRED, "Agreement not expired yet");
        require(agreement.active, "Agreement not active");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWAL, "Emergency withdrawl enabled");

        uint256 cost = agreement.costPerToken * agreement.tokens;

        uint256 collateral = cost * 25 / 100;
        uint256 fee = collateral * 20 / 100;

        agreement.active = false;

        USDCDeposited[agreement.seller] -= collateral;
        USDCDeposited[msg.sender] -= cost;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            (cost + collateral) - fee
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_1,
            fee / 2
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_2,
            fee / 2
        );
    }

    /// @notice Allows users to withdraw their deposited USDC in case of an emergency.
    /// @dev Resets the USDC deposited amount for the user after the withdrawal.
    function emergencyWithdraw() public nonReentrant {
        require(tx.origin == msg.sender, "EOA only");
        require(EMERGENCY_WITHDRAWAL, "Emergency not active");
        require(USDCDeposited[msg.sender] > 0, "No funds available to withdraw");

        uint256 amountDeposited = USDCDeposited[msg.sender];

        USDCDeposited[msg.sender] = 0;

        require(IERC20(USDC_ADDRESS).transfer(msg.sender, amountDeposited));
    }

    /// @notice Returns an array of trade offers within the specified range
    /// @dev Pagination is used to fetch trade offers in smaller chunks
    /// @param startIndex The start index of the trade offers to fetch
    /// @param endIndex The end index of the trade offers to fetch
    /// @return offers An array of TradeOffer structs within the specified range
    function getOffers(uint256 startIndex, uint256 endIndex) public view returns (TradeOffer[] memory) {
        require(startIndex < endIndex, "Invalid range");

        if (endIndex > tradeOffers.length) endIndex = tradeOffers.length;

        uint256 length = endIndex - startIndex;
        TradeOffer[] memory offers = new TradeOffer[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            offers[i - startIndex] = tradeOffers[i];
        }

        return offers;
    }

    /// @notice Returns an array of agreements within the specified range
    /// @dev Pagination is used to fetch agreements in smaller chunks
    /// @param startIndex The start index of the agreements to fetch
    /// @param endIndex The end index of the agreements to fetch
    /// @return agmts An array of Agreement structs within the specified range
    function getAgreements(uint256 startIndex, uint256 endIndex) public view returns (Agreement[] memory) {
        require(startIndex < endIndex, "Invalid range");

        if (endIndex > agreements.length) endIndex = agreements.length;

        uint256 length = endIndex - startIndex;
        Agreement[] memory agmts = new Agreement[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            agmts[i - startIndex] = agreements[i];
        }

        return agmts;
    }

    /// @notice Allows the contract owner to set the addresses for USDC, ARB, and AIRDROP tokens
    /// @dev This function is restricted to the contract owner
    /// @param _USDC The address of the USDC token
    /// @param _ARB The address of the ARB token
    function setAddresses(address _USDC, address _ARB) public onlyOwner {
        USDC_ADDRESS = _USDC;
        ARB_ADDRESS = _ARB;
    }

    /// @notice Allows the contract owner to set the maximum and minimum acceptable costs per token
    /// @dev This function is restricted to the contract owner
    /// @param _min The minimum acceptable cost per token in USDC
    /// @param _max The maximum acceptable cost per token in USDC
    function setMaxAndMin(uint256 _min, uint256 _max) public onlyOwner {
        MIN_COST = _min;
        MAX_COST = _max;
    }

    /// @notice Expires all offers 3 days after the airdrop opens.
    /// @dev Can only be called by the contract owner.
    /// Incentive to let offers expire is a 5% fee on any buyers gained
    function expireOffers() public onlyOwner {
        OFFERS_EXPIRED = true;
    }

    /// @notice Enables emergency withdrawals for users.
    /// @dev Can only be called by the contract owner.
    function triggerEmergencyWithdrawals() public onlyOwner {
        EMERGENCY_WITHDRAWAL = true;
    }
}
