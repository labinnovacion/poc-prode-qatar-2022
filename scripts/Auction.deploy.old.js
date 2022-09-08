const {ethers} = require("hardhat");

async function main() {
    const currentTimestampInSeconds = Math.round(Date.now() / 1000);
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

    const lockedAmount = ethers.utils.parseEther("1");

    const Auction = await ethers.getContractFactory("Auction");
    const auction = await Auction.deploy(unlockTime, { value: lockedAmount });

    await auction.deployed();

    console.log(
        `Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${auction.address}`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });