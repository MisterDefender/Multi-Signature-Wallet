const {verify} = require("../scripts/utils");

module.exports = async function ({getNamedAccounts, deployments }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    const owner = deployer
  
    let mockUSDC
  
    mockUSDC = await deploy("USDC", {
      from: deployer,
      args: [],
      log: true,
      deterministicDeployment: true,
    })
    await verify(mockUSDC.address, [])
    
  }
  
  module.exports.tags = ["mockUSDC"]
  