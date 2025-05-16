// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OnFlowSingleBorrowerVault is ERC4626, Ownable, ReentrancyGuard {
    enum VaultState { CapitalFormation, CreditLive, Closed }
    VaultState public state;

    address public borrower;
    uint256 public cap;
    uint256 public capitalFormationDeadline;
    uint256 public creditEndTimestamp;
    bool public isStopped;
    bool public isInDefault;

    mapping(address => bool) public hasClaimed;

    event VaultStopped();
    event VaultResumed();
    event Borrowed(address borrower, uint256 amount);
    event Claimed(address investor, uint256 amount);
    event ForceDefault();

    modifier onlyDuringCapitalFormation() {
        require(state == VaultState.CapitalFormation, "Not in formation");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Not admin");
        _;
    }

    modifier vaultActive() {
        require(!isStopped, "Vault is stopped");
        _;
    }

    constructor(
        address _asset,
        address _borrower,
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        uint256 _capitalFormationDeadline,
        uint256 _creditEndTimestamp,
        address _initialOwner
    ) ERC20(_name, _symbol) ERC4626(IERC20(_asset)) Ownable(_initialOwner) {
        borrower = _borrower;
        cap = _cap;
        capitalFormationDeadline = _capitalFormationDeadline;
        creditEndTimestamp = _creditEndTimestamp;
        state = VaultState.CapitalFormation;
    }

    function deposit(uint256 assets, address receiver) 
        public 
        override 
        vaultActive 
        onlyDuringCapitalFormation 
        returns (uint256)
    {
        require(totalAssets() + assets <= cap, "Cap exceeded");
        return super.deposit(assets, receiver);
    }

    function borrow() external nonReentrant vaultActive {
        require(msg.sender == borrower, "Only borrower");
        require(state == VaultState.CapitalFormation, "Not borrowable now");
        require(
            block.timestamp >= capitalFormationDeadline || totalAssets() >= cap,
            "Capital formation ongoing"
        );

        state = VaultState.CreditLive;
        uint256 amount = totalAssets();
        IERC20(asset()).transfer(borrower, amount);
        emit Borrowed(borrower, amount);
    }

    function stopVault() external onlyAdmin {
        isStopped = true;
        emit VaultStopped();
    }

    function resumeVault() external onlyAdmin {
        isStopped = false;
        emit VaultResumed();
    }

    function forceDefault() external onlyAdmin {
        require(state == VaultState.CreditLive, "Not during credit phase");
        require(!isInDefault, "Already defaulted");
        isInDefault = true;
        emit ForceDefault();
        state = VaultState.Closed;
    }

    function claim(uint256 shares) external nonReentrant {
        require(state == VaultState.CreditLive, "Not credit phase");
        require(block.timestamp >= creditEndTimestamp, "Credit period not ended");
        require(!isInDefault, "Loan defaulted");
        require(!hasClaimed[msg.sender], "Already claimed");

        uint256 amount = previewRedeem(shares);
        _burn(msg.sender, shares);
        IERC20(asset()).transfer(msg.sender, amount);

        hasClaimed[msg.sender] = true;
        emit Claimed(msg.sender, amount);

        if (totalSupply() == 0) {
            state = VaultState.Closed;
        }
    }

    function getVaultInfo() external view returns (
        VaultState,
        address borrower_,
        uint256 cap_,
        uint256 capitalFormationDeadline_,
        uint256 creditEndTimestamp_,
        bool isStopped_,
        bool isInDefault_
    ) {
        return (
            state,
            borrower,
            cap,
            capitalFormationDeadline,
            creditEndTimestamp,
            isStopped,
            isInDefault
        );
    }
}
