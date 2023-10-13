// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./SismoWallet.sol";

contract SismoWalletFactory {
    SismoWallet public immutable walletImplementation;

    constructor(IEntryPoint _entryPoint) {
        walletImplementation = new SismoWallet(_entryPoint);
    }

    function createAccount(address owner, uint256 salt) public returns (SismoWallet ret) {
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return SismoWallet(payable(addr));
        }
        ret = SismoWallet(
            payable(
                new ERC1967Proxy{salt : bytes32(salt)}(
                address(walletImplementation),
                abi.encodeCall(SismoWallet.initialize, (owner))
                )
            )
        );
    }

    function getAddress(address owner, uint256 salt) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(address(walletImplementation), abi.encodeCall(SismoWallet.initialize, (owner)))
                )
            )
        );
    }
}
