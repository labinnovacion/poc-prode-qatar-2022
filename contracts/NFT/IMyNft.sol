// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



/**

 * @title IMyNft

 * @dev This interface manages the ERC21 token for the game.


 */



interface IMyNft {


    function mintNFT(address to, string memory idMatch) external;

    

}