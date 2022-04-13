// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//create ERC20 token contract
contract SocialBlocksToken is ERC20 {
  mapping(address => bool) public admins;
  
  //modifiers
  modifier _onlyAdmin() {
    require(admins[msg.sender], "caller is not the admin");
    _;
  }

  //CONSTRUCTOR
  constructor() ERC20("Social Blocks Token", "SBT"){
    admins[msg.sender] = true;
  }

  //only admin functions
  function addAdmin(address _admin) external _onlyAdmin{
    admins[_admin] = true;
  }
  function removeAdmin(address _admin) external _onlyAdmin{
    admins[_admin] = false;
  }
  function mint(address _to, uint _amount) external _onlyAdmin{
    _mint(_to, _amount);
  }
  function burn(address _account, uint _amount) external _onlyAdmin{
    _burn(_account, _amount);
  }
  
}
