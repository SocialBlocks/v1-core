//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Verify {
    // this function will compute the hash and produce & return signer address
    // function verify(
    //     address _signer,
    //     bytes memory _signature,
    //     bytes32 signedMessageHash
    // ) public pure returns (bool) {
    //     return recoverSigner(signedMessageHash, _signature) == _signer;
    // }

    /**
     * @dev Verifies the on-chain reward claim. claimId is incremented every time a claim is made.
       and it is keept private so that no message hash and signature can be use twice.
     * @param signer admin address.
     * @param signature signature signed by admin for likes reward.
     * @param likesCount total accumulated likes so far.
     * @return True if the reward claim is verified. False otherwise.
     */
    function verify(
        address signer,
        bytes memory signature,
        uint256 likesCount,
        uint256 claimId
    ) public view returns (bool) {
        bytes32 _messageHash = keccak256(
            abi.encodePacked(likesCount, msg.sender, claimId)
        );
        bytes32 _signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
        return recoverSigner(_signedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _signedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(_signature.length == 65, "invalid signature length"); // 65 bytes = 32 bytes for r + 32 bytes for s + 1 byte for v

        // add(x, y)        -> x + y
        // add(_sig, 32)    -> skips firt 32 bytes
        // mload(p) loads next 32 bytes starting at the memory address p

        assembly {
            r := mload(add(_signature, 32)) //signature
            s := mload(add(_signature, 64)) //value
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_signedMessageHash, v, r, s);
    }
}
