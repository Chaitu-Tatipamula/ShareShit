// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract DEsh is IERC1155Receiver, IERC721Receiver{
    
    // token types 
    // 0 --> normal eth transfer 
    // 1 --> ERC20 token transfer 
    // 2 --> ER721 token transfer 
    // 3 --> ERC1155 token transfer 

    // pubKey for safety while claiming the tokens

    event DepositEvent(address sender, uint256 index, uint8 tokenType, uint256 amount);
    event WithdrawEvent(address receiver, uint256 index, uint8 tokenType, uint256 amount);
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


    function getAll(address _address) public view returns (DepositItem[] memory) {
        DepositItem[] memory _deposits = new DepositItem[](deposits.length);
        uint indexToAdd = 0;
        for(uint i=0; i<deposits.length; i++){
            if(deposits[i].sender == _address){
                _deposits[indexToAdd] = deposits[i];
                indexToAdd++;
            }
        }
        return _deposits;
    }


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
                    tokenType : 3
                })
            );
        }

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
        return interfaceId == type(IERC721Receiver).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function receiveFund(
        uint256 index
    ) public payable returns (bool){
        require(index < deposits.length, "Non existent Deposit ");
        DepositItem memory deposit = deposits[index];
        require(deposit.sender != msg.sender, "sender can't receive fund");
        require(deposit.amount > 0, "Already received");
        delete deposits[index];

        if(deposit.tokenType == 0){
            (bool sucess, ) = deposit.sender.call{value : deposit.amount}("");
            require(sucess, "transfer FAILED");
        }  else if(deposit.tokenType == 1){
            IERC20 token = IERC20(deposit.tokenAddress);
            SafeERC20.safeTransferFrom(token, address(this), msg.sender, deposit.amount);
        }  else if(deposit.tokenType == 2){
            IERC721 token = IERC721(deposit.tokenAddress);
            token.safeTransferFrom(address(this), msg.sender, deposit.tokenId, "");
        }   else if(deposit.tokenType ==3){
            IERC1155 token = IERC1155(deposit.tokenAddress);
            token.safeTransferFrom(address(this), msg.sender, deposit.tokenId, deposit.amount, "");
        }
        emit WithdrawEvent(msg.sender, index, deposit.tokenType, deposit.amount);
        return true;
    }




    function createShittyLink(
        address _tokenAddress,
        uint8 _tokenType,
        uint256 _amount,
        uint256 _tokenId
    ) public payable returns (uint256) {
        require(_tokenType <= 3, "Token type cannot be accepted");

        if(_tokenType == 0){
            require(msg.value > 0, "send some ETHER to share");
            _amount = msg.value;
        } else if(_tokenType == 1){
            IERC20 token = IERC20(_tokenAddress);
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);
        } else if(_tokenType == 2){
            IERC721 token = IERC721(_tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), _tokenId, "internal transfer");
        } else if(_tokenType == 3){
            IERC1155 token = IERC1155(_tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "internl transfer");
        }

        deposits.push(
            DepositItem({
                sender  : msg.sender,
                tokenAddress : _tokenAddress,
                amount : _amount,
                tokenId : _tokenId,
                timestamp : block.timestamp,
                tokenType : _tokenType 
            })
        );
        emit DepositEvent(msg.sender, deposits.length-1, _tokenType, _amount);

        return deposits.length - 1;
    }



    function revertCreation(
        uint256 _index
    ) public returns (bool)  {

        require(_index < deposits.length, "Non existent Deposit ");
        DepositItem memory deposit = deposits[_index];
        require(deposit.sender == msg.sender, "only the sender can revert"); 

        delete deposits[_index];

        if(deposit.tokenType == 0){
            (bool sucess, ) = deposit.sender.call{value : deposit.amount}("");
            require(sucess, "transfer FAILED");
        }  else if(deposit.tokenType == 1){
            IERC20 token = IERC20(deposit.tokenAddress);
            SafeERC20.safeTransferFrom(token, address(this), msg.sender, deposit.amount);
        }  else if(deposit.tokenType == 2){
            IERC721 token = IERC721(deposit.tokenAddress);
            token.safeTransferFrom(address(this), msg.sender, deposit.tokenId, "");
        }   else if(deposit.tokenType ==3){
            IERC1155 token = IERC1155(deposit.tokenAddress);
            token.safeTransferFrom(address(this), msg.sender, deposit.tokenId, deposit.amount, "");
        }
        return true;     
    }



}