// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OnFlowVault is Initializable, ERC4626Upgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
    using Math for uint256;

    enum VaultState { CapitalFormation, LiveCredit, Ended }
    VaultState public currentState;

    address public borrower;
    uint256 public cap;
    uint256 public fundingDeadline;

    bool public finalized;
    bool public approvedToReleaseFunds;
    bool public fullyRepaid;
    bool public isInDefault;
    bool public fundsWithdrawnByBorrower;
    bool public allowClaiming;
    uint256 public totalRepaidAmount;

    mapping(address => bool) public claimed;

    string public vaultName;
    string public vaultSymbol;

    struct Installment {
        uint256 dueDate;
        uint256 amount;
        bool paid;
    }

    Installment[] public repaymentSchedule;

    event Deposited(address indexed user, uint256 amount);
    event InstallmentRepaid(uint256 index, uint256 amount);
    event Finalized();
    event Claimed(address indexed user, uint256 amount);
    event Defaulted(uint256 index);
    event ClaimingEnabled();

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
    ) external initializer {
        require(_installmentDueDates.length == _installmentAmounts.length, "Mismatched arrays");
        for (uint256 i = 1; i < _installmentDueDates.length; i++) {
            require(_installmentDueDates[i] > _installmentDueDates[i - 1], "Dates must be sorted");
        }

        borrower = _borrower;
        cap = _cap;
        fundingDeadline = block.timestamp + _fundingDuration;
        currentState = VaultState.CapitalFormation;

        vaultName = _name;
        vaultSymbol = _symbol;

        __Ownable2Step_init();
        __ERC20_init(_name, _symbol);
        __ERC4626_init(IERC20Metadata(_asset));
        __ReentrancyGuard_init();
        _transferOwnership(_owner);

        for (uint256 i = 0; i < _installmentDueDates.length; i++) {
            repaymentSchedule.push(Installment({
                dueDate: _installmentDueDates[i],
                amount: _installmentAmounts[i],
                paid: false
            }));
        }
    }

    modifier onlyBeforeDeadline() {
        require(block.timestamp <= fundingDeadline, "Funding closed");
        require(currentState == VaultState.CapitalFormation, "Not in capital formation");
        _;
    }

    modifier onlyAfterDeadline() {
        require(block.timestamp > fundingDeadline, "Funding ongoing");
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "Not borrower");
        _;
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        onlyBeforeDeadline
        nonReentrant
        returns (uint256)
    {
        require(totalAssets() + assets <= cap, "Cap reached");
        uint256 shares = super.deposit(assets, receiver);
        emit Deposited(receiver, assets);
        return shares;
    }

    function approveFundRelease() external onlyOwner {
        approvedToReleaseFunds = true;
    }

    function finalize() external onlyAfterDeadline nonReentrant {
        require(currentState == VaultState.CapitalFormation, "Not in funding stage");
        require(!finalized, "Already finalized");
        require(approvedToReleaseFunds, "Not approved by admin");
        require(totalAssets() >= cap, "Funding cap not reached");

        finalized = true;
        uint256 balance = totalAssets();
        require(balance > 0, "No funds");
        require(!fundsWithdrawnByBorrower, "Already withdrawn");

        fundsWithdrawnByBorrower = true;
        IERC20(asset()).transfer(borrower, balance);
        currentState = VaultState.LiveCredit;
        emit Finalized();
    }

    function repayInstallment(uint256 index) external onlyBorrower nonReentrant {
        require(finalized, "Not finalized");
        require(currentState == VaultState.LiveCredit, "Not in live period");
        require(index < repaymentSchedule.length, "Invalid index");

        Installment storage inst = repaymentSchedule[index];
        require(!inst.paid, "Already paid");
        require(block.timestamp <= inst.dueDate, "Past due");

        IERC20(asset()).transferFrom(msg.sender, address(this), inst.amount);
        inst.paid = true;
        totalRepaidAmount += inst.amount;

        emit InstallmentRepaid(index, inst.amount);

        bool allPaid = true;
        for (uint256 i = 0; i < repaymentSchedule.length; i++) {
            if (!repaymentSchedule[i].paid) {
                allPaid = false;
                break;
            }
        }

        fullyRepaid = allPaid;
        if (fullyRepaid) {
            currentState = VaultState.Ended;
        }
    }

    function checkDefaultStatus() public {
        if (isInDefault || fullyRepaid) return;

        for (uint256 i = 0; i < repaymentSchedule.length; i++) {
            if (!repaymentSchedule[i].paid && block.timestamp > repaymentSchedule[i].dueDate) {
                isInDefault = true;
                emit Defaulted(i);
                break;
            }
        }
    }

    function forceDefault() external onlyOwner {
        require(currentState == VaultState.LiveCredit, "Can only default during credit period");
        require(!fullyRepaid, "Already repaid");
        isInDefault = true;
    }

    function enableClaiming() external onlyOwner {
        require(currentState == VaultState.Ended, "Vault not ended");
        require(fullyRepaid, "Loan not fully repaid");
        allowClaiming = true;
        emit ClaimingEnabled();
    }

    function claim() external nonReentrant {
        checkDefaultStatus();
        require(currentState == VaultState.Ended, "Not ended");
        require(fullyRepaid, "Not fully repaid");
        require(!isInDefault, "Loan defaulted");
        require(!claimed[msg.sender], "Already claimed");

        require(allowClaiming, "Claiming not allowed");

        uint256 userShares = balanceOf(msg.sender);
        require(userShares > 0, "No shares");

        uint256 payout = (totalRepaidAmount * userShares) / totalSupply();
        claimed[msg.sender] = true;
        _burn(msg.sender, userShares);
        IERC20(asset()).transfer(msg.sender, payout);

        emit Claimed(msg.sender, payout);
    }

    function getInstallmentCount() external view returns (uint256) {
        return repaymentSchedule.length;
    }

    function getInstallment(uint256 index)
        external
        view
        returns (uint256 dueDate, uint256 amount, bool paid)
    {
        Installment storage inst = repaymentSchedule[index];
        return (inst.dueDate, inst.amount, inst.paid);
    }

    function getFullRepaymentSchedule() external view returns (Installment[] memory) {
        return repaymentSchedule;
    }

    function getVaultMetadata()
        external
        view
        returns (
            address borrower_,
            uint256 cap_,
            uint256 deadline_,
            string memory name_,
            string memory symbol_,
            VaultState state_
        )
    {
        return (borrower, cap, fundingDeadline, vaultName, vaultSymbol, currentState);
    }

    function redeem(uint256, address, address) public pure override returns (uint256) {
        revert("Withdrawals disabled");
    }

    function withdraw(uint256, address, address) public pure override returns (uint256) {
        revert("Withdrawals disabled");
    }
}