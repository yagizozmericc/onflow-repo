// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IOnFlowVault {
    function initializeVault(
        address _asset,
        address _borrower,
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        uint256 _fundingDuration,
        uint256[] memory _installmentDueDates,
        uint256[] memory _installmentAmounts,
        address _owner
    ) external;
}

contract VaultFactory is Ownable {
    address public implementation;
    address[] public allVaults;
    mapping(address => address[]) public vaultsByBorrower;

    event VaultCreated(address indexed vault, address indexed borrower);

    constructor(address _implementation, address _initialOwner) Ownable(_initialOwner) {
        implementation = _implementation;
    }

    function createVault(
        address _asset,
        address _borrower,
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        uint256 _fundingDuration,
        uint256[] memory _installmentDueDates,
        uint256[] memory _installmentAmounts
    ) external onlyOwner returns (address) {
        address clone = Clones.clone(implementation);

        IOnFlowVault(clone).initializeVault(
            _asset,
            _borrower,
            _name,
            _symbol,
            _cap,
            _fundingDuration,
            _installmentDueDates,
            _installmentAmounts,
            owner() // factory'nin sahibi vault'un da sahibi olur
        );

        allVaults.push(clone);
        vaultsByBorrower[_borrower].push(clone);

        emit VaultCreated(clone, _borrower);
        return clone;
    }

    function getAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

    function getVaultsByBorrower(address borrower) external view returns (address[] memory) {
        return vaultsByBorrower[borrower];
    }
}
