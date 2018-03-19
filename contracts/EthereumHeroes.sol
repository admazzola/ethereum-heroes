pragma solidity ^0.4.8;
contract EthereumHeroesMarket {

    // You can use this hash to verify the image file containing all the heroes
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address public _0xBitcoinContract = "0x56b497ccf0dc858bb49ad820e99d6f29bcb2c1c7473b788d8ac8d7df1b87376d"; //ropsten


    address owner;

    string public standard = 'EthereumHeroes';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextHeroIndexToAssign = 0;

    bool public allHeroesAssigned = false;
    uint public heroesRemainingToAssign = 0;

    //mapping (address => uint) public addressToHeroIndex;
    mapping (uint => address) public heroIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint heroIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint heroIndex;
        address bidder;
        uint value;
    }

    // A record of heroes that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public heroesOfferedForSale;

    // A record of the highest hero bid
    mapping (uint => Bid) public heroBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 heroIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event HeroTransfer(address indexed from, address indexed to, uint256 heroIndex);
    event HeroOffered(uint indexed heroIndex, uint minValue, address indexed toAddress);
    event HeroBidEntered(uint indexed heroIndex, uint value, address indexed fromAddress);
    event HeroBidWithdrawn(uint indexed heroIndex, uint value, address indexed fromAddress);
    event HeroBought(uint indexed heroIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event HeroNoLongerForSale(uint indexed heroIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EthereumHeroesMarket() internal  {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000;                        // Update total supply
        heroesRemainingToAssign = totalSupply;
        name = "ETHEREUMHEROES";                                   // Set the name for display purposes
        symbol = "Ͼ";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint heroIndex) {
        if (msg.sender != owner) revert();
        if (allHeroesAssigned) revert();
        if (heroIndex >= 10000) revert();
        if (heroIndexToAddress[heroIndex] != to) {
            if (heroIndexToAddress[heroIndex] != 0x0) {
                balanceOf[heroIndexToAddress[heroIndex]]--;
            } else {
                heroesRemainingToAssign--;
            }
            heroIndexToAddress[heroIndex] = to;
            balanceOf[to]++;
            Assign(to, heroIndex);
        }
    }

    function setInitialOwners(address[] addresses, uint[] indices) {
        if (msg.sender != owner) revert();
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) revert();
        allHeroesAssigned = true;
    }

    function getHero(uint heroIndex) {
        if (!allHeroesAssigned) revert();
        if (heroesRemainingToAssign == 0) revert();
        if (heroIndexToAddress[heroIndex] != 0x0) revert();
        if (heroIndex >= 10000) revert();
        heroIndexToAddress[heroIndex] = msg.sender;
        balanceOf[msg.sender]++;
        heroesRemainingToAssign--;
        Assign(msg.sender, heroIndex);
    }

    // Transfer ownership of a hero to another user without requiring payment
    function transferHero(address to, uint heroIndex) {
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] != msg.sender) revert();
        if (heroIndex >= 10000) revert();
        if (heroesOfferedForSale[heroIndex].isForSale) {
            heroNoLongerForSale(heroIndex);
        }
        heroIndexToAddress[heroIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        HeroTransfer(msg.sender, to, heroIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = heroBids[heroIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            heroBids[heroIndex] = Bid(false, heroIndex, 0x0, 0);
        }
    }

    function heroNoLongerForSale(uint heroIndex) {
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] != msg.sender) revert();
        if (heroIndex >= 10000) revert();
        heroesOfferedForSale[heroIndex] = Offer(false, heroIndex, msg.sender, 0, 0x0);
        HeroNoLongerForSale(heroIndex);
    }

    function offerHeroForSale(uint heroIndex, uint minSalePriceInWei) {
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] != msg.sender) revert();
        if (heroIndex >= 10000) revert();
        heroesOfferedForSale[heroIndex] = Offer(true, heroIndex, msg.sender, minSalePriceInWei, 0x0);
        HeroOffered(heroIndex, minSalePriceInWei, 0x0);
    }

    function offerHeroForSaleToAddress(uint heroIndex, uint minSalePriceInWei, address toAddress) {
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] != msg.sender) revert();
        if (heroIndex >= 10000) revert();
        heroesOfferedForSale[heroIndex] = Offer(true, heroIndex, msg.sender, minSalePriceInWei, toAddress);
        HeroOffered(heroIndex, minSalePriceInWei, toAddress);
    }

    //instead of payable, trigger this via ApproveAndCall
    function _buyHero(uint heroIndex) internal {
        if (!allHeroesAssigned) revert();
        Offer offer = heroesOfferedForSale[heroIndex];
        if (heroIndex >= 10000) revert();
        if (!offer.isForSale) revert();                // hero not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert();  // hero not supposed to be sold to this user
        if (msg.value < offer.minValue) revert();      // Didn't send enough ETH
        if (offer.seller != heroIndexToAddress[heroIndex]) revert(); // Seller no longer owner of hero

        address seller = offer.seller;

        heroIndexToAddress[heroIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        heroNoLongerForSale(heroIndex);
        pendingWithdrawals[seller] += msg.value;
        HeroBought(heroIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = heroBids[heroIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            heroBids[heroIndex] = Bid(false, heroIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allHeroesAssigned) revert();
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    //instead of payable, trigger this via ApproveAndCall
    function _enterBidForHero(uint heroIndex) internal {
        if (heroIndex >= 10000) revert();
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] == 0x0) revert();
        if (heroIndexToAddress[heroIndex] == msg.sender) revert();
        if (msg.value == 0) revert();
        Bid existing = heroBids[heroIndex];
        if (msg.value <= existing.value) revert();
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        heroBids[heroIndex] = Bid(true, heroIndex, msg.sender, msg.value);
        HeroBidEntered(heroIndex, msg.value, msg.sender);
    }

    function acceptBidForHero(uint heroIndex, uint minPrice) {
        if (heroIndex >= 10000) revert();
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] != msg.sender) revert();
        address seller = msg.sender;
        Bid bid = heroBids[heroIndex];
        if (bid.value == 0) revert();
        if (bid.value < minPrice) revert();

        heroIndexToAddress[heroIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        heroesOfferedForSale[heroIndex] = Offer(false, heroIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        heroBids[heroIndex] = Bid(false, heroIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        HeroBought(heroIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForHero(uint heroIndex) {
        if (heroIndex >= 10000) revert();
        if (!allHeroesAssigned) revert();
        if (heroIndexToAddress[heroIndex] == 0x0) revert();
        if (heroIndexToAddress[heroIndex] == msg.sender) revert();
        Bid bid = heroBids[heroIndex];
        if (bid.bidder != msg.sender) revert();
        HeroBidWithdrawn(heroIndex, bid.value, msg.sender);
        uint amount = bid.value;
        heroBids[heroIndex] = Bid(false, heroIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

    // ------------------------------------------------------------------------

   // Don't accept ETH

   // ------------------------------------------------------------------------

     function () public payable {

         revert();

     }


      /*
        Receive approval to spend tokens and perform any action all in one transaction
      */
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
      if (token != _0xBitcoinContract) revert();
      if (msg.sender != _0xBitcoinContract) revert();

      //parse the data:   first byte is for 'action_id'
      byte action_id = data[0];


      if(action_id == 0x1)
      {
        //  uint heroIndex = data[?]
       //  _enterBidForHero(uint heroIndex)
      }


      if(action_id == 0x2) 
      {
        //  uint heroIndex = data[?]
        // _buyHero(uint heroIndex) internal
      }




    }


}
