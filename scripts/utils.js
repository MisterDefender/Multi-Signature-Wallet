const { ethers } = require("hardhat")
const hre = require("hardhat")

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }


async function verify(address, args) {
    if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
      let retry = 20
      console.log("Sleeping before verification...")
      while ((await ethers.provider.getCode(address).catch(() => "")).length <= 3 && retry >= 0) {
        await sleep(5000)
        --retry
      }
      await sleep(30000)
  
      console.log(address, args)
  
      await hre
        .run("verify:verify", {
          address,
          constructorArguments: args,
        })
        .catch(() => console.log("Verification failed"))
    }
  }

module.exports = {verify, sleep}