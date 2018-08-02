var ProtectedController = artifacts.require("./ProtectedController.sol");

module.exports = function(deployer) {
  deployer.deploy(ProtectedController);
};
