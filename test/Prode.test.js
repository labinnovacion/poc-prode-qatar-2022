const { expect } = require("chai");

describe("PRODE QATAR 2022", () => {

    describe("(ERC20) CryptoLink contract", function () {
        it("Deployment should pass.", async function () {
            const [owner] = await ethers.getSigners();

            const CryptoLink = await ethers.getContractFactory("CryptoLink");

            const cryptoLinkToken = await CryptoLink.deploy();

            const ownerBalance = await cryptoLinkToken.balanceOf(owner.address);
            expect(await cryptoLinkToken.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe("Prode contract", function () {
        it("Deployment should assign ERC20 token and pass.", async function () {
            const [owner] = await ethers.getSigners();

            const CryptoLink = await ethers.getContractFactory("CryptoLink");
            const cryptoLinkToken = await CryptoLink.deploy();

            const Prode = await ethers.getContractFactory("Prode");
            const ProdeContract = await Prode.deploy();

            const ownerBalance = await ProdeContract.setERC20Contract(cryptoLinkToken.address);
            expect(await ProdeContract.erc20_contract()).to.equal(cryptoLinkToken.address);
        });
    });

})