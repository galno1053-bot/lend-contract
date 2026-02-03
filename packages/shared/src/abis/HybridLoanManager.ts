export const hybridLoanManagerAbi = [
  {
    type: "constructor",
    inputs: [
      { name: "_treasury", type: "address" },
      { name: "_usdcToken", type: "address" },
      { name: "_ethUsdOracle", type: "address" },
      { name: "_aprBps", type: "uint32" },
      { name: "_payoutDeadlineSeconds", type: "uint40" },
      { name: "_usdIdrRate", type: "uint256" }
    ]
  },
  {
    type: "event",
    name: "LoanRequested",
    inputs: [
      { indexed: true, name: "positionId", type: "uint256" },
      { indexed: true, name: "borrower", type: "address" },
      { indexed: true, name: "token", type: "address" },
      { indexed: false, name: "collateralAmount", type: "uint256" },
      { indexed: false, name: "principalIDR", type: "uint256" },
      { indexed: false, name: "offchainRefHash", type: "bytes32" }
    ]
  },
  {
    type: "event",
    name: "Cancelled",
    inputs: [{ indexed: true, name: "positionId", type: "uint256" }]
  },
  {
    type: "event",
    name: "PayoutConfirmed",
    inputs: [
      { indexed: true, name: "positionId", type: "uint256" },
      { indexed: false, name: "payoutRefHash", type: "bytes32" }
    ]
  },
  {
    type: "event",
    name: "RepayRequested",
    inputs: [
      { indexed: true, name: "positionId", type: "uint256" },
      { indexed: false, name: "repayRefHash", type: "bytes32" }
    ]
  },
  {
    type: "event",
    name: "RepayConfirmed",
    inputs: [
      { indexed: true, name: "positionId", type: "uint256" },
      { indexed: false, name: "repayRefHash", type: "bytes32" }
    ]
  },
  {
    type: "event",
    name: "CollateralWithdrawn",
    inputs: [{ indexed: true, name: "positionId", type: "uint256" }]
  },
  {
    type: "event",
    name: "Liquidated",
    inputs: [
      { indexed: true, name: "positionId", type: "uint256" },
      { indexed: false, name: "seizedAmount", type: "uint256" },
      { indexed: false, name: "ltvBps", type: "uint256" },
      { indexed: false, name: "ethUsd", type: "uint256" },
      { indexed: false, name: "usdIdr", type: "uint256" },
      { indexed: false, name: "debtIdr", type: "uint256" },
      { indexed: false, name: "collateralValueIdr", type: "uint256" }
    ]
  },
  {
    type: "function",
    name: "createRequestETH",
    stateMutability: "payable",
    inputs: [
      { name: "requestedIDR", type: "uint256" },
      { name: "offchainRefHash", type: "bytes32" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "createRequestUSDC",
    stateMutability: "nonpayable",
    inputs: [
      { name: "usdcAmount", type: "uint256" },
      { name: "requestedIDR", type: "uint256" },
      { name: "offchainRefHash", type: "bytes32" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "cancelIfNotPaid",
    stateMutability: "nonpayable",
    inputs: [{ name: "positionId", type: "uint256" }],
    outputs: []
  },
  {
    type: "function",
    name: "requestRepay",
    stateMutability: "nonpayable",
    inputs: [
      { name: "positionId", type: "uint256" },
      { name: "repayRefHash", type: "bytes32" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "withdrawCollateral",
    stateMutability: "nonpayable",
    inputs: [{ name: "positionId", type: "uint256" }],
    outputs: []
  },
  {
    type: "function",
    name: "confirmPayout",
    stateMutability: "nonpayable",
    inputs: [
      { name: "positionId", type: "uint256" },
      { name: "payoutRefHash", type: "bytes32" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "confirmRepay",
    stateMutability: "nonpayable",
    inputs: [
      { name: "positionId", type: "uint256" },
      { name: "repayRefHash", type: "bytes32" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "liquidate",
    stateMutability: "nonpayable",
    inputs: [{ name: "positionId", type: "uint256" }],
    outputs: []
  },
  {
    type: "function",
    name: "setAPR",
    stateMutability: "nonpayable",
    inputs: [{ name: "newAprBps", type: "uint32" }],
    outputs: []
  },
  {
    type: "function",
    name: "setPayoutDeadline",
    stateMutability: "nonpayable",
    inputs: [{ name: "secondsValue", type: "uint40" }],
    outputs: []
  },
  {
    type: "function",
    name: "setTreasury",
    stateMutability: "nonpayable",
    inputs: [{ name: "newTreasury", type: "address" }],
    outputs: []
  },
  {
    type: "function",
    name: "setUsdIdrRate",
    stateMutability: "nonpayable",
    inputs: [{ name: "newRate", type: "uint256" }],
    outputs: []
  },
  {
    type: "function",
    name: "setEthUsdOracle",
    stateMutability: "nonpayable",
    inputs: [{ name: "newOracle", type: "address" }],
    outputs: []
  },
  {
    type: "function",
    name: "setUsdcToken",
    stateMutability: "nonpayable",
    inputs: [{ name: "newToken", type: "address" }],
    outputs: []
  },
  {
    type: "function",
    name: "getDebtNow",
    stateMutability: "view",
    inputs: [{ name: "positionId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "getCollateralValueIDR",
    stateMutability: "view",
    inputs: [{ name: "positionId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "getCollateralValueIDRForToken",
    stateMutability: "view",
    inputs: [
      { name: "collateralAmount", type: "uint256" },
      { name: "token", type: "address" }
    ],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "getMaxBorrowIDR",
    stateMutability: "view",
    inputs: [
      { name: "collateralAmount", type: "uint256" },
      { name: "token", type: "address" }
    ],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "getLtvNow",
    stateMutability: "view",
    inputs: [{ name: "positionId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "getUserPositions",
    stateMutability: "view",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256[]" }]
  },
  {
    type: "function",
    name: "isFxRateStale",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    type: "function",
    name: "getEthUsd",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "positions",
    stateMutability: "view",
    inputs: [{ name: "", type: "uint256" }],
    outputs: [
      { name: "positionId", type: "uint256" },
      { name: "borrower", type: "address" },
      { name: "collateralToken", type: "address" },
      { name: "collateralAmount", type: "uint256" },
      { name: "principalIDR", type: "uint256" },
      { name: "aprBps", type: "uint32" },
      { name: "startTimestamp", type: "uint40" },
      { name: "status", type: "uint8" },
      { name: "payoutDeadline", type: "uint40" },
      { name: "payoutRefHash", type: "bytes32" },
      { name: "repayRefHash", type: "bytes32" },
      { name: "offchainRefHash", type: "bytes32" }
    ]
  },
  {
    type: "function",
    name: "nextPositionId",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "usdIdrRate",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "usdIdrUpdatedAt",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    type: "function",
    name: "aprBps",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint32" }]
  },
  {
    type: "function",
    name: "payoutDeadlineSeconds",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint40" }]
  },
  {
    type: "function",
    name: "treasury",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    type: "function",
    name: "usdcToken",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  }
] as const;
