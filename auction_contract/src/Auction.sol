// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
每个购买者在拍卖期间发送他们的竞标到智能合约。竞标包括发送资金，以
便将购买者与他们的竞标鄉定。如果最高出价被提高，之前的出价者就可以
拿回他们的竞标资金。竞价期结束后，出售人可以手动调用合约，收到他们
的收益。
 */

// auction contract
contract Auction is Ownable{

    address private seller;

    // start time, before this time, the action can not start
    uint private immutable start_at;

    // end time, after this time, the action can not moving on
    uint private immutable expire_at;

    uint private current_bid;

    uint private last_days = 30 days;

    address payable private current_max_bidder;

    event Bidding_msg(address addr, uint price);
    event AuctionEnded(address indexed winner, uint winningBid);


    // init with the msg.sender as the owner
    constructor(uint _initPrice) Ownable(msg.sender) {
        start_at = block.timestamp;
        expire_at = block.timestamp + last_days;
        current_bid = _initPrice;
        seller = msg.sender;
    }

    // 发送竞价价格
    function bidding() external payable{
        // 检查是否在竞价期内
        require(block.timestamp > start_at, "the auction is not start");
        require(block.timestamp < expire_at, "the anction is ended");

        // 竞标价格需要大于当前的价格
        require(msg.value > current_bid, "price must higher than current price");

         // 退回他的竞标价格
        if (current_max_bidder != address(0)) {
            (bool success, ) = current_max_bidder.call{value: current_bid}("");
            require(success, "Refund previous bidder failed");
        }

        // 竞价后的新的价格
        current_bid = msg.value;
        current_max_bidder = payable(msg.sender);

        // 提交一个事件
        emit Bidding_msg(msg.sender, msg.value);

    }


    // 只有合约的拥有者才可以调用
    function endAuction() external onlyOwner{
        // 只有合约结束了才可以获取收益
        require(block.timestamp > expire_at, "auction is not ended");

        // 获取收益
        (bool success, ) = seller.call{value: current_bid}("");
        require(success, "transfer faile");

        emit AuctionEnded(current_max_bidder, current_bid);
    }

}

