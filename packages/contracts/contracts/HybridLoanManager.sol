// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IAggregatorV3.sol";

contract HybridLoanManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant RATE_DECIMALS = 1e8;
    uint256 public constant LTV_MAX_BPS = 7000;
    uint256 public constant LIQ_THRESHOLD_BPS = 9500;
    uint256 public constant FX_STALE_SECONDS = 60 minutes;
    uint256 public constant MAX_FX_CHANGE_BPS = 200;

    enum Status {
        PAYOUT_PENDING,
        ACTIVE,
        REPAY_REQUESTED,
        CLOSED,
        LIQUIDATED
    }

    struct Position {
        uint256 positionId;
        address borrower;
        address collateralToken;
        uint256 collateralAmount;
        uint256 principalIDR;
        uint32 aprBps;
        uint40 startTimestamp;
        Status status;
        uint40 payoutDeadline;
        bytes32 payoutRefHash;
        bytes32 repayRefHash;
        bytes32 offchainRefHash;
    }

    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) private positionsByUser;
    uint256 public nextPositionId;

    address public treasury;
    IERC20 public usdcToken;
    uint8 public usdcDecimals;
    IAggregatorV3 public ethUsdOracle;

    uint256 public usdIdrRate;
    uint256 public usdIdrUpdatedAt;
    uint32 public aprBps;
    uint40 public payoutDeadlineSeconds;

    event LoanRequested(
        uint256 indexed positionId,
        address indexed borrower,
        address indexed token,
        uint256 collateralAmount,
        uint256 principalIDR,
        bytes32 offchainRefHash
    );
    event Cancelled(uint256 indexed positionId);
    event PayoutConfirmed(uint256 indexed positionId, bytes32 payoutRefHash);
    event RepayRequested(uint256 indexed positionId, bytes32 repayRefHash);
    event RepayConfirmed(uint256 indexed positionId, bytes32 repayRefHash);
    event CollateralWithdrawn(uint256 indexed positionId);
    event Liquidated(
        uint256 indexed positionId,
        uint256 seizedAmount,
        uint256 ltvBps,
        uint256 ethUsd,
        uint256 usdIdr,
        uint256 debtIdr,
        uint256 collateralValueIdr
    );
    event UsdIdrRateUpdated(uint256 rate, uint256 updatedAt);
    event AprUpdated(uint32 aprBps);
    event PayoutDeadlineUpdated(uint40 secondsValue);
    event TreasuryUpdated(address treasury);
    event EthUsdOracleUpdated(address oracle);
    event UsdcTokenUpdated(address token);

    error FxRateStale();
    error InvalidRateChange();
    error InvalidAmount();
    error NotBorrower();
    error InvalidStatus();
    error PayoutDeadlineNotReached();
    error MaxBorrowExceeded();
    error LtvTooLow();

    constructor(
        address _treasury,
        address _usdcToken,
        address _ethUsdOracle,
        uint32 _aprBps,
        uint40 _payoutDeadlineSeconds,
        uint256 _usdIdrRate
    ) Ownable(msg.sender) {
        require(_treasury != address(0), "TREASURY_ZERO");
        require(_usdcToken != address(0), "USDC_ZERO");
        require(_ethUsdOracle != address(0), "ORACLE_ZERO");

        treasury = _treasury;
        usdcToken = IERC20(_usdcToken);
        usdcDecimals = IERC20Metadata(_usdcToken).decimals();
        ethUsdOracle = IAggregatorV3(_ethUsdOracle);
        aprBps = _aprBps;
        payoutDeadlineSeconds = _payoutDeadlineSeconds;

        if (_usdIdrRate > 0) {
            usdIdrRate = _usdIdrRate;
            usdIdrUpdatedAt = block.timestamp;
            emit UsdIdrRateUpdated(_usdIdrRate, block.timestamp);
        }
    }

    receive() external payable {}

    function createRequestETH(uint256 requestedIDR, bytes32 offchainRefHash) external payable nonReentrant {
        if (msg.value == 0 || requestedIDR == 0) revert InvalidAmount();
        _requireFreshFx();

        uint256 collateralValueIdr = _getCollateralValueIdrFromEth(msg.value);
        uint256 maxBorrowIdr = (collateralValueIdr * LTV_MAX_BPS) / 10000;
        if (requestedIDR > maxBorrowIdr) revert MaxBorrowExceeded();

        uint256 positionId = nextPositionId++;
        positions[positionId] = Position({
            positionId: positionId,
            borrower: msg.sender,
            collateralToken: address(0),
            collateralAmount: msg.value,
            principalIDR: requestedIDR,
            aprBps: aprBps,
            startTimestamp: 0,
            status: Status.PAYOUT_PENDING,
            payoutDeadline: uint40(block.timestamp + payoutDeadlineSeconds),
            payoutRefHash: bytes32(0),
            repayRefHash: bytes32(0),
            offchainRefHash: offchainRefHash
        });
        positionsByUser[msg.sender].push(positionId);

        emit LoanRequested(
            positionId,
            msg.sender,
            address(0),
            msg.value,
            requestedIDR,
            offchainRefHash
        );
    }

    function createRequestUSDC(
        uint256 usdcAmount,
        uint256 requestedIDR,
        bytes32 offchainRefHash
    ) external nonReentrant {
        if (usdcAmount == 0 || requestedIDR == 0) revert InvalidAmount();
        _requireFreshFx();

        uint256 collateralValueIdr = _getCollateralValueIdrFromUsdc(usdcAmount);
        uint256 maxBorrowIdr = (collateralValueIdr * LTV_MAX_BPS) / 10000;
        if (requestedIDR > maxBorrowIdr) revert MaxBorrowExceeded();

        usdcToken.safeTransferFrom(msg.sender, address(this), usdcAmount);

        uint256 positionId = nextPositionId++;
        positions[positionId] = Position({
            positionId: positionId,
            borrower: msg.sender,
            collateralToken: address(usdcToken),
            collateralAmount: usdcAmount,
            principalIDR: requestedIDR,
            aprBps: aprBps,
            startTimestamp: 0,
            status: Status.PAYOUT_PENDING,
            payoutDeadline: uint40(block.timestamp + payoutDeadlineSeconds),
            payoutRefHash: bytes32(0),
            repayRefHash: bytes32(0),
            offchainRefHash: offchainRefHash
        });
        positionsByUser[msg.sender].push(positionId);

        emit LoanRequested(
            positionId,
            msg.sender,
            address(usdcToken),
            usdcAmount,
            requestedIDR,
            offchainRefHash
        );
    }

    function cancelIfNotPaid(uint256 positionId) external nonReentrant {
        Position storage position = positions[positionId];
        if (position.borrower != msg.sender) revert NotBorrower();
        if (position.status != Status.PAYOUT_PENDING) revert InvalidStatus();
        if (block.timestamp <= position.payoutDeadline) revert PayoutDeadlineNotReached();

        position.status = Status.CLOSED;
        _transferCollateral(position.borrower, position.collateralToken, position.collateralAmount);
        emit Cancelled(positionId);
    }

    function requestRepay(uint256 positionId, bytes32 repayRefHash) external {
        Position storage position = positions[positionId];
        if (position.borrower != msg.sender) revert NotBorrower();
        if (position.status != Status.ACTIVE) revert InvalidStatus();

        position.status = Status.REPAY_REQUESTED;
        position.repayRefHash = repayRefHash;
        emit RepayRequested(positionId, repayRefHash);
    }

    function withdrawCollateral(uint256 positionId) external nonReentrant {
        Position storage position = positions[positionId];
        if (position.borrower != msg.sender) revert NotBorrower();
        if (position.status != Status.CLOSED) revert InvalidStatus();

        position.status = Status.CLOSED;
        _transferCollateral(position.borrower, position.collateralToken, position.collateralAmount);
        emit CollateralWithdrawn(positionId);
    }

    function confirmPayout(uint256 positionId, bytes32 payoutRefHash) external onlyOwner {
        Position storage position = positions[positionId];
        if (position.status != Status.PAYOUT_PENDING) revert InvalidStatus();

        position.status = Status.ACTIVE;
        position.startTimestamp = uint40(block.timestamp);
        position.payoutRefHash = payoutRefHash;
        emit PayoutConfirmed(positionId, payoutRefHash);
    }

    function confirmRepay(uint256 positionId, bytes32 repayRefHash) external onlyOwner {
        Position storage position = positions[positionId];
        if (position.status != Status.REPAY_REQUESTED) revert InvalidStatus();

        position.status = Status.CLOSED;
        position.repayRefHash = repayRefHash;
        emit RepayConfirmed(positionId, repayRefHash);
    }

    function liquidate(uint256 positionId) external onlyOwner nonReentrant {
        Position storage position = positions[positionId];
        if (
            position.status != Status.ACTIVE &&
            position.status != Status.REPAY_REQUESTED
        ) revert InvalidStatus();
        _requireFreshFx();

        uint256 collateralValueIdr = getCollateralValueIDR(positionId);
        uint256 debtIdr = getDebtNow(positionId);
        uint256 ltvBps = collateralValueIdr == 0
            ? type(uint256).max
            : (debtIdr * 10000) / collateralValueIdr;
        if (ltvBps < LIQ_THRESHOLD_BPS) revert LtvTooLow();

        position.status = Status.LIQUIDATED;
        _transferCollateral(treasury, position.collateralToken, position.collateralAmount);

        emit Liquidated(
            positionId,
            position.collateralAmount,
            ltvBps,
            getEthUsd(),
            usdIdrRate,
            debtIdr,
            collateralValueIdr
        );
    }

    function setAPR(uint32 newAprBps) external onlyOwner {
        aprBps = newAprBps;
        emit AprUpdated(newAprBps);
    }

    function setPayoutDeadline(uint40 secondsValue) external onlyOwner {
        payoutDeadlineSeconds = secondsValue;
        emit PayoutDeadlineUpdated(secondsValue);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "TREASURY_ZERO");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function setUsdIdrRate(uint256 newRate) external onlyOwner {
        if (newRate == 0) revert InvalidAmount();
        if (usdIdrRate > 0) {
            uint256 maxDelta = (usdIdrRate * MAX_FX_CHANGE_BPS) / 10000;
            uint256 upper = usdIdrRate + maxDelta;
            uint256 lower = usdIdrRate - maxDelta;
            if (newRate > upper || newRate < lower) revert InvalidRateChange();
        }
        usdIdrRate = newRate;
        usdIdrUpdatedAt = block.timestamp;
        emit UsdIdrRateUpdated(newRate, block.timestamp);
    }

    function setEthUsdOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "ORACLE_ZERO");
        ethUsdOracle = IAggregatorV3(newOracle);
        emit EthUsdOracleUpdated(newOracle);
    }

    function setUsdcToken(address newToken) external onlyOwner {
        require(newToken != address(0), "USDC_ZERO");
        usdcToken = IERC20(newToken);
        usdcDecimals = IERC20Metadata(newToken).decimals();
        emit UsdcTokenUpdated(newToken);
    }

    function getDebtNow(uint256 positionId) public view returns (uint256) {
        Position memory position = positions[positionId];
        if (position.startTimestamp == 0) {
            return position.principalIDR;
        }
        uint256 elapsed = block.timestamp - position.startTimestamp;
        uint256 yearlyInterest = (position.principalIDR * position.aprBps) / 10000;
        uint256 interest = Math.mulDiv(yearlyInterest, elapsed, 365 days);
        return position.principalIDR + interest;
    }

    function getCollateralValueIDR(uint256 positionId) public view returns (uint256) {
        Position memory position = positions[positionId];
        return _getCollateralValueIdr(position.collateralAmount, position.collateralToken);
    }

    function getCollateralValueIDRForToken(
        uint256 collateralAmount,
        address token
    ) public view returns (uint256) {
        return _getCollateralValueIdr(collateralAmount, token);
    }

    function getMaxBorrowIDR(uint256 collateralAmount, address token) external view returns (uint256) {
        uint256 valueIdr = _getCollateralValueIdr(collateralAmount, token);
        return (valueIdr * LTV_MAX_BPS) / 10000;
    }

    function getLtvNow(uint256 positionId) external view returns (uint256) {
        uint256 collateralValueIdr = getCollateralValueIDR(positionId);
        uint256 debtIdr = getDebtNow(positionId);
        if (collateralValueIdr == 0) return type(uint256).max;
        return (debtIdr * 10000) / collateralValueIdr;
    }

    function getUserPositions(address user) external view returns (uint256[] memory) {
        return positionsByUser[user];
    }

    function isFxRateStale() public view returns (bool) {
        if (usdIdrUpdatedAt == 0) return true;
        return block.timestamp - usdIdrUpdatedAt > FX_STALE_SECONDS;
    }

    function getEthUsd() public view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = ethUsdOracle.latestRoundData();
        require(answer > 0, "INVALID_ETH_USD");
        require(updatedAt > 0, "NO_ETH_USD");
        uint256 price = uint256(answer);
        uint8 dec = ethUsdOracle.decimals();
        if (dec > 8) {
            price = price / (10 ** (dec - 8));
        } else if (dec < 8) {
            price = price * (10 ** (8 - dec));
        }
        return price;
    }

    function _requireFreshFx() internal view {
        if (isFxRateStale()) revert FxRateStale();
    }

    function _getCollateralValueIdr(uint256 collateralAmount, address token) internal view returns (uint256) {
        if (token == address(0)) {
            return _getCollateralValueIdrFromEth(collateralAmount);
        }
        if (token == address(usdcToken)) {
            return _getCollateralValueIdrFromUsdc(collateralAmount);
        }
        return 0;
    }

    function _getCollateralValueIdrFromEth(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethUsd = getEthUsd(); // 1e8
        uint256 usdValueE8 = Math.mulDiv(ethAmount, ethUsd, 1e18);
        uint256 idrValueE8 = Math.mulDiv(usdValueE8, usdIdrRate, RATE_DECIMALS);
        return idrValueE8 / RATE_DECIMALS;
    }

    function _getCollateralValueIdrFromUsdc(uint256 usdcAmount) internal view returns (uint256) {
        uint256 usdValueE8 = Math.mulDiv(usdcAmount, RATE_DECIMALS, 10 ** usdcDecimals);
        uint256 idrValueE8 = Math.mulDiv(usdValueE8, usdIdrRate, RATE_DECIMALS);
        return idrValueE8 / RATE_DECIMALS;
    }

    function _transferCollateral(address to, address token, uint256 amount) internal {
        if (token == address(0)) {
            (bool success,) = payable(to).call{value: amount}("");
            require(success, "ETH_TRANSFER_FAIL");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}
