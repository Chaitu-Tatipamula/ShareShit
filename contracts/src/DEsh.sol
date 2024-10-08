// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";


contract DEsh is IERC1155Receiver, IERC721Receiver{

    // token types 
    // 0 --> normal eth transfer 
    // 1 --> ERC20 token transfer 
    // 2 --> ER721 token transfer 
    // 3 --> ERC1155 token transfer 

    // pubKey for safety while claiming the tokens

    event DepositEvent(uint256 index);
    struct DepositItem {
        address sender;
        address tokenAddress;
        uint256 amount;
        uint256 tokenId;
        uint256 timestamp;
        uint8 tokenType;
        // address pubKey;
    }


    // Array of deposits
    DepositItem[] public deposits;



    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        if(operator == address(this)){
            return this.onERC721Received.selector;
        }else if(data.length != 32){
            revert("Invalid calldata provided");
        }

        deposits.push(
            DepositItem({
                sender : from,
                tokenAddress : msg.sender,
                amount : 1,
                tokenId : tokenId,
                timestamp : block.timestamp,
                tokenType : 2
            })
        );
        emit DepositEvent(deposits.length-1);
        return this.onERC721Received.selector;
    }



    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4){
        if(operator == address(this)){
            return this.onERC1155Received.selector;
        }else if(data.length != 32){
            revert("Invalid calldata provided");
        }

        deposits.push(
            DepositItem({
                sender : from,
                tokenAddress : msg.sender,
                amount : value,
                tokenId : id,
                timestamp : block.timestamp,
                tokenType : 3
            })
        );

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4){
        if(operator == address(this)){
            return this.onERC1155BatchReceived.selector;
        }else if(data.length != (ids.length * 32)){
            revert("Invalid calldata provided");
        }

        for(uint i =0; i < ids.length; i++){
            deposits.push(
                DepositItem({
                    sender : from,
                    tokenAddress : msg.sender,
                    amount : values[i],
                    tokenId : ids[i],
                    timestamp : block.timestamp,
                    tokenType : 4
                })
            );
        }

        return this.onERC1155BatchReceived.selector;
    }


}