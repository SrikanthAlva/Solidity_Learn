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

contract BasicNFT is ERC721 {

    using Strings for uint256;

    string public constant baseURI = "https://ipfs.io/ipfs/QmT1qRf7EKPdner6vbhZjtAf6nFvU3hb8mzCEjk11i3vpV/";// CID of Metadata
    string public constant baseExtension = ".json";
    uint256 private tokenCounter = 1;

    constructor() ERC721("Quiz Geeks", "QZG")  {
    }

    function mintNFT() public {
        _safeMint(msg.sender, tokenCounter);
        tokenCounter = tokenCounter + 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        return bytes(baseURI).length != 0 ?
                string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
    }

    function getTokenCounter() public view returns(uint256){
        return tokenCounter;
    }

}
