// require('hardhat-etherscan');
require("hardhat-contract-sizer");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require("@nomicfoundation/hardhat-toolbox");

const { PRIVATE_KEY, INFURA_API_KEY } = require("./secret");

if (!(INFURA_API_KEY || PRIVATE_KEY)) {
	throw new Error("Please set your INFURA_API_KEY & PRIVATE_KEY in a .env file");
}

const chainIds = {
	ganache: 1337,
	goerli: 5,
	hardhat: 31337,
	kovan: 42,
	mainnet: 1,
	bscmainnet: 56,
	matic: 137,
	rinkeby: 4,
	ropsten: 3,
	bsctestnet: 97,
	mumbai: 80001,
};

module.exports = {
	solidity: {
		compilers: [
			{
				version: "0.8.16",
				settings: {
					// https://hardhat.org/hardhat-network/#solidity-optimizer-support
					optimizer: {
						enabled: true,
						runs: 1,
					},
				},
			},
		],
	},
	defaultNetwork: "hardhat",

	networks: {
		goerli: {
			accounts: [PRIVATE_KEY],
			chainId: chainIds["goerli"],
			url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
			gas: 2100000,
			gasPrice: 32000000000, // 32 Gwei
		},
		rinkeby: {
			accounts: [PRIVATE_KEY],
			chainId: chainIds["rinkeby"],
			url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
			gas: 2100000,
			gasPrice: 32000000000, // 32 Gwei
		},
		mumbai: {
			accounts: [PRIVATE_KEY],
			chainId: chainIds["mumbai"],
			url: `https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}`,
			gas: 2100000,
			gasPrice: 32000000000, //32 gwei
		},
	},
	etherscan: {
		// url: "https://api.etherscan.io/api",
		// apiKey: "F4SSISAJCDM9F5JG8FZN8NXCWBTNY6C73M" //mainnet
		apiKey: "ZUQBXSVXNT8RWQDK7Z5NHV4395U5JJFB5M", // matic
		// apiKey: "FFBBU5ZQ2KV1183XT3VRBKF68ZR56RWT5B" //bsc
		// apiKey: {
		//   mumbai: "ZUQBXSVXNT8RWQDK7Z5NHV4395U5JJFB5M",
		// }
	},
};
