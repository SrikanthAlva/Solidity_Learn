//SPDX-License-Identifier:MIT

// 1. ListNFT on the Marketplace
// 2. buyNFT from the Marketplace
// 3. CancelListing from the Marketplace
// 4. updateListing to update the price
// 5. withdrawFunds from the marketplace to my wallet.

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NFTMarketplace__PriceMustBeAboveZero();
error NFTMarketplace__NotApprovedForMarketplace();
error NftMarketplace__NotOwner();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price
);
error NFTMarketplace__NoProceeds();
error NFTMarketplace__TransferFailed();

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price; // Price of the Item
        address seller; // Address of the seller
    }

    // NFTContract Address is mapped to (tokenId => Listing Details)
    mapping(address => mapping(uint256 => Listing)) private listings;

    mapping(address => uint256) private proceeds;

    event ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCancelled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != spender) {
            revert NftMarketplace__NotOwner();
        }

        _;
    }

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory nft = listings[nftAddress][tokenId];
        if (nft.price != 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }

        _;
    }

    modifier isListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory nft = listings[nftAddress][tokenId];
        if (nft.price <= 0) {
            revert NftMarketplace__NotListed(nftAddress, tokenId);
        }

        _;
    }

    // ListItem
    function ListItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(nftAddress, tokenId, msg.sender)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NFTMarketplace__PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NFTMarketplace__NotApprovedForMarketplace();
        }
        listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    // buyItem
    function BuyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId, msg.sender)
        nonReentrant
    {
        Listing memory listedItem = listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NftMarketplace__PriceNotMet(
                nftAddress,
                tokenId,
                listedItem.price
            );
        }
        proceeds[listedItem.seller] += msg.value;
        delete listings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );
        emit ItemBought(msg.sender, nftAddress, tokenId, msg.value);
    }

    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId, msg.sender)
    {
        delete listings[nftAddress][tokenId];
        emit ItemCancelled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId, msg.sender)
    {
        if (newPrice <= 0) {
            revert NFTMarketplace__PriceMustBeAboveZero();
        }
        listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external nonReentrant {
        uint256 amount = proceeds[msg.sender];
        if (amount <= 0) {
            revert NFTMarketplace__NoProceeds();
        }
        proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert NFTMarketplace__TransferFailed();
        }
    }
}
