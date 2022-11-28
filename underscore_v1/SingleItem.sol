// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract ItemListing is ReentrancyGuard {

    string name;
    string symbol;
    string imageURL;
    string keyword;
    uint256 public immutable WETHRequested;
    uint256 public immutable fee;
    address public buyer;

    event ItemBought(address Buyer, address Seller, address Arbitrator, uint256 WETHRequested);
    event BuyerAprove(address Buyer, uint256 buyerApprove);
    event BuyerReject(address Buyer, uint256 buyerApprove);
    event SellerApprove(address Seller, uint256 sellerApprove);
    event ArbitratorApprove(address Arbitrator, uint256 arbitratorApprove);
    event ArbitratorReject(address Arbitrator, uint256 arbitratorApprove);
    event BuyerClaim(address Buyer, address Seller, address Listing, bool hasEnded);
    event SellerClaim(address Buyer, address Seller, address Listing, bool hasEnded);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    //ItemListing(name, symbol, imageURL, keyword, WETHRequested);
    address factory = msg.sender;
    address seller = tx.origin;
    address arbitrator = Ownable(factory).owner();
    
    /**
    0 = not approved
    1 = approved
    3 = not true or false but a secret third thing
        (jk its wen u want to undo a purchase because mr. buyer fucked u UwU)
    and they're 256 byes cuz fuck you

    bought is just true false with 0 false and 1 true
     */

    uint256 buyerApprove = 0;
    uint256 sellerApprove = 0;
    uint256 arbitratorApprove = 0;
    uint256 bought = 0;
    bool hasEnded = false;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _imageURL,
        string memory _keyword,
        uint256 _WETHRequested,
        uint256 _fee
        ) {
        name = _name;
        symbol = _symbol;
        imageURL = _imageURL;
        keyword = _keyword;
        fee = _fee;
        WETHRequested = _WETHRequested;
    }
    
    /**
     * @dev Throws if called by any account other than the Seller.
     */
    modifier onlySeller() {
        require(msg.sender == seller, "R4");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the Arbitrator.
     */
    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "R4");
        _;
    }

    function getWETH() public view returns (uint256) {
        uint256 escrowWETH = IERC20(WETH).balanceOf(address(this));
        return escrowWETH;
    }

    function buyItem() public nonReentrant returns (uint256) {
        require(msg.sender != seller || msg.sender != arbitrator); // no insider tradinnn!
        require(IERC20(WETH).balanceOf(msg.sender) >= WETHRequested); // U TOO POOR
        require(bought == 0); //cant buy twice

        uint256 arbitratorFee = (WETHRequested * fee) / 10000;

        IERC20(WETH).transferFrom(msg.sender, address(this), WETHRequested);
        IERC20(WETH).transferFrom(address(this), arbitrator, arbitratorFee);

        emit ItemBought(msg.sender, seller, arbitrator, WETHRequested);
        buyer = msg.sender;
        bought = 1;
        return bought;
    }

    //buyer approval to give seller moneys once item is received
    function buyerApproval() external nonReentrant returns (uint256) {
        require(msg.sender == buyer);
        require(buyerApprove == 0);

        emit BuyerAprove(buyer, buyerApprove);
        buyerApprove = 1;
        return buyerApprove;
    }

    //for returning funds to da buyer if the seller betways dem
    function buyerReject() external nonReentrant returns (uint256) {
        require(msg.sender == buyer);
        require(buyerApprove == 0);

        emit BuyerReject(buyer, buyerApprove);
        buyerApprove = 3;
        return buyerApprove;
    }

    //for seller approving 1nce dey send da item
    function sellerApproval() external onlySeller nonReentrant returns (uint256) {
        require(sellerApprove == 0);

        emit SellerApprove(seller, sellerApprove);
        sellerApprove = 1;
        return sellerApprove;
    }

    //arbitrator approval to give funds to seller
    function arbitratorApproval() external onlyArbitrator nonReentrant returns (uint256) {
        require(arbitratorApprove == 0);

        emit ArbitratorApprove(arbitrator, arbitratorApprove);
        arbitratorApprove = 1;
        return arbitratorApprove;
    }

    //for returning funds to da buyer if the seller betways dem
    function arbitratorReject() external onlyArbitrator nonReentrant returns (uint256) {
        require(arbitratorApprove == 0);

        emit ArbitratorReject(arbitrator, arbitratorApprove);
        arbitratorApprove = 3;
        return arbitratorApprove;
    }

    //for buyer to get bak moneyz if dey get screwed over
    //if true then dey get deir money bak
    //if false den NOT APPROVED YET!!!!11!
    function buyerClaim() public nonReentrant returns (bool) {
        require(msg.sender == buyer);
        if (arbitratorApprove == 3 && buyerApprove == 3) {
            IERC20(WETH).transfer(buyer, IERC20(WETH).balanceOf(address(this)));

            emit BuyerClaim(buyer, seller, address(this), true);
            hasEnded = true;
            return hasEnded;
        }
        else {
            return hasEnded;
        }
    }

    //for seller to claim moneyz if dey wer good boyz/girlz
    //if returns true then moneyz transferred
    //if false den NOT APPROVED YET!!!!11!
    function sellerClaim() public onlySeller nonReentrant returns (bool) {
        if (buyerApprove == 1 && sellerApprove == 1) {
            IERC20(WETH).transfer(seller, IERC20(WETH).balanceOf(address(this)));
            
            emit SellerClaim(buyer, seller, address(this), true);
            hasEnded = true;
            return hasEnded;
        }
        else if (arbitratorApprove == 1 && sellerApprove == 1) {
            IERC20(WETH).transfer(seller, IERC20(WETH).balanceOf(address(this)));

            emit SellerClaim(buyer, seller, address(this), true);
            hasEnded = true;
            return hasEnded;
        }
        else {
            return hasEnded;
        }
    }

    function hasBeenBought() public view returns (uint256) {
        return bought;
    }
    //iz we done????!?
    function isItOver() public view returns (bool) {
        return hasEnded;
    }
}