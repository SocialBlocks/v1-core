// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AccountCreation is ERC721Enumerable {
     struct UserInfo {
        string userName;
        string displayName;
        string bio;
        string image;
    }
    // Mapping from user address to user info, only displayName and Bio updatable
    mapping(address => UserInfo) public userInfo;

    // Mapping from address to username
    mapping(address => string) public userName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    // event AccountCreated(string newName);
    // event BioChange(string bio);
    event PostCreated(uint id, address sender, string uri, uint8 buyStatus, uint256 sellValue);
    event InfoChanged(string displayName, string bio, string image);
    event AccountCreated(address user, string userName, string displayName, string bio, string image);
    event PostDetailsChanged(uint256 postId, uint8 status,  uint256 price, uint256 bidDuration);
    event PostRewardClaimed(address user, uint256 postId,  uint256 reward);
    event BiddableTokenPurchased(address oldOwner, address newOwner, uint256 amount, uint256 id);
    event BidPlaced(address bidder, uint256 postId, uint256 bidAmount );
    event PostSold(address from, address to, uint256 amount, uint256 id);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}


    function updateUserInfo(UserInfo memory _userInfo) external {
        address user = msg.sender;
        require(
            bytes(userName[user]).length != 0,
            "Undefined user"
        );
        require(
            keccak256(abi.encodePacked(userInfo[user].userName)) == keccak256(abi.encodePacked(_userInfo.userName)), 
            "Username must be unique"
        );
        userInfo[user] = _userInfo;
        emit InfoChanged(_userInfo.displayName, _userInfo.bio, _userInfo.image);
    }

    function createAccount
    (
        UserInfo memory _userInfo
    ) public virtual {
        address user = msg.sender;
        require(
            bytes(userName[user]).length == 0,
            "Account already created"
        );

        require(validateName(_userInfo.userName), "Not a valid new name");
        require(!isNameReserved(_userInfo.userName), "Username already exists");
        _nameReserved[toLower(_userInfo.userName)] = true;
        userInfo[user] = _userInfo;
        
        userName[user] = _userInfo.userName;
        emit AccountCreated(user, _userInfo.userName, _userInfo.displayName, _userInfo.bio, _userInfo.image);
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function isAddressReserved(address _address)
        public
        view
        returns (string memory)
    {
        return userName[_address];
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            ) return false;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
