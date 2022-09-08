//script/deploy.js
//How to: npx hardhat run scripts/deploy.js --network <network-name>

async function main() {
    const [deployer] = await ethers.getSigners();

    const allowListAddr = 0x0;

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Auction = await ethers.getContractFactory("Auction");
    const auction = await Auction.deploy();

    console.log("Token address:", token.address);
  }

 

  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });