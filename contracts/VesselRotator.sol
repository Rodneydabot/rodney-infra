// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VesselRotator
/// @notice 96-minute auction cycle for 15 rotator seats
/// @dev NFT-owned bots launch tokens; seat holders earn trading fee shares
contract VesselRotator {
    
    // ============ Structs ============
    
    struct Seat {
        address holder;        // Current seat holder (address(0) if empty)
        uint256 bidAmount;     // Amount they bid to win
        uint256 winningTime;   // When they won the seat
        uint256 expiresAt;     // When seat expires (24hr from winning)
        uint256 accruedFees;   // Fees owed to this seat (18 decimals)
    }
    
    struct Auction {
        uint256 id;
        uint256 endsAt;                    // Auction end time
        uint256[15] seatBids;              // Current highest bid per seat
        address[15] seatBidders;           // Current highest bidder per seat
        bool settled;                      // Whether auction was settled
    }
    
    struct BotConfig {
        address nftOwner;                  // Who controls this bot
        uint256 feeSplitToSeats;           // % of trading fees to seats (0-100)
        uint256 minBidIncrement;           // Minimum bid increase (wei)
        bool active;                       // Is this bot accepting new seats?
    }
    
    // ============ State ============
    
    uint256 public constant AUCTION_DURATION = 96 minutes;
    uint256 public constant SEAT_DURATION = 24 hours;
    uint256 public constant SEAT_COUNT = 15;
    
    /// @notice botId => config
    mapping(uint256 => BotConfig) public botConfigs;
    
    /// @notice botId => seat number => Seat state
    mapping(uint256 => mapping(uint256 => Seat)) public seats;
    
    /// @notice botId => current auction
    mapping(uint256 => Auction) public currentAuction;
    
    /// @notice botId => auction counter
    mapping(uint256 => uint256) public auctionCounter;
    
    /// @notice botId => total fees collected for current period
    mapping(uint256 => uint256) public totalFeesCollected;
    
    /// @notice botId => token address => fees from that token
    mapping(uint256 => mapping(address => uint256)) public feesByToken;
    
    /// @notice accrued fees per seat per bot (for pull claims)
    mapping(uint256 => mapping(uint256 => uint256)) public accruedFees;
    
    // ============ Events ============
    
    event AuctionStarted(uint256 indexed botId, uint256 indexed auctionId, uint256 endsAt);
    event BidPlaced(uint256 indexed botId, uint256 indexed auctionId, uint256 seatNumber, address bidder, uint256 amount);
    event AuctionSettled(uint256 indexed botId, uint256 indexed auctionId);
    event SeatWon(uint256 indexed botId, uint256 seatNumber, address winner, uint256 bidAmount, uint256 expiresAt);
    event FeeDeposited(uint256 indexed botId, address token, uint256 amount);
    event FeeClaimed(uint256 indexed botId, uint256 seatNumber, address claimant, uint256 amount);
    event BotRegistered(uint256 indexed botId, address nftOwner, uint256 feeSplit);
    
    // ============ Modifiers ============
    
    modifier onlyNFTOwner(uint256 botId) {
        require(msg.sender == botConfigs[botId].nftOwner, "Not NFT owner");
        _;
    }
    
    modifier validSeat(uint256 seatNumber) {
        require(seatNumber < SEAT_COUNT, "Invalid seat number");
        _;
    }
    
    // ============ Core Functions ============
    
    /// @notice Register a new bot/NFT in the system
    /// @param botId Unique identifier for this bot
    /// @param feeSplitToSeats % of fees to distribute to seats (0-100)
    /// @param minBidIncrement Minimum bid increment in wei
    function registerBot(
        uint256 botId,
        uint256 feeSplitToSeats,
        uint256 minBidIncrement
    ) external {
        require(!botConfigs[botId].active, "Bot already registered");
        require(feeSplitToSeats <= 100, "Fee split must be <= 100");
        
        botConfigs[botId] = BotConfig({
            nftOwner: msg.sender,
            feeSplitToSeats: feeSplitToSeats,
            minBidIncrement: minBidIncrement,
            active: true
        });
        
        emit BotRegistered(botId, msg.sender, feeSplitToSeats);
        
        // Start first auction immediately
        _startAuction(botId);
    }
    
    /// @notice Start a new 96-minute auction for open seats
    function _startAuction(uint256 botId) internal {
        require(botConfigs[botId].active, "Bot not active");
        
        uint256 auctionId = ++auctionCounter[botId];
        
        // Find which seats are available (expired or empty)
        uint256[15] memory openSeats;
        uint256 openCount = 0;
        
        for (uint256 i = 0; i < SEAT_COUNT; i++) {
            Seat storage seat = seats[botId][i];
            if (seat.holder == address(0) || block.timestamp >= seat.expiresAt) {
                openSeats[openCount] = i;
                openCount++;
            }
        }
        
        // Only start if there are open seats
        if (openCount > 0) {
            Auction storage auction = currentAuction[botId];
            auction.id = auctionId;
            auction.endsAt = block.timestamp + AUCTION_DURATION;
            auction.settled = false;
            
            emit AuctionStarted(botId, auctionId, auction.endsAt);
        }
    }
    
    /// @notice Place a bid on a specific seat
    /// @param botId Which bot's rotator
    /// @param seatNumber Which seat (0-14)
    function placeBid(uint256 botId, uint256 seatNumber) external payable validSeat(seatNumber) {
        Auction storage auction = currentAuction[botId];
        
        require(block.timestamp < auction.endsAt, "Auction ended");
        require(msg.value > 0, "Bid must be > 0");
        
        BotConfig storage config = botConfigs[botId];
        
        // Check bid increment
        uint256 currentBid = auction.seatBids[seatNumber];
        require(
            msg.value >= currentBid + config.minBidIncrement || currentBid == 0,
            "Bid increment too low"
        );
        
        // Refund previous bidder
        if (currentBid > 0 && auction.seatBidders[seatNumber] != address(0)) {
            payable(auction.seatBidders[seatNumber]).transfer(currentBid);
        }
        
        // Update bid
        auction.seatBids[seatNumber] = msg.value;
        auction.seatBidders[seatNumber] = msg.sender;
        
        emit BidPlaced(botId, auction.id, seatNumber, msg.sender, msg.value);
    }
    
    /// @notice Settle auction after 96 minutes, assign seats to winners
    function settleAuction(uint256 botId) external {
        Auction storage auction = currentAuction[botId];
        
        require(block.timestamp >= auction.endsAt, "Auction still running");
        require(!auction.settled, "Already settled");
        
        auction.settled = true;
        
        // Assign seats to winners
        for (uint256 i = 0; i < SEAT_COUNT; i++) {
            address winner = auction.seatBidders[i];
            uint256 bid = auction.seatBids[i];
            
            if (winner != address(0) && bid > 0) {
                // Clear previous holder's accrued fees if any (should be claimed)
                seats[botId][i].accruedFees = 0;
                
                // Assign new holder
                seats[botId][i] = Seat({
                    holder: winner,
                    bidAmount: bid,
                    winningTime: block.timestamp,
                    expiresAt: block.timestamp + SEAT_DURATION,
                    accruedFees: 0
                });
                
                emit SeatWon(botId, i, winner, bid, block.timestamp + SEAT_DURATION);