const { expect } = require("chai");
const {loadFixture}  = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const {hre, ethers} = require("hardhat");


describe("MultisigWallet", function(){
    let owner1, owner2, owner3, owner4, owner5;

    async function deployMultiSigWalletFixture(){
        [owner1, owner2, owner3, owner4, owner5] = await ethers.getSigners();
        const deployer = owner1;
        const minApproval = 2
        const multisigWallet = await ethers.deployContract("MultisigWallet", [minApproval], {signer: deployer});
        return {multisigWallet, minApproval, deployer, owner1, owner2, owner3, owner4, owner5};
    };

    async function deployMockUSDCFixture(){
        const mockUSDC = ethers.deployContract("USDC", []);
        return mockUSDC;
        // ethers.utils.parseEther()
    }
    it("should get the threshold of owner required", async ()=>{
        const {multisigWallet} = await loadFixture(deployMultiSigWalletFixture);
        const mockUSDC = await loadFixture(deployMockUSDCFixture)
        console.log("Multisig deployed at: ", await multisigWallet.getAddress());
        console.log("Mock USDC deployed at: ", await mockUSDC.getAddress());
    })


    
})
