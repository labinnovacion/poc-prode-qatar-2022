// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.2/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.7.2/utils/Counters.sol";

contract MyToken is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    uint256 token_count;
    mapping (uint256 => string) imageUri;
    string baseUri = "https://raw.githubusercontent.com/labinnovacion/poc-prode-qatar-2022/main/contracts/NFT/images/"; 
    address private owner;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Prode NFT", "PNFT") {
        owner = msg.sender; // colocar el address del contrato del prode
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function safeMint(address to, string memory idMatch) public  {
        uint256 tokenId = _tokenIdCounter.current();
        string memory finalUrl = string(abi.encodePacked(idMatch,".txt"));
        imageUri[token_count] = updateUrlMatch(finalUrl);
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, idMatch);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
       // return super.tokenURI(tokenId);
       return imageUri[tokenId];
    }

     function updateUrlMatch(string memory idMatch) view public returns (string memory) {
       return string(abi.encodePacked(baseUri,idMatch)); 
    }

    function updateBaseUri(string memory newBaseUri) public returns (string memory) {
        baseUri = newBaseUri;
        return _baseURI();
    }
}