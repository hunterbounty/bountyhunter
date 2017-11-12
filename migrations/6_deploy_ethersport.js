const EtherSport =
  artifacts.require(`./EtherSport.sol`)

module.exports = (deployer) => {
  console.log('deployer.deploy', Object.keys(deployer))
  deployer.deploy(EtherSport,
      '0x52eac68BEaFB8FFBde44C14e71BE31a9f4161D44',
      4545041,
      44800,
      57600,
      57867,
      64267,
      108954,
      243018
  )
}
