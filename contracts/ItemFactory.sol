// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SingleItem.sol";

contract ItemFactory is Ownable {
    uint256 public fee = 250;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => ItemListing[]) userListings;
    mapping(address => reviewStruct[]) userRatings;
    address[] allSellers;

    event ListingCreated(string name, string symbol, string imageURL, string keyword, uint256 WETHRequested, uint256 fee);
    /** 
    listingVars
    _name = name of the item for frontend display
    _symbol = ticker for the symbol if necessary
    _imageURL = image url 
    _keyword = category keyword for search assistance
    _WETHRequested = weth wei value requested for the item
    */

    struct reviewStruct{
        uint256 rating;
        string reviewDesc;
    }

    function setFee(uint256 newFee) public onlyOwner returns (uint256) {
        fee = newFee;
        return newFee;
    }

    function createListing(
        string memory name,
        string memory symbol,
        string memory imageURL,
        string memory keyword,
        uint256 WETHRequested
        ) external returns (ItemListing) {

        require(msg.sender != owner());
        require(WETHRequested <= IERC20(WETH).totalSupply());

        ItemListing newListing = new ItemListing(name, symbol, imageURL, keyword, WETHRequested, fee);
        userListings[msg.sender].push(newListing);
        allSellers.push(msg.sender);

        emit ListingCreated(name, symbol, imageURL, keyword, WETHRequested, fee);
        return (newListing);
    }

    function reviewSeller(ItemListing _CompletedListing, uint256 rating, string memory reviewDesc) external returns (reviewStruct memory) {
        require(rating == 0 || rating == 1 || rating == 2 || rating == 3 || rating == 4 || rating == 5);
        require(_CompletedListing.isReviewed() == false);
        require(_CompletedListing.getBuyer() == msg.sender, "Only the buyer can review a seller");
        require(_CompletedListing.getFactory() == address(this));
        
        address seller = _CompletedListing.getSeller();
        reviewStruct memory vars;
        vars.rating = rating;
        vars.reviewDesc = reviewDesc;

        userRatings[seller].push(vars);
        return vars;
    }

    function getSellerReviews(address seller_) public view returns (reviewStruct[] memory) {
        return userRatings[seller_];
    }

    //use dis in de frontend to run through an array of all sellers and their listings
    function GetAllSellers() public view returns (address[] memory) {
        return allSellers;
    }

    function GetActiveListingsBySeller(address seller_) public view returns (ItemListing[] memory) {
        return userListings[seller_];
    }
}