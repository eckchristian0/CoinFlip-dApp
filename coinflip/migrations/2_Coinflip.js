const Migrations = artifacts.require("Coinflip.sol");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
