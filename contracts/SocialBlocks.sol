// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AccountCreation.sol";
import "./Verify.sol";
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint _amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract SocialBlocks is AccountCreation("Social Blocks", "$SB"), Ownable, Verify {
    using Strings for uint256;
    // using SafeERC20 for IERC20;




    struct PostInfo {
        uint8 buyStatus;
        uint256 sellValue;
        uint256 bidDuration;
        string uri;
    }
    mapping(uint256 => PostInfo) private postInfo;

    IERC20 public rewardToken;
    // Stores max token id
    uint256 maxTokenId = 1;
    uint256 rewardFactor = 1000;
    uint256 ONE = 1 ether;
    address public admin;
    // address lastBidder;
    
    //following this buyStatus
    // enum PostStatus {
    //     BUYABLE,
    //     BIDDABLE,
    //     NOT_FOR_SELL
    // }

    // Stores all the token/ post ids of the user
    mapping(address => uint256[]) public userPostIds;

    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // mapping from user to rewardClaimedByUser
    mapping(address => uint256) public rewardClaimed;

    // mapping from postId to likesCount
    mapping(uint256 => uint256) public idToLikes;

    // mapping from nftId to owner
    mapping(uint256 => address) public idToOwner;
    
    // mapping from postId to lastBidder
    mapping(uint256 => address) public postLastBidder;

    // mapping from user to postID to price 
    mapping(address => mapping(uint256 => uint256)) public userBid;



    constructor(IERC20 _rewardToken, address _admin) {  
        rewardToken = _rewardToken;
        admin = _admin;
    }

    modifier _onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    modifier ValidToChange(uint256 _postId) {
        require(_postId > 0 && _postId <= maxTokenId, "postId must be greater than 0 or valid");
        require(msg.sender == idToOwner[_postId] , "irrelevant post id against this user");
        _;
    }
    modifier isValidUser() {
        require(bytes(userName[msg.sender]).length != 0, "Create Account First");
        _;
    }
    
    // onlyowner functions
    function changeRewardToken(IERC20 _rewardToken) external _onlyOwner {
        rewardToken = _rewardToken;
    }
    function changeAdminAddress(address _admin) external _onlyOwner {
        admin = _admin;
    }
    function changeRewardFactor(uint256 _rewardFactor) external _onlyOwner{
        require(rewardFactor != _rewardFactor, "can not set the previous reward factor");
        rewardFactor = _rewardFactor;
    }


    // Getter functions
    // Get postInfo by post id
    function getPostInfo(uint256 _postId) public view returns (PostInfo memory) {
        return postInfo[_postId];
    }
    function getOwnerById(uint256 _postId) public view returns (address) {
        return idToOwner[_postId];
    }
    function getLastBidInfoById(uint256 _postId) public view returns (address, uint256, uint256) {
        address lastBidder = postLastBidder[_postId];
        return (postLastBidder[_postId], userBid[lastBidder][_postId], postInfo[_postId].bidDuration);
    }

    //Get token Ids of all tokens owned by _owner
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }
    //setter functions


    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
    // update postInfo struct, best use after the post is newly purchased
    function changePostInfo(uint256 _postId, uint8 _buyStatus, uint256 _price, uint256 _bidDuration)
        external 
        ValidToChange(_postId) 
        isValidUser
    {
        postInfo[_postId] = PostInfo(_buyStatus, _price, _bidDuration,  postInfo[_postId].uri);
        emit PostDetailsChanged(_postId, _buyStatus, _price, _bidDuration);
        
    } 
    
    function changePostStatus(uint256 _postId, uint8 _status) external ValidToChange(_postId) isValidUser {
        require(
            _status < 3 && postInfo[_postId].buyStatus != _status,
            "can't set the previous or undefined status"
        );

        postInfo[_postId].buyStatus = _status;
        emit PostDetailsChanged(_postId, _status, postInfo[_postId].sellValue, postInfo[_postId].bidDuration);
    }


    function changePostPrice(uint256 _postId, uint256 _price) external ValidToChange(_postId) isValidUser {
        require(
            postInfo[_postId].sellValue != _price,
            "can't set the previous value status"
        );
        require(postInfo[_postId].buyStatus == 2, "post is not for sale");
        postInfo[_postId].sellValue = _price;
        emit PostDetailsChanged(_postId, postInfo[_postId].buyStatus, _price, postInfo[_postId].bidDuration);
    }

    function claimPostReward
    (
        uint256 _postId, 
        uint256 _likesCount,
        bytes memory _signature, 
        bytes32 signedMessageHash
    ) 
    external {
        //local copy for gas efficiency
        address user = msg.sender;
        require(_postId > 0 && idToOwner[_postId] == user, "Invalid postId");
        require(verify(admin, _signature, signedMessageHash), "Invalid signature");
        
        // total reward of the post minus rewardPaid = reward to be paid
        uint256 likes = _likesCount - idToLikes[_postId];
        uint256 reward = ((likes * ONE) / rewardFactor) ;
        if(reward > 0) {
            idToLikes[_postId] += likes;
            rewardClaimed[user] += reward;
            rewardToken.mint(user, reward);
        }
        emit PostRewardClaimed(user, _postId, reward);
    }

    function bid(uint256 _postId) external payable isValidUser {
        //check username of bidder if account created
        uint256 _price = msg.value;
        PostInfo memory _postInfo = postInfo[_postId];
        address lastBidder = postLastBidder[_postId];

        require(
            _postInfo.buyStatus == 1,
            "post is not biddable"
        );
        require(
            _postId <= maxTokenId,
            "invalid post id"
        );
        require(
            _price > 0 
            && _price >= _postInfo.sellValue,
            "price must be greater than 0 or last set price"
        );
        require(
            _price > userBid[lastBidder][_postId],
            "price must be greater than the previous bid"
        );
        require(
            block.timestamp < _postInfo.bidDuration, 
            "bidding has been off"
        );

        //approval is mandatory first
        // bool sent1; 
        bool sent2;
        // sending bid amount from bidder to this contract (amount lcoked)
        
        // (sent1,) = address(this).call{value: _price}(""); // msg.value is already sent, so no need for this line. 
        // (sent1) = rewardToken.transferFrom(msg.sender, address(this), _price);
        
        // all bids except first one
        if(lastBidder != address(0)) {
            // (sent2) = rewardToken.transfer(lastBidder, userBid[lastBidder][_postId]);
            // returning bid amount from contract to last bidder
            (sent2,) = lastBidder.call{value: userBid[lastBidder][_postId]}(""); // returning last bid amount to last bidder
            require(sent2, "transfer fail");
        } 
        // else {
        //     // for the first bid placement
        //     require(sent1, "transfer fail");
        // }
        userBid[msg.sender][_postId] = _price;
        // lastBidder = msg.sender;
        postLastBidder[_postId] = msg.sender;
        emit BidPlaced(msg.sender, _postId, _price);
    }

    function claimBid(uint256 _postId) external isValidUser{
        //check username of bidder if account created

        // uint256 _price = msg.value;
        address user = msg.sender;
        address lastBidder = postLastBidder[_postId];
        address owner = getOwnerById(_postId);
        uint8 buyStatus = postInfo[_postId].buyStatus;
        uint256 _price = userBid[lastBidder][_postId];
        require(_postId <= maxTokenId, "invalid post id");
        require(
            buyStatus == 1,
            "non-biddbale post's purchase call"
        );
        require(user == lastBidder || user == owner, "invalid caller");
        // check for, last bidder can't purchase before bid has passed,
        // only owner can sell before bid duration ends.
        if(user == lastBidder) require(postInfo[_postId].bidDuration <= block.timestamp, "bid is actively ON");

        idToOwner[_postId] = lastBidder;
        postInfo[_postId].buyStatus = 2;
        postInfo[_postId].sellValue = 0;
        
        // clear all earlier bids i.e. fresh start
        userBid[lastBidder][_postId] = 0;
        delete postLastBidder[_postId];

        // tranfer post amount to the owner
        // (bool sent) = rewardToken.transfer(owner, _price);    // transfer post amount to the last bidder
        (bool sent,) = owner.call{value: _price}("");
        require(sent, "transfer fail");


        //tranferr nft
        _transfer(owner, lastBidder, _postId);
        emit BiddableTokenPurchased(owner, lastBidder, _price, _postId);
    }

    function buyPost(uint256 _postId) external payable isValidUser{
        uint256 _price = msg.value;
        PostInfo memory _postInfo = postInfo[_postId];
        address owner = idToOwner[_postId];
        address user = msg.sender;
        require(
            _postInfo.buyStatus == 0,
            "non-buyable post's purchase call"
        );
        // require(_postInfo.sellValue >= 0, "post is not for sale yet");
        require(_postId <= maxTokenId, "invalid post id for BUYABBLE item");
        require(_price >= _postInfo.sellValue , "price mistmatch");
        //change contract level ownership of the token
        idToOwner[_postId] = user;
        // changed sell and price tag to avoid bot purchase, user has to set the price after purchasing
        postInfo[_postId].buyStatus = 2;
        postInfo[_postId].sellValue = 0;
        //approval is mandatory first
        // (bool sent) = rewardToken.transferFrom(user, owner, _postInfo.sellValue);
        (bool sent,) = owner.call{value: _price}("");

        require(sent, "amount transfer fail");
        _transfer(owner, user, _postId);
        emit PostSold(owner, user, _price, _postId);
    }

    

    function mint(uint8 _buyStatus, uint256 _sellValue, uint256 _bidDuration, string memory tokenURI_) external isValidUser {
        address user = msg.sender;
        bytes memory b = bytes(tokenURI_);

        require(b.length != 0, "Token URI can't be empty");
        require(_buyStatus < 3, "Invalid status");
        if(_buyStatus == 2) require(_sellValue == 0, "sell value must be 0 for non sellable items");
        if(_buyStatus == 1) require(_bidDuration > block.timestamp, "Bidding time should be of future");

        _safeMint(user, maxTokenId);
        _setTokenURI(maxTokenId, tokenURI_);
        emit PostCreated(maxTokenId,user,tokenURI_, _buyStatus, _sellValue);

        idToOwner[maxTokenId] = user;
        postInfo[maxTokenId] = PostInfo(_buyStatus, _sellValue, _bidDuration, tokenURI_);
        userPostIds[user].push(maxTokenId);
        
        maxTokenId++;
    }

}
