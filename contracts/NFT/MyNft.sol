// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    uint256 token_count;
    mapping (uint256 => string) imageUri;
    string baseUri = "https://raw.githubusercontent.com/labinnovacion/poc-prode-qatar-2022/main/contracts/NFT/images/"; 

    constructor() ERC721("Prode NFT", "PNFT") {
        
        //El contrato ahora es Ownable, Ownable tiene su propio contructor, asi que el msg.sender es el owner, cuando quieras pasarlo el contrato de Maty, usas la transaccion transferOwnership y le mandas la dire del contrato de maty.
        //owner = msg.sender; //colocar el address del contrato del prode
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        //return "https://ipfs.io/ipfs/QmfUVCYQyounx9GUUrYcJmw3yNppqJduPJ7nb1ciLaX3mu";
        // return baseUri + class_match[id_class[tokenId]]
        return imageUri[tokenId];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        //baseUri = "https://raw.githubusercontent.com/labinnovacion/poc-prode-qatar-2022/main/contracts/NFT/images/";
        return baseUri;
    }

    function updateUrlMatch(string memory idMatch) view public returns (string memory) {
       return string(abi.encodePacked(baseUri,idMatch)); 
    }

    function updateBaseUri(string memory newBaseUri) public returns (string memory) {
        baseUri = newBaseUri;
        return _baseURI();
    }

    function mintNFT(address to, string memory idMatch) public onlyOwner
    {
        string memory finalUrl = string(abi.encodePacked(idMatch,".txt"));
        token_count  += 1;
        imageUri[token_count] = updateUrlMatch(finalUrl);
        _mint(to, token_count);
        
    }
}