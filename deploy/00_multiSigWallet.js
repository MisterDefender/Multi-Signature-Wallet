const {verify} = require("../scripts/utils");

module.exports = async function ({getNamedAccounts, deployments}) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    const owner = deployer
  
    let multiSigWallet
  
    multiSigWallet = await deploy("MultisigWallet", {
      from: deployer,
      args: [2],
      log: true,
      deterministicDeployment: false,
    })
    await verify(multiSigWallet.address, [2])
    
  }
  
  module.exports.tags = ["multiSigWallet"]
  