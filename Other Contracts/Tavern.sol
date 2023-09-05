// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

interface AEPNFT is IERC721 {
    enum TIER {
        HUMAN,
        ZOMBIE,
        VAMPIRE
    }

    function tokenTierIndex(uint256 id) external view returns (uint256, TIER);
}

contract Tavern is Ownable, Pausable, ReentrancyGuard {
    struct BoostedNFT {
        uint256 tokenBoostingCoolDown;
        uint256 rewardEarnedInBoost;
        uint256 rewardReleasedInBoost;
        uint256 boostCount;
        uint256 bribeEncash;
        uint256 totalRewardEarned;
        uint256 totalRewardReleased;
    }

    IRewardToken public preyContract;
    AEPNFT public nft;

    uint256 public totalBoostedNFTs;
    uint256 public totalBoosts;
    uint256 public boostStartTime;
    address public teamAddress;
    uint256 public preyPerBoost = 9000000000000000000;
    uint256 private treasuryShare = 60;
    uint256 public constant MAX_BOOST_COUNT = 5;
    uint256 public boostInterval = 24 hours;
    uint256 public winPecentage = 25;
    uint256[] public rewards = [2500e15, 3075e15, 4200e15];
    uint256[] public MAXREWARD_PER_BOOST = [12500e15, 15375e15, 21000e15];
    uint256[] public boostedNFTList;
    mapping(uint256 => BoostedNFT) public boostedNFTs;

    bool public initialised;

    constructor(AEPNFT _nft, IRewardToken _preyContract, address _address) {
        nft = _nft;
        preyContract = _preyContract;
        teamAddress = _address;
    }

    event Boosted(address indexed owner, uint256 indexed tokenId, uint256 indexed boostCount);
    event RewardPaid(address indexed user, uint256 indexed reward);
    event PausedStatusUpdated(bool indexed status);
    event GameResult(address indexed player, bool indexed boostSuccess);

    function initBoosting() public onlyOwner {
        require(!initialised, "Already initialised");
        boostStartTime = block.timestamp;
        initialised = true;
    }

    function bribe(uint256 _tokenId) public {
        require(initialised, "Boosting System: the boosting has not started");
        require(nft.ownerOf(_tokenId) == msg.sender, "User must be the owner of the token");
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        require(boostedNFT.boostCount < 5, "Max Boosts Reached");
        require(boostedNFT.bribeEncash == 0, "Max Boosts Reached");
        preyContract.burn(msg.sender, preyPerBoost);
        preyContract.mint(teamAddress, (preyPerBoost * treasuryShare) / 100);
        boostedNFT.bribeEncash = 1;
    }

    function boost(uint256 tokenId) public whenNotPaused nonReentrant returns (bool boostSuccess) {
        return _boost(tokenId);
    }

    function _boost(uint256 _tokenId) internal returns (bool boostSuccess) {
        require(initialised, "Boosting System: the boosting has not started");
        require(nft.ownerOf(_tokenId) == msg.sender, "User must be the owner of the token");
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        require(boostedNFT.boostCount < 5, "Max Boosts Reached");
        require(boostedNFT.bribeEncash == 1, "No Pending Bribes for Boost");
        if (boostedNFT.tokenBoostingCoolDown > 0) {
            require(
                boostedNFT.tokenBoostingCoolDown + 5 * boostInterval < block.timestamp,
                "Boost is Already Active"
            );
            // uint256[] memory tokenList = new uint[](1);
            // tokenList[0] = _tokenId;
            claimReward(_tokenId);
        }
        boostedNFT.bribeEncash = 0;
        if (!generateGameResult()) {
            emit GameResult(msg.sender, false);
            return false;
        } else {
            boostedNFT.totalRewardEarned += boostedNFT.rewardEarnedInBoost;
            boostedNFT.totalRewardReleased += boostedNFT.rewardReleasedInBoost;
            boostedNFT.rewardEarnedInBoost = 0;
            boostedNFT.rewardReleasedInBoost = 0;
            boostedNFT.tokenBoostingCoolDown = block.timestamp;
            boostedNFT.boostCount = boostedNFT.boostCount + 1;
            totalBoostedNFTs = boostedNFT.boostCount == 1 ? totalBoostedNFTs + 1 : totalBoostedNFTs;
            if (boostedNFT.boostCount == 1) {
                boostedNFTList.push(_tokenId);
            }
            totalBoosts = totalBoosts + 1;
            emit Boosted(msg.sender, _tokenId, boostedNFT.boostCount);
            emit GameResult(msg.sender, true);
            return true;
        }
    }

    function _updateReward(uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            BoostedNFT storage boostedNFT = boostedNFTs[_tokenIds[i]];
            if (
                boostedNFT.tokenBoostingCoolDown < block.timestamp + boostInterval &&
                boostedNFT.tokenBoostingCoolDown > 0
            ) {
                (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenIds[i]);
                uint256 tierIndex = uint256(tokenTier);
                uint256 tierReward = rewards[tierIndex];
                uint256 maxTierReward = MAXREWARD_PER_BOOST[tierIndex];

                uint256 boostedDays = ((block.timestamp - uint(boostedNFT.tokenBoostingCoolDown))) /
                    boostInterval;
                if (tierReward * boostedDays >= maxTierReward) {
                    boostedNFT.rewardEarnedInBoost = maxTierReward;
                } else {
                    boostedNFT.rewardEarnedInBoost = tierReward * boostedDays;
                }
            }
        }
    }

    function claimReward(uint256 _tokenId) public whenNotPaused {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "You can only claim rewards for NFTs you own!"
        );
        uint256[] memory tokenList = new uint[](1);
        tokenList[0] = _tokenId;
        _updateReward(tokenList);
        uint256 reward = 0;
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        reward += boostedNFT.rewardEarnedInBoost - boostedNFT.rewardReleasedInBoost;
        boostedNFT.rewardReleasedInBoost = boostedNFT.rewardEarnedInBoost;

        if (reward > 0) {
            preyContract.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function generateGameResult() private view returns (bool) {
        uint256 entropy = uint256(
            keccak256(abi.encodePacked(msg.sender, block.timestamp, tx.origin))
        );
        uint256 score = (entropy % 100) + 1;
        return score < winPecentage;
    }

    // Only in case of emergency 
    // Pause the contract for 5 days and then execute it.
    // This will release all pending boosting claims to all Players.
    function distributeRewardEmergency() external onlyOwner {
        uint256[] memory nftList = boostedNFTList;
        _updateReward(nftList);
        for (uint256 i = 0; i < nftList.length; i++) {
            address tokenOwner = nft.ownerOf(nftList[i]);
            uint256 reward = 0;
            BoostedNFT storage boostedNFT = boostedNFTs[nftList[i]];
            reward += boostedNFT.rewardEarnedInBoost - boostedNFT.rewardReleasedInBoost;
            boostedNFT.rewardReleasedInBoost = boostedNFT.rewardEarnedInBoost;
            if (reward > 0) {
                preyContract.mint(tokenOwner, reward);
                emit RewardPaid(tokenOwner, reward);
            }
        }
    }

    // This will destroy the contract completely.
    // Use this as a last resort.
    function destroyTavern(address payable _teamAddress) external onlyOwner {
        selfdestruct(_teamAddress);
    }

    //****************Only Owner Functions*********************//

    function updateWinPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Invalid Percentage Input");
        winPecentage = _percentage;
    }

    function updateBoostInterval(uint256 _intervalInSeconds) external onlyOwner {
        require(_intervalInSeconds > 0, "Invalid Interval");
        boostInterval = _intervalInSeconds;
    }

    function updatePreyPerBoost(uint256 _newPreyAmount) external onlyOwner {
        require(_newPreyAmount > 0, "Invalid Prey Amount");
        preyPerBoost = _newPreyAmount;
    }

    function updateTreasuryShare(uint256 _newTreasuryShare) external onlyOwner {
        require(_newTreasuryShare <= 100, "Invalid Tresury Share");
        treasuryShare = _newTreasuryShare;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    //****************Read Only Functions*********************//

    function getTokenTierIndex(
        uint256 _id
    ) public view returns (uint256 tokenIndex, AEPNFT.TIER tokenTier) {
        return (nft.tokenTierIndex(_id));
    }

    function isBoostActive(uint256 _tokenId) public view returns (bool boostIsActive) {
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        uint256 duration = block.timestamp - boostedNFT.tokenBoostingCoolDown;

        if (boostedNFT.tokenBoostingCoolDown != 0 && duration / boostInterval < 5) {
            return true;
        }
    }

    function calculateReward(uint256 _tokenId) public view returns (uint256) {
        uint256 claimableReward = 0;

        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        if (
            boostedNFT.tokenBoostingCoolDown < block.timestamp + boostInterval &&
            boostedNFT.tokenBoostingCoolDown > 0
        ) {
            (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenId);
            uint256 tierIndex = uint256(tokenTier);
            uint256 tierReward = rewards[tierIndex]; // 2.5 Token
            uint256 maxTierReward = MAXREWARD_PER_BOOST[tierIndex];
            uint256 totalRewardEarned = 0;

            uint256 boostedDays = ((block.timestamp - uint(boostedNFT.tokenBoostingCoolDown))) /
                boostInterval;
            if (tierReward * boostedDays >= maxTierReward) {
                totalRewardEarned = maxTierReward;
            } else {
                totalRewardEarned = tierReward * boostedDays;
            }
            claimableReward += totalRewardEarned - boostedNFT.rewardReleasedInBoost;
        }

        return claimableReward;
    }
}
