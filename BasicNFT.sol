// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

// Come Up with a Unique Idea
// Create Art Work assocaited with the NFT - Generative Art - AI Generated Art - Hand Drawn
// Create Metadata for each NFT
// Upload the NFT images and Metadata onto IPFS
// We Write Smart Contract to Launch the Collection
// In the Contract we specify MAX_SUpply, BASE_URL, COllection Name and SYMBOL
// Deploy the contract

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasicNFT is ERC721, Ownable {

    using Strings for uint256;

    string public constant baseURI = "https://ipfs.io/ipfs/QmT1qRf7EKPdner6vbhZjtAf6nFvU3hb8mzCEjk11i3vpV/";// CID of Metadata
    string public constant baseExtension = ".json";
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public tokenCounter = 1;
    uint256 public mintFee = 0.01 ether;
    bool public revealed = false;
    bool public onlyAllowList = true;
    
    mapping(address => uint256) public mintPerWallet;

    mapping(address => bool) public allowList;

    // 1. Accept a minimum 0.01 Ether to Mint an NFT
    // 2. Set Max no of Tokens that can ever be created in this collection.
    // 3. Create an AllowList -> Only Allowed Addresess can mint an NFT.

    constructor() ERC721("Quiz Geeks", "QZG") {}

    function mintNFT() public payable {
        require( tokenCounter + 1 <= MAX_SUPPLY , "Max Supply Reached");
        require(msg.value >= mintFee, "Insufficient Price");
        if(onlyAllowList){
        require(allowList[msg.sender] == true, "Sorry, you are not in the allowlist");
        require( mintPerWallet[msg.sender] < 1, "Max Mint per Wallet Reached");
        }

        _safeMint(msg.sender, tokenCounter);
        mintPerWallet[msg.sender] = mintPerWallet[msg.sender] + 1;
        tokenCounter = tokenCounter + 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!revealed){
            return "https://api.orangecomet.io/collectible-metadata/eternal/1";
        }else {
            return bytes(baseURI).length != 0 ?
                string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
        }
    }

    function getTokenCounter() public view returns(uint256){
        return tokenCounter;
    }

    function updateMintFee(uint256 newMintFee) external onlyOwner {
        mintFee = newMintFee;
    }

    function addAllowList(address[] memory allowListAddr) external onlyOwner {
        for(uint i =0; i<allowListAddr.length; i++){
            allowList[allowListAddr[i]] = true;
        }
    }

    function revealNft() external onlyOwner {
        revealed = true;
    }

    function openForPublicSale() external onlyOwner {
        onlyAllowList = false;
    }

}
