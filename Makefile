-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaKey --sender 0x718323585Dac87661C198a440D87e2083c50FDF5 --broadcast --verify --etherscan-api-key $(ETHER_SCAN_API_KEY) -vvvv